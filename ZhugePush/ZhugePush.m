#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "ZhugePush.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#define DEVICE_TYPE 2

typedef enum {
    ZGNotificationStateConnecting       = 0, // 未连接
    ZGNotificationStateConnected        = 1, // 连接建立
    ZGNotificationStateLogin            = 2, // 登录成功
    ZGNotificationStateClosed           = 4  // 连接关闭
} ZGNotificationState;

#pragma mark - 消息协议

typedef struct {
    uint16_t iHeadLen;  // 包头长度, 大于或者等于 sizeof(PkgHeader)=8 字节
    uint16_t iCmdType;  // 消息类型, 消息类型加1为对应的响应的类型
    uint32_t iTotalLen; // 总包长,   即包头长度+包体长度
} PkgHeader;

typedef enum {
    ZGNoticeCmdLogin          = 0x1000,	// 注册
    ZGNoticeCmdKeepalive      = 0x1002,	// 心跳检测
    ZGNoticeCmdUploadToken    = 0x1004,	// 上传ios token
    ZGNoticeCmdGetClientId    = 0x1006,	// 获取clientid
    ZGNoticeCmdClearMsgCnt    = 0x1008,	// 清除未读消息数量
    ZGNoticeCmdSetMsgRead     = 0x1010,	// 标记消息已经阅读
    ZGNoticeCmdSetShield      = 0x1012,	// 设置屏蔽消息
    ZGNoticeCmdGetShield      = 0x1014,	// 获取屏蔽消息
    ZGNoticeCmdSetRecvTime    = 0x1016,	// 设置消息接收时段
    ZGNoticeCmdGetRecvTime    = 0x1018,	// 获取消息接收时段
    ZGNoticeCmdMsg            = 0x2000,	// b2c消息
    ZGNoticeCmdLogout         = 0xFF00,	// logout
    ZGNoticeCmdKickout        = 0xFF02,	// kickout
} ZGNoticeCmdType;

typedef enum {
    ZGNoticeCmdAckLogin          = 0x1001,	// 注册
    ZGNoticeCmdAckKeepalive      = 0x1003,	// 心跳检测
    ZGNoticeCmdAckUploadToken    = 0x1005,	// 上传ios token
    ZGNoticeCmdAckGetClientId    = 0x1007,	// 获取clientid
    ZGNoticeCmdAckClearMsgCnt    = 0x1009,	// 清除未读消息数量
    ZGNoticeCmdAckSetMsgRead     = 0x1011,	// 标记消息已经阅读
    ZGNoticeCmdAckSetShield      = 0x1013,	// 设置屏蔽消息
    ZGNoticeCmdAckGetShield      = 0x1015,	// 获取屏蔽消息
    ZGNoticeCmdAckSetRecvTime    = 0x1017,	// 设置消息接收时段
    ZGNoticeCmdAckGetRecvTime    = 0x1019,	// 获取消息接收时段
    ZGNoticeCmdAckMsg            = 0x2001,	// b2c消息
    ZGNoticeCmdAckLogout         = 0xFF01,	// logout
    ZGNoticeCmdAckKickout        = 0xFF03,	// kickout
} ZGNoticeAckCmdType;


#pragma mark - NSRunLoop

@interface NSRunLoop (ZGNotificationManager)
+ (NSRunLoop *)zgNetworkRunLoop;
@end

@interface _ZGRunLoopThread : NSThread
@property (nonatomic, readonly) NSRunLoop *runLoop;
@end

#pragma mark - ZhugePush

@interface ZhugePush() <NSStreamDelegate>

@property (nonatomic) ZGNotificationState readyState;

@property (nonatomic, copy) NSString *serverUrl;
@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, copy) NSString *currentServer;
@property (atomic) int retry;

@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *deviceToken;
@property (nonatomic, copy) NSString *cid;
@property (atomic) NSNumber *seq;
@property (atomic) NSNumber *ver;

@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSMutableArray *unreadMessages;

@property (atomic) BOOL deviceTokenUploaded;

@property (atomic) BOOL isLogEnabled;


@end

@implementation ZhugePush {
    dispatch_queue_t _connectQueue;
}

NSInputStream *_inputStream;
NSOutputStream *_outputStream;

#pragma mark - 初始化

+ (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types categories:(NSSet *)categories {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_8_0
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes: types];
#endif
}

+ (void)registerDeviceId:(NSString *)deviceId {
    [ZhugePush sharedInstance].deviceId = deviceId;
}

+ (void)registerDeviceToken:(NSData *)deviceToken {
    NSString *token=[NSString stringWithFormat:@"%@",deviceToken];
    token=[token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token=[token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token=[token stringByReplacingOccurrencesOfString:@" " withString:@""];
    [ZhugePush sharedInstance].deviceToken = token;
}

+ (void)startWithAppKey:(NSString *)appKey launchOptions:(NSDictionary *)launchOptions {
    [[ZhugePush sharedInstance] openWithAppKey:appKey launchOptions:launchOptions];
}

+ (void)setLogEnabled:(BOOL)value {
    [ZhugePush sharedInstance].isLogEnabled = value;
}

+ (void)handleRemoteNotification:(NSDictionary *)userInfo {
    if (userInfo && userInfo[@"mid"]) {
        [[ZhugePush sharedInstance] setMessageRead:userInfo[@"mid"]];
    }
}


static ZhugePush *sharedInstance = nil;
+ (ZhugePush *)sharedInstance {
    if (sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[super alloc] init];
        });
        return sharedInstance;
    }
    
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.serverUrl = @"http://apipool.37degree.com/open/?method=setting_srv.srv_list_get";
        
        self.retry = 3;
        
        self.seq = [NSNumber numberWithInt:1];
        self.ver = [NSNumber numberWithInt:1];
        
        self.deviceTokenUploaded = NO;
        
        self.unreadMessages = [[NSMutableArray alloc] init];
        
        _connectQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)openWithAppKey:(NSString *)appkey launchOptions:(NSDictionary *)launchOptions {
    self.appKey = appkey;
    
    self.readyState = ZGNotificationStateConnecting;
    
    [self _getServers];
    [self _connect];
    
//    if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
//        NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
//        if (userInfo && userInfo[@"mid"]) {
//            [self setMessageRead:userInfo[@"mid"]];
//        }
//    }
}

- (void)_connect {
    if (self.servers != nil && self.servers.count > 0) {
        self.currentServer = self.servers[arc4random() % [self.servers count]];
        
        if (self.isLogEnabled) {
            NSLog(@"尝试连接服务器: %@", self.currentServer);
        }
        
        if (self.currentServer) {
            NSArray *serverItems = [self.currentServer componentsSeparatedByString:@":"];
            
            CFReadStreamRef readStream;
            CFWriteStreamRef writeStream;
            
            CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)serverItems[0], [serverItems[1] intValue], &readStream, &writeStream);
            
            _inputStream = (NSInputStream *)CFBridgingRelease(readStream);
            _outputStream = (NSOutputStream *)CFBridgingRelease(writeStream);
            
            _inputStream.delegate = self;
            _outputStream.delegate = self;
            
            NSRunLoop * rl = [NSRunLoop zgNetworkRunLoop];
            [_inputStream scheduleInRunLoop:rl forMode:NSDefaultRunLoopMode];
            [_outputStream scheduleInRunLoop:rl forMode:NSDefaultRunLoopMode];
            
            [_inputStream open];
            [_outputStream open];
            
            [self login];
        }
    }
}

- (void)_connectFailed {
    if (self.servers != nil && self.servers.count > 0 ) {
        [self.servers removeObject:self.currentServer];
    }
    
    if (self.servers != nil && self.servers.count > 0) {
        [self _connect];
    } else {
        if (self.retry > 0) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"zgPushServers"];
            [self _getServers];
            self.retry--;
            [self _connect];
        }
    }
}

- (void) _getServers {
    self.servers = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"zgPushServers"] mutableCopy];
    if (self.servers == nil || self.servers.count == 0) {
        if (self.isLogEnabled) {
            NSLog(@"推送服务器列表不存在，正在重新获取服务器列表...");
        }
        
        NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&did=%@", self.serverUrl, self.deviceId]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        
        NSError *error = nil;
        NSURLResponse *urlResponse = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
        
        if (error) {
            if (self.isLogEnabled) {
                NSLog(@"%@ 获取推送服务器列表错误: %@", self, error);
            }
            return;
        }
        
        NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (self.isLogEnabled) {
            NSLog(@"http response: %@", object);
        }
        self.servers = [object[@"data"][@"servers"] mutableCopy];
        [[NSUserDefaults standardUserDefaults] setObject:self.servers forKey:@"zgPushServers"];
        if (self.isLogEnabled) {
            NSLog(@"重新获取推送服务器列表成功:%@", self.servers);
        }
    }
}

- (void)close {
    _inputStream.delegate = nil;
    _outputStream.delegate = nil;
    
    [_inputStream close];
    [_outputStream close];
    self.readyState = ZGNotificationStateClosed;
}


#pragma mark - 请求命令

// 登录
- (void) login {
    NSMutableDictionary *msg = [NSMutableDictionary dictionary];
    msg[@"appid"] = self.appKey;
    msg[@"did"] = self.deviceId;
    msg[@"dtype"] = [NSNumber numberWithInt:2];
    msg[@"encrypt"] = [NSNumber numberWithInt:0];
    msg[@"compress"] = [NSNumber numberWithInt:0];
    
    [self sendMessage:msg withCmd:ZGNoticeCmdLogin];
}

// 注册device token
- (void) registerDeviceToken:(NSString *)deviceToken {
    self.deviceToken = deviceToken;
    
    if (self.readyState == ZGNotificationStateLogin) {
        NSMutableDictionary *msg = [NSMutableDictionary dictionary];
        msg[@"cid"] = self.cid;
        msg[@"token"] = deviceToken;
        
        [self sendMessage:msg withCmd:ZGNoticeCmdUploadToken];
    }
}

// 获取客户端ID
- (NSString *) getClientId {
    return self.cid;
}

- (void) sendGetClientId {
    NSMutableDictionary *msg = [NSMutableDictionary dictionary];
    msg[@"deviceId"] = self.deviceId;
    msg[@"dtype"] = [NSNumber numberWithInt:DEVICE_TYPE];
    msg[@"appid"] = self.appKey;
    
    [self sendMessage:msg withCmd:ZGNoticeCmdGetClientId];
}

- (void) setMessageRead:(NSString *)messageId {
    if (messageId) {
        [self.unreadMessages addObject:messageId];
    }
    if (self.readyState != ZGNotificationStateLogin) {
        [self _connect];
    }
    
    [self _sendMessageRead];

}

- (void) _sendMessageRead {
    if (self.unreadMessages && self.unreadMessages.count > 0) {
        for (NSString *messageId in self.unreadMessages) {
            NSMutableDictionary *msg = [NSMutableDictionary dictionary];
            msg[@"id"] = messageId;
            [self sendMessage:msg withCmd:ZGNoticeCmdSetMsgRead];
        }
    }
}


- (void) sendMessage:(NSMutableDictionary *) msg withCmd:(uint16_t) cmd {
    msg[@"seq"] = self.seq;
    msg[@"ver"] = self.ver;
    
    NSString *json = [[NSString alloc] initWithData:[self JSONSerializeObject:msg] encoding:NSUTF8StringEncoding];
    if (self.isLogEnabled) {
        NSLog(@"发生请求: %@", json);
    }
    NSInteger iLenJson = json.length;
    
    PkgHeader pkgHeader;
    pkgHeader.iHeadLen = CFSwapInt16HostToBig(sizeof(pkgHeader));
    pkgHeader.iCmdType = CFSwapInt16HostToBig(cmd);
    pkgHeader.iTotalLen = CFSwapInt32HostToBig(sizeof(pkgHeader) + (uint32_t)iLenJson);
    
    NSMutableData *data = [NSMutableData data];
    [data appendBytes:&pkgHeader length:sizeof(pkgHeader)];
    [data appendBytes:[json UTF8String] length:iLenJson];
    
    dispatch_async(self->_connectQueue, ^{
        [_outputStream write:[data bytes] maxLength:[data length]];
    });
}

#pragma mark - 响应

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    switch (streamEvent) {
        case  NSStreamEventOpenCompleted:
            if (self.isLogEnabled) {
                NSLog(@"NSStreamEventOpenCompleted");
            }
            if (theStream == _inputStream) {
                self.readyState = ZGNotificationStateConnected;
                if (self.isLogEnabled) {
                    NSLog(@"已建立连接");
                }
            }
            break;
        case  NSStreamEventHasBytesAvailable:
            if (self.isLogEnabled) {
                NSLog(@"NSStreamEventHasBytesAvailable");
            }

            if (theStream == _inputStream) {
                [self recvData];
            }
            break;
        case  NSStreamEventHasSpaceAvailable:
            if (self.isLogEnabled) {
                NSLog(@"NSStreamEventHasSpaceAvailable");
            }
            break;
        case  NSStreamEventErrorOccurred:
            if (self.isLogEnabled) {
                NSLog(@"NSStreamEventErrorOccurred %@ %@", theStream, [[theStream streamError] copy]);
            }
            if (self.readyState == ZGNotificationStateConnecting) {
                if (self.isLogEnabled) {
                    NSLog(@"连接失败");
                }
                [self _connectFailed];
            }
            
            break;
        case  NSStreamEventEndEncountered:
            if (self.isLogEnabled) {
                NSLog(@"NSStreamEventEndEncountered");
            }
            break;
        default:
            if (self.isLogEnabled) {
                NSLog(@"no event : %lu", streamEvent);
            }
            break;
    }
}

-(void) recvData {
    const int bufferSize = 2048;
    uint8_t buffer[bufferSize];
    while ([_inputStream hasBytesAvailable]) {
        NSInteger readBytes = [_inputStream read:buffer maxLength:bufferSize];
        if (readBytes > 0) {
            NSData *data = [NSData dataWithBytes:buffer length:readBytes];
            
            PkgHeader pkgHeader;
            [data getBytes:&pkgHeader length:sizeof(pkgHeader)];
            unsigned int iHeadLen = CFSwapInt16BigToHost(pkgHeader.iHeadLen);
            unsigned int iCmdType = CFSwapInt16BigToHost(pkgHeader.iCmdType);
            unsigned int iTotalLen = CFSwapInt32BigToHost(pkgHeader.iTotalLen);
            unsigned int iBodyLen = iTotalLen - iHeadLen;
            
            if (self.isLogEnabled) {
                NSLog(@"PkgHeader iCmdType: %u,iHeadLen: %u, iTotalLen: %u", iCmdType, iHeadLen, iTotalLen);
            }
            void *msgBuf = malloc(2048);
            [data getBytes:msgBuf range:NSMakeRange(iHeadLen, iBodyLen)];
            NSDictionary *ack = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:msgBuf length:iBodyLen ] options:0 error:nil];
            
            if (self.isLogEnabled) {
                NSLog(@"响应: %@", ack);
            }
            if (ack == nil || [ack[@"ret"] intValue] != 0) {
                if (self.isLogEnabled) {
                    NSLog(@"接收数据失败");
                }
                return;
            }
            
            switch (iCmdType) {
                case ZGNoticeCmdAckLogin:
                    if (self.isLogEnabled) {
                        NSLog(@"登录成功");
                    }
                    [self sendGetClientId];
                    break;
                case ZGNoticeCmdAckGetClientId:
                    if (self.isLogEnabled) {
                        NSLog(@"获取ClientId成功");
                    }
                    self.cid = ack[@"cid"];
                    [[NSUserDefaults standardUserDefaults] setObject:self.cid forKey:@"zgPushClientId"];
                    self.readyState = ZGNotificationStateLogin;
                    
                    if (!self.deviceTokenUploaded && self.deviceToken) {
                        [self registerDeviceToken:self.deviceToken];
                    }
                    
                    [self _sendMessageRead];
                    
                    break;
                case ZGNoticeCmdAckUploadToken:
                    if (self.isLogEnabled) {
                        NSLog(@"注册DeviceToken成功");
                    }
                    self.deviceTokenUploaded = YES;
                    break;
                case ZGNoticeCmdAckSetMsgRead:
                    if (self.isLogEnabled) {
                        NSLog(@"消息设置已读成功");
                    }
                    if (self.unreadMessages && self.unreadMessages.count > 0) {
                        [self.unreadMessages removeObjectAtIndex:0];
                    }
                    break;
                case ZGNoticeCmdMsg:
                    if (self.isLogEnabled) {
                        NSLog(@"获取消息 msg: %@", NSStringFromClass([ack[@"msg"] class]));
                    }
                    break;
                default:
                    break;
            }
            
            
        }
    }
}

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
        NSLog(@"%@ error encoding api data: %@", self, error);
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
                NSLog(@"%@ warning: property keys should be strings. got: %@. coercing to: %@", self, [key class], stringKey);
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
    NSLog(@"%@ warning: property values should be valid json types. got: %@. coercing to: %@", self, [obj class], s);
    return s;
}


- (void)dealloc {
    _inputStream.delegate = nil;
    _outputStream.delegate = nil;
    
    [_inputStream close];
    [_outputStream close];
}


@end

#pragma mark - NSRunLoop

static _ZGRunLoopThread *networkThread = nil;
static NSRunLoop *networkRunLoop = nil;

@implementation NSRunLoop (ZGNotificationManager)

+ (NSRunLoop *)zgNetworkRunLoop {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkThread = [[_ZGRunLoopThread alloc] init];
        networkThread.name = @"io.zhuge.push.NetworkThread";
        [networkThread start];
        networkRunLoop = networkThread.runLoop;
    });
    
    return networkRunLoop;
}

@end

@implementation _ZGRunLoopThread {
    dispatch_group_t _waitGroup;
}

@synthesize runLoop = _runLoop;

- (id)init {
    self = [super init];
    if (self) {
        _waitGroup = dispatch_group_create();
        dispatch_group_enter(_waitGroup);
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        _runLoop = [NSRunLoop currentRunLoop];
        dispatch_group_leave(_waitGroup);
        
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate distantFuture] interval:0.0 target:nil selector:nil userInfo:nil repeats:NO];
        [_runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        
        while ([_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            
        }
        assert(NO);
    }
}

- (NSRunLoop *)runLoop {
    dispatch_group_wait(_waitGroup, DISPATCH_TIME_FOREVER);
    return _runLoop;
}

@end
