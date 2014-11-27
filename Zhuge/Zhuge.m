//
//  Zhuge.m
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import <UIKit/UIDevice.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import "Zhuge.h"

@interface Zhuge () {
    BOOL isLogEnabled;
    BOOL isCrashReportEnabled;
    BOOL isOnlineConfigEnabled;
}

// API连接
@property (nonatomic, copy) NSString *apiURL;
@property (nonatomic, copy) NSString *confURL;
@property (nonatomic, copy) NSString *appKey;

// 会话页面
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, strong) NSNumber *sessionId;
@property (nonatomic, strong) NSMutableDictionary *pages;
@property (nonatomic, strong) NSString *lastPage;

// 事件
@property (nonatomic, strong) NSMutableDictionary *timedEvents;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *eventsQueue;

// 配置文件
@property (nonatomic, strong)ZhugeConfig *config;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSUInteger sendCount;

// 网络状态
@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyInfo;
@property (nonatomic, strong) NSString *net;
@property (nonatomic, strong) NSString *radio;

// 崩溃报告
- (void)trackCrash:(NSString *)stackTrace;
@end

// 异常处理
void uncaughtExceptionHandler(NSException *exception) {
    if ([[[Zhuge sharedInstance] config] isLogEnabled]) {
        NSLog(@"Exception: %@", exception);
        NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    }
    NSString *stackTrace = [[NSString alloc] initWithFormat:@"%@\n%@", exception, [exception callStackSymbols]];
    [[Zhuge sharedInstance] trackCrash: stackTrace];
}


@implementation Zhuge

static void ZhugeReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    if (info != NULL && [(__bridge NSObject*)info isKindOfClass:[Zhuge class]]) {
        @autoreleasepool {
            Zhuge *zhuge = (__bridge Zhuge *)info;
            [zhuge reachabilityChanged:flags];
        }
    }
}

static Zhuge *sharedInstance = nil;

#pragma mark - 初始化

+ (Zhuge *)sharedInstance {
    if (sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[super alloc] init];
            sharedInstance.apiURL = @"http://apipool.37degree.com/APIPOOL/";
            sharedInstance.confURL = @"http://zhuge.io/config.jsp";
            sharedInstance.config = [[ZhugeConfig alloc] init];
        });
        
        return sharedInstance;
    }
    
    return sharedInstance;
}

- (ZhugeConfig *)config {
    return _config;
}

- (void)startWithAppKey:(NSString *)appKey {
    if (appKey == nil || [appKey length] == 0) {
        NSLog(@"%@ appKey不能为空。", self);
        return;
    }
    self.appKey = appKey;
    self.deviceId = [self defaultDeviceId];
    self.pages = [NSMutableDictionary dictionary];
    self.lastPage = @"APP_START";
    self.net = @"";
    self.radio = @"";

    // SDK配置
    if (self.config.isOnlineConfigEnabled) {
        [self updateConfigFromOnline];
    }
    if(self.config.isLogEnabled) {
        NSLog(@"SDK系统配置: %@", self.config);
    }

    NSString *label = [NSString stringWithFormat:@"io.zhuge.%@.%p", appKey, self];
    self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    self.eventsQueue = [NSMutableArray array];
    self.timedEvents = [NSMutableDictionary dictionary];

    [self setupListeners];
    [self unarchive];
    [self sessionStart];

    // 崩溃报告
    if (self.config.isCrashReportEnabled) {
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    }
    
}

// 监听网络状态和应用生命周期
- (void)setupListeners {
    BOOL reachabilityOk = NO;
    if ((_reachability = SCNetworkReachabilityCreateWithName(NULL, "www.baidu.com")) != NULL) {
        SCNetworkReachabilityContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(_reachability, ZhugeReachabilityCallback, &context)) {
            if (SCNetworkReachabilitySetDispatchQueue(_reachability, self.serialQueue)) {
                reachabilityOk = YES;
            } else {
                SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
            }
        }
    }
    if (!reachabilityOk) {
        if(self.config.isLogEnabled) {
            NSLog(@"failed to set up reachability callback: %s", SCErrorString(SCError()));
        }
    }
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // 网络制式(GRPS,WCDMA,LTE,...),IOS7以上版本才支持
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [self setCurrentRadio];
        [notificationCenter addObserver:self
                               selector:@selector(setCurrentRadio)
                                   name:CTRadioAccessTechnologyDidChangeNotification
                                 object:nil];
    }
#endif
    
    // 应用生命周期通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
 
}

#pragma mark - 应用生命周期

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if(self.config.isLogEnabled) {
        NSLog(@"applicationDidBecomeActive");
    }

    [self sessionStart];
    [self uploadDeviceInfo];
    [self sendWithTiming:@"start"];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if(self.config.isLogEnabled) {
        NSLog(@"applicationDidEnterBackground");
    }
    [self endAllPages];
    [self sessionEnd];
    [self sendWithTiming:@"exit"];
    dispatch_async(_serialQueue, ^{
        [self archive];
    });
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if(self.config.isLogEnabled) {
        NSLog(@"applicationWillTerminate");
    }
    [self endAllPages];
    [self sessionEnd];
    [self sendWithTiming:@"exit"];
    dispatch_async(_serialQueue, ^{
        [self archive];
    });
}

#pragma mark - 设备状态

// 是否在后台运行
- (BOOL)inBackground {
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

// 广告ID
- (NSString *)adid {
    NSString *adid = nil;
#ifndef ZHUGE_NO_ADID
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        adid = [uuid UUIDString];
    }
#endif
    return adid;
}

// 设备ID
- (NSString *)defaultDeviceId {
    NSString *deviceId = [self adid];
    
    if (!deviceId && NSClassFromString(@"UIDevice")) {
        deviceId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    if (!deviceId) {
        if(self.config.isLogEnabled) {
            NSLog(@"error getting device identifier: falling back to uuid");
        }
        deviceId = [[NSUUID UUID] UUIDString];
    }
    return deviceId;
}

// MAC地址
- (NSString *)macAddress {
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        if(self.config.isLogEnabled) {
            NSLog(@"Error: if_nametoindex error");
        }
        return nil;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        if(self.config.isLogEnabled) {
            NSLog(@"Error: sysctl, take 1");
        }
        return nil;
    }
    
    if ((buf = malloc(len)) == NULL) {
        if(self.config.isLogEnabled) {
            NSLog(@"Could not allocate memory. error!");
        }
        return nil;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        if(self.config.isLogEnabled) {
            NSLog(@"Error: sysctl, take 2");
        }
        free(buf);
        return nil;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return outstring;
}

// 系统信息
- (NSString *)getSysInfoByName:(char *)typeSpecifier {
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return results;
}

// 分辨率
- (NSString *)resolution {
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGFloat scale = [[UIScreen mainScreen] scale];
    return [[NSString alloc] initWithFormat:@"%.fx%.f",rect.size.width*scale,rect.size.height*scale];
}

// 运营商
- (NSString *)carrier {
    CTTelephonyNetworkInfo *netInfo =[[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier =[netInfo subscriberCellularProvider];
    if (carrier != nil) {
        NSString *mcc =[carrier mobileCountryCode];
        NSString *mnc =[carrier mobileNetworkCode];
        return [NSString stringWithFormat:@"%@%@", mcc, mnc];
    }
    
    return @"";
}

// 是否越狱
- (BOOL)isJailBroken {
    static const char * __jb_app = NULL;
    static const char * __jb_apps[] = {
        "/Application/Cydia.app",
        "/Application/limera1n.app",
        "/Application/greenpois0n.app",
        "/Application/blackra1n.app",
        "/Application/blacksn0w.app",
        "/Application/redsn0w.app",
        NULL
    };
    __jb_app = NULL;
    for ( int i = 0; __jb_apps[i]; ++i ) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:__jb_apps[i]]]) {
            __jb_app = __jb_apps[i];
            return YES;
        }
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/lib/apt/"]) {
        return YES;
    }

    return NO;
}

// 是否破解
- (BOOL)isPirated {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    /*SC _Info*/
    if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/SC_Info",bundlePath]]) {
        return YES;
    }
    /* iTunesMetadata.plist */
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/iTunesMetadata.plist",bundlePath]]) {
        return YES;
    }
    return NO;
}

// 更新网络指示器
- (void)updateNetworkActivityIndicator:(BOOL)on {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = on;
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags {
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
            self.net = @"1";//2G/3G/4G
        } else {
            self.net = @"4";//WIFI
        }
    } else {
        self.net = @"0";//未知
    }
    if(self.config.isLogEnabled) {
        NSLog(@"联网状态: %@", [@"0" isEqualToString:self.net]?@"未知":[@"1" isEqualToString:self.net]?@"移动网络":@"WIFI");
    }
}

// 网络制式(GPRS,WCDMA,LTE,...)
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
- (void)setCurrentRadio {
    dispatch_async(self.serialQueue, ^(){
        self.radio = [self currentRadio];
        if(self.config.isLogEnabled) {
            NSLog(@"网络制式: %@", self.radio);
        }
    });
}

- (NSString *)currentRadio {
    NSString *radio = _telephonyInfo.currentRadioAccessTechnology;
    if (!radio) {
        radio = @"None";
    } else if ([radio hasPrefix:@"CTRadioAccessTechnology"]) {
        radio = [radio substringFromIndex:23];
    }
    return radio;
}
#endif

#pragma mark - 事件跟踪

// 会话开始
- (void)sessionStart {
    NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
    if (!self.sessionId || ([self.sessionId intValue] - [ts intValue]) > self.config.sessionInterval) {
        self.sessionId = ts;
        if(self.config.isLogEnabled) {
            NSLog(@"会话开始(ID:%@)", self.sessionId);
        }
        
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"et"] = @"ss";
        e[@"sid"] = self.sessionId;
        e[@"vn"] = self.config.appVersion;

        [self enqueueEvent:e];
    }
}

// 会话结束
- (void)sessionEnd {
    if(self.config.isLogEnabled) {
        NSLog(@"会话结束(ID:%@)", self.sessionId);
    }
    
    if (self.sessionId) {
        NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"et"] = @"se";
        e[@"sid"] = self.sessionId;
        e[@"dr"] = [NSString stringWithFormat:@"%d", [ts intValue] - [self.sessionId intValue]];

        [self enqueueEvent:e];
        self.sessionId = nil;
    }
}

// 结束所有页面
- (void) endAllPages {
    NSArray *sortedPages = [self.pages keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
        if ([obj1 doubleValue] > [obj2 doubleValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        if ([obj1 doubleValue] < [obj2 doubleValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    for (NSString *page in sortedPages) {
       [self pageEnd:page];
    }
}

// 页面开始访问
- (void)pageStart:(NSString *)page {
    if (page == nil || page.length == 0) {
        if(self.config.isLogEnabled) {
            NSLog(@"页面名称不能为空");
        }
        return;
    }
    
    if(self.config.isLogEnabled) {
        NSLog(@"开始访问页面: %@", page);
    }
    
    dispatch_async(self.serialQueue, ^{
        self.pages[page] = @([[NSDate date] timeIntervalSince1970]);
    });
}

// 页面访问结束
- (void)pageEnd:(NSString *)page {
    if(self.config.isLogEnabled) {
        NSLog(@"结束访问页面: %@", page);
    }
    
    NSMutableDictionary *e = [NSMutableDictionary dictionary];
    e[@"et"] = @"pg";
    e[@"pg"] = page;
    e[@"sid"] = self.sessionId;
    e[@"pid"] = page;
    e[@"ref"] = self.lastPage;
    
    self.lastPage = page;

    NSNumber *startTime = self.pages[page];
    if (startTime) {
        [self.pages removeObjectForKey:page];
        NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
        e[@"dr"] = [NSString stringWithFormat:@"%d", [ts intValue] - [startTime intValue]];
    }

    [self enqueueEvent:e];
}

// 上报设备信息
- (void)uploadDeviceInfo {
    NSNumber *zgInfoUploadTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"zgInfoUploadTime"];
    NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
    if (zgInfoUploadTime == nil ||[ts longValue] > [zgInfoUploadTime longValue] + 7*86400) {
        [self trackDeviceInfo];
        [[NSUserDefaults standardUserDefaults] setObject:ts forKey:@"zgInfoUploadTime"];
    }
}

// 上报设备信息
- (void)trackDeviceInfo {
    NSMutableDictionary *e = [NSMutableDictionary dictionary];
    e[@"et"] = @"info";

    // 设备ID
    e[@"did"] = self.deviceId;
    // 应用版本
    e[@"vn"] = self.config.appVersion;
    // 应用名称
    NSString *displayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (displayName != nil) {
        e[@"pn"] = displayName;
    }
    // SDK
    e[@"sdk"] = @"ios";
    // SDK版本
    e[@"sdkv"] = self.config.sdkVersion;
    // MAC地址
    e[@"mac"] = [self macAddress];
    // 设备
    e[@"dv"] = [self getSysInfoByName:"hw.machine"];
    // 系统
    e[@"os"] = @"ios";
    // 制造商
    e[@"maker"] = @"Apple";
    // 系统版本
    e[@"ov"] = [[UIDevice currentDevice] systemVersion];
    //分辨率
    e[@"rs"] = [self resolution];
    // 运营商
    e[@"cr"] = [self carrier];
    //网络
    e[@"net"] = self.net;
    e[@"radio"] = self.radio;
    // 是否越狱
    e[@"jail"] =[self isJailBroken] ? @YES : @NO;
    // 是否破解
    e[@"pirate"] =[self isPirated] ? @YES : @NO;
    // 语言
    e[@"lang"] = [[NSLocale preferredLanguages] objectAtIndex:0];
    // 时区
    e[@"tz"] = [NSString stringWithFormat:@"%@",[NSTimeZone localTimeZone]];
    
    [self enqueueEvent:e];
    
}

// 识别用户
- (void)identify:(NSString *)userId properties:(NSDictionary *)properties {
    if (userId == nil || userId.length == 0) {
        if(self.config.isLogEnabled) {
            NSLog(@"用户ID不能为空");
        }
        return;
    }
    
    NSMutableDictionary *e = [NSMutableDictionary dictionary];
    e[@"et"] = @"idf";
    e[@"cuid"] = userId;
    e[@"sid"] = self.sessionId;
    e[@"pr"] =[NSDictionary dictionaryWithDictionary:properties];
    
    [self enqueueEvent:e];
}

// 开始记录有时长的事件
- (void)timeEvent:(NSString *)event {
    if (event == nil || [event length] == 0) {
        if(self.config.isLogEnabled) {
            NSLog(@"事件名不能为空");
        }
        return;
    }
    dispatch_async(self.serialQueue, ^{
        self.timedEvents[event] = @([[NSDate date] timeIntervalSince1970]);
    });
}

// 跟踪自定义事件
- (void)track:(NSString *)event {
    [self track:event properties:nil];
}

// 跟踪自定义事件
- (void)track:(NSString *)event properties:(NSMutableDictionary *)properties {
    if (event == nil || [event length] == 0) {
        if(self.config.isLogEnabled) {
            NSLog(@"事件名不能为空");
        }
        return;
    }
    
    NSMutableDictionary *e = [NSMutableDictionary dictionary];
    e[@"et"] = @"cus";
    e[@"eid"] = event;
    e[@"sid"] = self.sessionId;
    e[@"pr"] =[NSDictionary dictionaryWithDictionary:properties];
    
    NSNumber *eventStartTime = self.timedEvents[event];
    if (eventStartTime) {
        [self.timedEvents removeObjectForKey:event];
        double epochInterval = [[NSDate date] timeIntervalSince1970];
        e[@"dr"] = [NSString stringWithFormat:@"%.3f", epochInterval - [eventStartTime doubleValue]];
    }

    [self enqueueEvent:e];
}

// 崩溃报告
- (void)trackCrash:(NSString *)stackTrace {
    NSMutableDictionary *pr = [NSMutableDictionary dictionary];
    pr[@"msg"] = stackTrace;
    
    NSMutableDictionary *e = [NSMutableDictionary dictionary];
    e[@"et"] = @"ex";
    e[@"sid"] = self.sessionId;
    e[@"pr"] =pr;
    
    [self syncEnqueueEvent:e];
    [self archiveEvents];
}

// 事件包装
- (NSMutableDictionary *)wrapEvents:(NSArray *) events {
    NSMutableDictionary *batch = [NSMutableDictionary dictionary];
    batch[@"type"] = @"statis";
    batch[@"sdk"] = @"ios";
    batch[@"sdkv"] = self.config.sdkVersion;
    batch[@"ts"] = @(round([[NSDate date] timeIntervalSince1970]));
    batch[@"cn"] = self.config.channel;
    batch[@"ak"] = self.appKey;
    batch[@"did"] = self.deviceId;
    batch[@"data"] = events;
    
    return batch;
}

#pragma mark - 编码&解码

// JSON序列化
- (NSData *)JSONSerializeObject:(id)obj {
    id coercedObj = [self JSONSerializableObjectForObject:obj];
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:coercedObj options:0 error:&error];
    }
    @catch (NSException *exception) {
        if(self.config.isLogEnabled) {
            NSLog(@"%@ exception encoding api data: %@", self, exception);
        }
    }
    if (error) {
        if(self.config.isLogEnabled) {
            NSLog(@"%@ error encoding api data: %@", self, error);
        }
    }
    return data;
}

// JSON序列化
- (id)JSONSerializableObjectForObject:(id)obj {
    // valid json types
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    // recurse on containers
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in obj) {
            [a addObject:[self JSONSerializableObjectForObject:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *stringKey;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                if(self.config.isLogEnabled) {
                    NSLog(@"%@ warning: property keys should be strings. got: %@. coercing to: %@", self, [key class], stringKey);
                }
            } else {
                stringKey = [NSString stringWithString:key];
            }
            id v = [self JSONSerializableObjectForObject:obj[key]];
            d[stringKey] = v;
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }

    // default to sending the object's description
    NSString *s = [obj description];
    if(self.config.isLogEnabled) {
        NSLog(@"%@ warning: property values should be valid json types. got: %@. coercing to: %@", self, [obj class], s);
    }
    return s;
}

// API数据编码
- (NSString *)encodeAPIData:(NSMutableDictionary *) batch
{
    NSData *data = [self JSONSerializeObject:batch];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - 上报策略

// 上报策略
- (void)sendWithTiming:(NSString *)timing {
    // 实时发送
    if (self.config.policy == SEND_REALTIME) {
        [self flush];
    }
    // WIFI时发送
    else if (self.config.policy == SEND_WIFI_ONLY && [@"4" isEqualToString:self.net]) {
        [self flush];
    }
    // 启动时发送
    else if (self.config.policy == SEND_ON_START && [@"start" isEqualToString: timing]) {
        [self flush];
    }
    // 按时间间隔发送
    else if (self.config.policy == SEND_INTERVAL) {
        if ([@"start" isEqualToString: timing]) {
            [self startFlushTimer];
        } else if ([@"exit" isEqualToString: timing]) {
            [self stopFlushTimer];
        }
    }
}

// 启动事件发送定时器
- (void)startFlushTimer {
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.config.sendInterval > 0) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.config.sendInterval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            if(self.config.isLogEnabled) {
                NSLog(@"启动事件发送定时器: %@", self.timer);
            }
        }
    });
}

// 关闭事件发送定时器
- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            if(self.config.isLogEnabled) {
                NSLog(@"关闭事件发送定时器: %@", self.timer);
            }
        }
        self.timer = nil;
    });
}


#pragma mark - 事件上报

// 事件加入待发队列

- (void)enqueueEvent:(NSMutableDictionary *)event {
    dispatch_async(self.serialQueue, ^{
        [self syncEnqueueEvent:event];
    });
}

- (void)syncEnqueueEvent:(NSMutableDictionary *)event {
    event[@"ts"] = @(round([[NSDate date] timeIntervalSince1970]));
    
    if(self.config.isLogEnabled) {
        NSLog(@"产生事件: %@", event);
    }
    
    [self.eventsQueue addObject:event];
    if ([self.eventsQueue count] > self.config.cacheMaxSize) {
        [self.eventsQueue removeObjectAtIndex:0];
    }
    
    [self sendWithTiming:@"enqueue"];
}

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        [self flushQueue: _eventsQueue];
    });
}

- (void)flushQueue:(NSMutableArray *)queue {
    while ([queue count] > 0) {
        if (self.sendCount >= self.config.sendMaxSizePerDay) {
            if(self.config.isLogEnabled) {
                NSLog(@"超过每天限额，不发送。(今天已经发送:%lu, 限额:%lu, 队列库存数: %lu)", (unsigned long)self.sendCount, (unsigned long)self.config.sendMaxSizePerDay, (unsigned long)[queue count]);
            }
            return;
        }
        
        NSUInteger sendBatchSize = ([queue count] > 50) ? 50 : [queue count];
        if (self.sendCount + sendBatchSize >= self.config.sendMaxSizePerDay) {
            sendBatchSize = self.config.sendMaxSizePerDay - self.sendCount;
        }
        
        NSArray *events = [queue subarrayWithRange:NSMakeRange(0, sendBatchSize)];
        if(self.config.isLogEnabled) {
            NSLog(@"开始上报事件(本次上报事件数:%lu, 队列内事件总数:%lu, 今天已经发送:%lu, 限额:%lu)", (unsigned long)[events count], (unsigned long)[queue count], (unsigned long)self.sendCount, (unsigned long)self.config.sendMaxSizePerDay);
        }
        
        NSString *requestData = [self encodeAPIData:[self wrapEvents:events]];
        NSString *postBody = [NSString stringWithFormat:@"method=event_statis_srv.upload&event=%@", requestData];
        NSURL *URL = [NSURL URLWithString:self.apiURL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[[postBody stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding]];
        if(self.config.isLogEnabled) {
            NSLog(@"API请求: %@&%@", URL, postBody);
        }
        NSError *error = nil;
        
        [self updateNetworkActivityIndicator:YES];
        
        NSURLResponse *urlResponse = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
        
        [self updateNetworkActivityIndicator:NO];
        
        
        if (error) {
            if(self.config.isLogEnabled) {
                NSLog(@"上报失败: %@", error);
            }
            break;
        }

        NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        if(self.config.isLogEnabled) {
            NSLog(@"API响应: %@", response);
        }
        
        self.sendCount += sendBatchSize;
       [queue removeObjectsInArray:events];
    }
}

#pragma mark - 持久化

// 文件根路径
- (NSString *)filePathForData:(NSString *)data {
    NSString *filename = [NSString stringWithFormat:@"zhuge-%@-%@.plist", self.appKey, data];
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
}

// 事件路径
- (NSString *)eventsFilePath {
    return [self filePathForData:@"events"];
}

// 属性路径
- (NSString *)propertiesFilePath {
    return [self filePathForData:@"properties"];
}

- (void)archive {
    [self archiveEvents];
    [self archiveProperties];
}

- (void)archiveEvents{
    NSString *filePath = [self eventsFilePath];
    NSMutableArray *eventsQueueCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    if(self.config.isLogEnabled) {
        NSLog(@"保存事件到 %@", filePath);
    }
    if (![NSKeyedArchiver archiveRootObject:eventsQueueCopy toFile:filePath]) {
        if(self.config.isLogEnabled) {
            NSLog(@"事件保存失败");
        }
    }
}

- (void)archiveProperties {
    NSString *filePath = [self propertiesFilePath];
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setValue:self.deviceId forKey:@"deviceId"];
    [p setValue:self.timedEvents forKey:@"timedEvents"];

    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *today = [DateFormatter stringFromDate:[NSDate date]];
    [p setValue:[NSString stringWithFormat:@"%lu",(unsigned long)self.sendCount] forKey:[NSString stringWithFormat:@"sendCount-%@", today]];

    if(self.config.isLogEnabled) {
        NSLog(@"保存属性到 %@: %@",  filePath, p);
    }
    if (![NSKeyedArchiver archiveRootObject:p toFile:filePath]) {
        if(self.config.isLogEnabled) {
            NSLog(@"属性保存失败");
        }
    }
}

- (void)unarchive {
    [self unarchiveEvents];
    [self unarchiveProperties];

}

- (id)unarchiveFromFile:(NSString *)filePath {
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        if(self.config.isLogEnabled) {
            NSLog(@"恢复数据 %@: %@", filePath, unarchivedData);
        }
    }
    @catch (NSException *exception) {
        if(self.config.isLogEnabled) {
            NSLog(@"恢复数据失败");
        }
        unarchivedData = nil;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!removed) {
            if(self.config.isLogEnabled) {
                NSLog(@"删除数据失败 %@", error);
            }
        }
    }
    return unarchivedData;
}

- (void)unarchiveEvents {
    self.eventsQueue = (NSMutableArray *)[self unarchiveFromFile:[self eventsFilePath]];
    if (!self.eventsQueue) {
        self.eventsQueue = [NSMutableArray array];
    }
}

- (void)unarchiveProperties {
    NSDictionary *properties = (NSDictionary *)[self unarchiveFromFile:[self propertiesFilePath]];
    if (properties) {
        self.deviceId = properties[@"deviceId"] ? properties[@"deviceId"] : [self defaultDeviceId];
        self.timedEvents = properties[@"timedEvents"] ? properties[@"timedEvents"] : [NSMutableDictionary dictionary];
        
        NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
        [DateFormatter setDateFormat:@"yyyyMMdd"];
        NSString *today = [DateFormatter stringFromDate:[NSDate date]];
        NSString *sendCountKey = [NSString stringWithFormat:@"sendCount-%@", today];
        self.sendCount = properties[sendCountKey] ? [properties[sendCountKey] intValue] : 0;
    }
}

#pragma mark - 配置文件

- (NSString *) getOnlineConfig {
    NSString *url =  [NSString stringWithFormat:@"%@?appkey=%@&did=%@", self.confURL, self.appKey, self.deviceId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLResponse *response;
    NSError *error;
    
    NSData *aData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc]init];
    json = (NSMutableDictionary*)[NSJSONSerialization JSONObjectWithData:aData options:kNilOptions error:&error];
    
    // 禁用上传:禁止上传应用列表|禁止上传账户中心数据|禁止上传手机号:上传方式|会话过期时间|用户每天最大上传消息数|用户本地最大缓存消息数|重试次数|连接超时|读取超时|上传间隔时间
    return json[@"config"];
    
}

- (void)updateConfigFromOnline {
    NSString *confString = [[NSUserDefaults standardUserDefaults] objectForKey:@"zgConfig"];
    NSNumber *zgConfigTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"zgConfigTime"];
    NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
    if (confString == nil || zgConfigTime == nil ||[ts longValue] > [zgConfigTime longValue] + 86400) {
        if(self.config.isLogEnabled) {
            NSLog(@"开始下载线上配置, 上次下载时间:%@", zgConfigTime);
        }

        confString = [self getOnlineConfig];
        
        if(self.config.isLogEnabled) {
            NSLog(@"线上配置: %@", confString);
        }
        [[NSUserDefaults standardUserDefaults] setObject:confString forKey:@"zgConfig"];
        [[NSUserDefaults standardUserDefaults] setObject:ts forKey:@"zgConfigTime"];
    }
    
    if(self.config.isLogEnabled) {
        NSLog(@"设置配置: %@", confString);
    }
    [self.config updateOnlineConfig:confString];
}

@end
