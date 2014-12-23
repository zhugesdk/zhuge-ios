#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>

typedef enum {
    ZGNotificationManagerStateConnecting = 0, // 正在连接
    ZGNotificationManagerStateConnected  = 1, // 已连接
    ZGNotificationManagerStateLogin      = 2, // 已登录
    ZGNotificationManagerStateClosing    = 3, // 正在关闭
    ZGNotificationManagerClosed          = 4  // 已关闭
} ZGNotificationManagerState;


@interface ZhugeNoticeManager : NSObject

// 开启消息服务
- (void)openWithAppKey:(NSString *)appkey andDeviceId:(NSString *)deviceId;

// 当前状态
- (ZGNotificationManagerState)state;

// 注册 Device Token
- (void) registerDeviceToken:(NSString *)deviceToken;

// 获取客户端ID
- (NSString *) getClientId;

// 关闭消息服务
- (void)close;

@end
