#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif
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
}

@property (nonatomic, copy) NSString *apiURL;
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, strong) NSNumber *sessionId;
@property (nonatomic, copy) NSString *deviceToken;
@property (nonatomic, copy) NSString *cid;
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskId;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong)ZhugeConfig *config;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSUInteger sendCount;
@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyInfo;
@property (nonatomic, strong) NSString *net;
@property (nonatomic, strong) NSString *radio;

@end

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
            sharedInstance.apiURL = @"https://apipool.37degree.com";
            sharedInstance.config = [[ZhugeConfig alloc] init];
        });
        
        return sharedInstance;
    }
    
    return sharedInstance;
}

- (ZhugeConfig *)config {
    return _config;
}

- (void)startWithAppKey:(NSString *)appKey launchOptions:(NSDictionary *)launchOptions {
    @try {
        if (appKey == nil || [appKey length] == 0) {
            NSLog(@"appKey不能为空。");
            return;
        }
        self.appKey = appKey;
        self.userId = @"";
        self.deviceId = [self defaultDeviceId];
        self.deviceToken = @"";
        self.cid = @"";
        self.sessionId = 0;
        self.net = @"";
        self.radio = @"";
        self.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        self.taskId = UIBackgroundTaskInvalid;
        NSString *label = [NSString stringWithFormat:@"io.zhuge.%@.%p", appKey, self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        self.eventsQueue = [NSMutableArray array];

        // SDK配置
        if(self.config && self.config.logEnabled) {
            NSLog(@"SDK系统配置: %@", self.config);
        }

        [self setupListeners];
        [self unarchive];
        
        if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
            [self trackPush:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] type:@"launch"];
        }
        
        [self sessionStart];
    }
    @catch (NSException *exception) {
        NSLog(@"startWithAppKey exception");
    }

}

- (NSString *)getDeviceId {
    if (!self.deviceId) {
        self.deviceId = [self defaultDeviceId];
    }
    
    return self.deviceId;
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
        if(self.config.logEnabled) {
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
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
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

#pragma mark - 推送
// 注册APNS远程消息类型
- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types categories:(NSSet *)categories {
    @try {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
            UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationType)types categories:categories];
            [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        } else {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes: types];
        }
#else
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: types];
#endif
    }
    @catch (NSException *exception) {
        NSLog(@"registerForRemoteNotificationTypes exception");
    }
}

// 注册deviceToken
- (void)registerDeviceToken:(NSData *)deviceToken {
    @try {
        NSString *token=[NSString stringWithFormat:@"%@",deviceToken];
        token=[token stringByReplacingOccurrencesOfString:@"<" withString:@""];
        token=[token stringByReplacingOccurrencesOfString:@">" withString:@""];
        token=[token stringByReplacingOccurrencesOfString:@" " withString:@""];
        self.deviceToken = token;
        
        if(self.config.logEnabled && token) {
            NSLog(@"deviceToken:%@", token);
        }
        
        NSNumber *lastUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"zgRegisterDeviceToken"];
        NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
        if (self.cid == nil || self.cid.length == 0 || lastUpdateTime == nil ||[ts longValue] > [lastUpdateTime longValue] + 86400) {
            [self uploadDeviceToken:token];
            [[NSUserDefaults standardUserDefaults] setObject:ts forKey:@"zgRegisterDeviceToken"];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"registerDeviceToken exception");
    }
}

- (void)uploadDeviceToken:(NSString *)deviceToken {
    dispatch_async(self.serialQueue, ^{
        NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
        NSError *error = nil;
        NSString *requestData = [NSString stringWithFormat:@"method=setting_srv.upload_token_tmp&dev=%@&appid=%@&did=%@&dtype=2&token=%@&timestamp=%@", self.config.apsProduction? @"0" : @"1", self.appKey, self.deviceId, deviceToken, ts];
        NSData *responseData = [self apiRequest:@"/open/" WithData:requestData andError:error];
        if (error) {
            NSLog(@"上报失败: %@", error);
        }
        if (responseData) {
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            if (response && response[@"data"]) {
                NSDictionary *zgData = response[@"data"];
                if ([zgData isKindOfClass:[NSDictionary class]] && zgData[@"cid"]) {
                    self.cid = zgData[@"cid"];
                    if(self.config.logEnabled && self.cid) {
                        NSLog(@"get cid:%@", self.cid);
                    }
                }
            }
        }
    });
}

// 处理接收到的消息
- (void)handleRemoteNotification:(NSDictionary *)userInfo {
    [self trackPush:userInfo type:@"rec"];
}

#pragma mark - 应用生命周期

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    @try {
        if(self.config.logEnabled) {
            NSLog(@"applicationDidBecomeActive");
        }

        [self sessionStart];
        [self uploadDeviceInfo];
        [self startFlushTimer];
    }
    @catch (NSException *exception) {
        NSLog(@"applicationDidBecomeActive exception");
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    @try {
        if(self.config.logEnabled) {
            NSLog(@"applicationWillResignActive");
        }
        [self sessionEnd];
        [self stopFlushTimer];
    }
    @catch (NSException *exception) {
        NSLog(@"applicationWillResignActive exception");
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    @try {
        if(self.config.logEnabled) {
            NSLog(@"applicationDidEnterBackground");
        }
        
        self.taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
            self.taskId = UIBackgroundTaskInvalid;
        }];
        
        [self flush];
        
        dispatch_async(_serialQueue, ^{
            [self archive];
            if (self.taskId != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
                self.taskId = UIBackgroundTaskInvalid;
            }
        });
    }
    @catch (NSException *exception) {
        NSLog(@"applicationDidEnterBackground exception");
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    @try {
        if(self.config.logEnabled) {
            NSLog(@"applicationWillTerminate");
        }
        dispatch_async(_serialQueue, ^{
            [self archive];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"applicationWillTerminate exception");
    }
}

#pragma mark - 设备ID

// 设备ID
- (NSString *)defaultDeviceId {
    // IDFA
    NSString *deviceId = [self adid];
    
    // IDFV from KeyChain
    if (!deviceId) {
        deviceId = [self idFromKeyChain];
    }
    
    if (!deviceId) {
        NSLog(@"error getting device identifier: falling back to uuid");
        deviceId = [[NSUUID UUID] UUIDString];
    }
    return deviceId;
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

- (NSString *)newStoredID {
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(kCFAllocatorDefault, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);
    CFDictionarySetValue(query, kSecAttrAccount, CFSTR("zgid_account"));
    CFDictionarySetValue(query, kSecAttrService, CFSTR("zgid_service"));
    
    NSString *uuid = nil;
    if (NSClassFromString(@"UIDevice")) {
        uuid = [[UIDevice currentDevice].identifierForVendor UUIDString];
    } else {
        uuid = [[NSUUID UUID] UUIDString];
    }
    
    CFDataRef dataRef = CFBridgingRetain([uuid dataUsingEncoding:NSUTF8StringEncoding]);
    CFDictionarySetValue(query, kSecValueData, dataRef);
    OSStatus status = SecItemAdd(query, NULL);
    
    if (status != noErr) {
        NSLog(@"Keychain Save Error: %d", (int)status);
        uuid = nil;
    }
    
    CFRelease(dataRef);
    CFRelease(query);
    
    return uuid;
}

- (NSString *)idFromKeyChain {
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(kCFAllocatorDefault, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);
    CFDictionarySetValue(query, kSecAttrAccount, CFSTR("zgid_account"));
    CFDictionarySetValue(query, kSecAttrService, CFSTR("zgid_service"));
    
    // See if the attribute exists
    CFTypeRef attributeResult = NULL;
    OSStatus status = SecItemCopyMatching(query, (CFTypeRef *)&attributeResult);
    if (attributeResult != NULL)
        CFRelease(attributeResult);
    
    if (status != noErr) {
        CFRelease(query);
        if (status == errSecItemNotFound) {
            return [self newStoredID];
        } else {
            NSLog(@"Unhandled Keychain Error %d", (int)status);
            return nil;
        }
    }
    
    // Fetch stored attribute
    CFDictionaryRemoveValue(query, kSecReturnAttributes);
    CFDictionarySetValue(query, kSecReturnData, (id)kCFBooleanTrue);
    CFTypeRef resultData = NULL;
    status = SecItemCopyMatching(query, &resultData);
    
    if (status != noErr) {
        CFRelease(query);
        if (status == errSecItemNotFound){
            return [self newStoredID];
        } else {
            NSLog(@"Unhandled Keychain Error %ld", status);
            return nil;
        }
    }
    
    NSString *uuid = nil;
    if (resultData != NULL)  {
        uuid = [[NSString alloc] initWithData:objc_retainedObject(resultData) encoding:NSUTF8StringEncoding];
    }
    
    CFRelease(query);
    
    return uuid;
}

#pragma mark - 设备状态

// 是否在后台运行
- (BOOL)inBackground {
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
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
    CTCarrier *carrier =[self.telephonyInfo subscriberCellularProvider];
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
    /* SC_Info */
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
    if(self.config.logEnabled) {
        NSLog(@"联网状态: %@", [@"0" isEqualToString:self.net]?@"未知":[@"1" isEqualToString:self.net]?@"移动网络":@"WIFI");
    }
}

// 网络制式(GPRS,WCDMA,LTE,...)
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
- (void)setCurrentRadio {
    dispatch_async(self.serialQueue, ^(){
        self.radio = [self currentRadio];
        if(self.config.logEnabled && self.radio) {
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
    @try {
        if (!self.sessionId) {
            NSNumber *ts = @([[NSDate date] timeIntervalSince1970]);
            self.sessionId = ts;
            NSLog(@"sessionId:%.3f",[ts doubleValue]);
            if(self.config.logEnabled) {
                NSLog(@"会话开始(ID:%@)", @([self.sessionId intValue]));
            }
            
            NSMutableDictionary *e = [NSMutableDictionary dictionary];
            e[@"et"] = @"ss";
            e[@"sid"] = [NSString stringWithFormat:@"%.3f", [self.sessionId doubleValue]];
            e[@"vn"] = self.config.appVersion;
            e[@"net"] = self.net;
            e[@"radio"] = self.radio;
            
            [self enqueueEvent:e];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"sessionStart exception");
    }
}

// 会话结束
- (void)sessionEnd {
    @try {
        if(self.config.logEnabled && self.sessionId) {
            NSLog(@"会话结束(ID:%@)", self.sessionId);
        }
    
        if (self.sessionId) {
            NSNumber *ts = @([[NSDate date] timeIntervalSince1970]);
            NSMutableDictionary *e = [NSMutableDictionary dictionary];
            e[@"et"] = @"se";
            e[@"sid"] = [NSString stringWithFormat:@"%.3f", [self.sessionId doubleValue]];
            e[@"dr"] = [NSString stringWithFormat:@"%.3f", [ts doubleValue] - [self.sessionId doubleValue]];
            e[@"ts"] = [NSString stringWithFormat:@"%.3f", [ts doubleValue]];
            [self enqueueEvent:e];
            self.sessionId = nil;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"sessionEnd exception");
    }
}

// 上报设备信息
- (void)uploadDeviceInfo {
    @try {
        NSNumber *zgInfoUploadTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"zgInfoUploadTime"];
        NSNumber *ts = @(round([[NSDate date] timeIntervalSince1970]));
        if (zgInfoUploadTime == nil ||[ts longValue] > [zgInfoUploadTime longValue] + 7*86400) {
            [self trackDeviceInfo];
            [[NSUserDefaults standardUserDefaults] setObject:ts forKey:@"zgInfoUploadTime"];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"uploadDeviceInfo exception");
    }
}

// 上报设备信息
- (void)trackDeviceInfo {
    @try {
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
    @catch (NSException *exception) {
        NSLog(@"trackDeviceInfo exception");
    }
}

// 识别用户
- (void)identify:(NSString *)userId properties:(NSDictionary *)properties {
    @try {
        if (userId == nil || userId.length == 0) {
            if(self.config.logEnabled) {
                NSLog(@"用户ID不能为空");
            }
            return;
        }
        
        if (!self.sessionId) {
            [self sessionStart];
        }
    
        self.userId = userId;
    
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"et"] = @"idf";
        e[@"cuid"] = userId;
        e[@"sid"] = [NSString stringWithFormat:@"%.3f", [self.sessionId doubleValue]];
        e[@"pr"] =[NSDictionary dictionaryWithDictionary:properties];
    
        [self enqueueEvent:e];
    }
    @catch (NSException *exception) {
        NSLog(@"identify exception");
    }
}

// 跟踪自定义事件
- (void)track:(NSString *)event {
    [self track:event properties:nil];
}

// 跟踪自定义事件
- (void)track:(NSString *)event properties:(NSMutableDictionary *)properties {
    @try {
        if (event == nil || [event length] == 0) {
            NSLog(@"事件名不能为空");
            return;
        }
        
        if (!self.sessionId) {
            [self sessionStart];
        }
    
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"et"] = @"cus";
        e[@"eid"] = event;
        e[@"sid"] = [NSString stringWithFormat:@"%.3f", [self.sessionId doubleValue]];
        e[@"pr"] =[NSDictionary dictionaryWithDictionary:properties];
    
        [self enqueueEvent:e];
    }
    @catch (NSException *exception) {
        NSLog(@"track properties exception");
    }
}

// 上报推送已读
- (void)trackPush:(NSDictionary *)userInfo type:(NSString *) type {
    @try {
        if(self.config.logEnabled && userInfo) {
            NSLog(@"push payload: %@", userInfo);
        }
        
        if (userInfo && userInfo[@"mid"]) {
            NSMutableDictionary *e = [NSMutableDictionary dictionary];
            e[@"et"] = @"push";
            e[@"mid"] = userInfo[@"mid"];
            e[@"mtype"] = type;
            [self enqueueEvent:e];
            [self flush];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"trackPush exception");
    }
}

// 设置第三方推送用户ID
- (void)setThirdPartyPushUserId:(NSString *)userId forChannel:(ZGPushChannel) channel {
    @try {
        if (userId == nil || [userId length] == 0) {
            NSLog(@"userId不能为空");
            return;
        }
        
        NSMutableDictionary *pr = [NSMutableDictionary dictionary];
        pr[@"channel"] = [self nameForChannel:channel];
        pr[@"user_id"] = userId;
        
        NSMutableDictionary *e = [NSMutableDictionary dictionary];
        e[@"et"] = @"3rdpush";
        e[@"pr"] = pr;
        
        [self enqueueEvent:e];
    }
    @catch (NSException *exception) {
        NSLog(@"track properties exception");
    }
}

-(NSString *)nameForChannel:(ZGPushChannel) channel {
    switch (channel) {
        case ZG_PUSH_CHANNEL_JPUSH:
            return @"jpush";
        case ZG_PUSH_CHANNEL_UMENG:
            return @"umeng";
        case ZG_PUSH_CHANNEL_BAIDU:
            return @"baidu";
        case ZG_PUSH_CHANNEL_XINGE:
            return @"xinge";
        case ZG_PUSH_CHANNEL_GETUI:
            return @"getui";
        default:
            return @"";
    }
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
    batch[@"cuid"] = self.userId;
    batch[@"net"] = self.net;
    batch[@"radio"] = self.radio;
    batch[@"deviceToken"] = self.deviceToken;
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
        NSLog(@"%@ exception encoding api data: %@", self, exception);
    }
    if (error) {
        if(self.config.logEnabled) {
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
    return s;
}

// API数据编码
- (NSString *)encodeAPIData:(NSMutableDictionary *) batch {
    NSData *data = [self JSONSerializeObject:batch];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - 上报策略

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
            if(self.config.logEnabled) {
                NSLog(@"启动事件发送定时器");
            }
        }
    });
}

// 关闭事件发送定时器
- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            if(self.config.logEnabled) {
                NSLog(@"关闭事件发送定时器");
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
    NSNumber *ts = @([[NSDate date] timeIntervalSince1970]);

    if (!event[@"ts"]) {
        event[@"ts"] = [NSString stringWithFormat:@"%.3f", [ts doubleValue]];
    }
    
    if(self.config.logEnabled) {
        NSLog(@"产生事件: %@", event);
    }
    
    [self.eventsQueue addObject:event];
    if ([self.eventsQueue count] > self.config.cacheMaxSize) {
        [self.eventsQueue removeObjectAtIndex:0];
    }
}

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        [self flushQueue: _eventsQueue];
    });
}

- (void)flushQueue:(NSMutableArray *)queue {
    @try {
        while ([queue count] > 0) {
            if (self.sendCount >= self.config.sendMaxSizePerDay) {
                if(self.config.logEnabled) {
                    NSLog(@"超过每天限额，不发送。(今天已经发送:%lu, 限额:%lu, 队列库存数: %lu)", (unsigned long)self.sendCount, (unsigned long)self.config.sendMaxSizePerDay, (unsigned long)[queue count]);
                }
                return;
            }
            
            NSUInteger sendBatchSize = ([queue count] > 50) ? 50 : [queue count];
            if (self.sendCount + sendBatchSize >= self.config.sendMaxSizePerDay) {
                sendBatchSize = self.config.sendMaxSizePerDay - self.sendCount;
            }
            
            NSArray *events = [queue subarrayWithRange:NSMakeRange(0, sendBatchSize)];
            if(self.config.logEnabled) {
                NSLog(@"开始上报事件(本次上报事件数:%lu, 队列内事件总数:%lu, 今天已经发送:%lu, 限额:%lu)", (unsigned long)[events count], (unsigned long)[queue count], (unsigned long)self.sendCount, (unsigned long)self.config.sendMaxSizePerDay);
            }
            
            NSString *eventData = [self encodeAPIData:[self wrapEvents:events]];
            NSString *requestData = [NSString stringWithFormat:@"method=event_statis_srv.upload&event=%@", eventData];

            NSError *error = nil;
            [self apiRequest:@"/APIPOOL/" WithData:requestData andError:error];
            if (error) {
                NSLog(@"上报失败: %@", error);
                break;
            }
            
            self.sendCount += sendBatchSize;
           [queue removeObjectsInArray:events];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"flushQueue exception");
    }
}


- (NSData*) apiRequest:(NSString *)endpoint WithData:(NSString *)requestData andError:(NSError *)error {
    NSURL *URL = [NSURL URLWithString:[self.apiURL stringByAppendingString:endpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[requestData stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding]];
    if(self.config.logEnabled && URL && requestData) {
        NSLog(@"API请求: %@&%@", URL, requestData);
    }
    
    [self updateNetworkActivityIndicator:YES];
    
    NSURLResponse *urlResponse = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    
    [self updateNetworkActivityIndicator:NO];
    
    if (responseData != nil) {
        NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        if(self.config.logEnabled && response) {
            NSLog(@"API响应: %@", response);
        }
    }
    
    return responseData;
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
    @try {
        [self archiveEvents];
        [self archiveProperties];
    }
    @catch (NSException *exception) {
        NSLog(@"archive exception");
    }
}

- (void)archiveEvents {
    NSString *filePath = [self eventsFilePath];
    NSMutableArray *eventsQueueCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    if(self.config.logEnabled && filePath) {
        NSLog(@"保存事件到 %@", filePath);
    }
    if (![NSKeyedArchiver archiveRootObject:eventsQueueCopy toFile:filePath]) {
        if(self.config.logEnabled) {
            NSLog(@"事件保存失败");
        }
    }
}

- (void)archiveProperties {
    NSString *filePath = [self propertiesFilePath];
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setValue:self.userId forKey:@"userId"];
    [p setValue:self.deviceId forKey:@"deviceId"];
    [p setValue:self.sessionId forKey:@"sessionId"];
    [p setValue:self.cid forKey:@"cid"];

    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *today = [DateFormatter stringFromDate:[NSDate date]];
    [p setValue:[NSString stringWithFormat:@"%lu",(unsigned long)self.sendCount] forKey:[NSString stringWithFormat:@"sendCount-%@", today]];

    if(self.config.logEnabled && filePath && p) {
        NSLog(@"保存属性到 %@: %@",  filePath, p);
    }
    if (![NSKeyedArchiver archiveRootObject:p toFile:filePath]) {
        if(self.config.logEnabled) {
            NSLog(@"属性保存失败");
        }
    }
}

- (void)unarchive {
    @try {
        [self unarchiveEvents];
        [self unarchiveProperties];
    }
    @catch (NSException *exception) {
        NSLog(@"unarchive exception");
    }
}

- (id)unarchiveFromFile:(NSString *)filePath {
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        if(self.config.logEnabled && filePath && unarchivedData) {
            NSLog(@"恢复数据 %@: %@", filePath, unarchivedData);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"恢复数据失败");
        unarchivedData = nil;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!removed) {
            if(self.config.logEnabled && error) {
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
        self.userId = properties[@"userId"] ? properties[@"userId"] : @"";
        self.deviceId = properties[@"deviceId"] ? properties[@"deviceId"] : [self defaultDeviceId];
        self.sessionId = properties[@"sessionId"] ? properties[@"sessionId"] : nil;
        self.cid = properties[@"cid"] ? properties[@"cid"] : nil;
        
        NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
        [DateFormatter setDateFormat:@"yyyyMMdd"];
        NSString *today = [DateFormatter stringFromDate:[NSDate date]];
        NSString *sendCountKey = [NSString stringWithFormat:@"sendCount-%@", today];
        self.sendCount = properties[sendCountKey] ? [properties[sendCountKey] intValue] : 0;
    }
}

@end
