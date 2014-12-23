#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZGNotification.h"

typedef enum {
    ZGNotificationManagerStateConnecting = 0, // 正在连接
    ZGNotificationManagerStateConnected  = 1, // 已连接
    ZGNotificationManagerStateLogin      = 2, // 已登录
    ZGNotificationManagerStateClosing    = 3, // 正在关闭
    ZGNotificationManagerClosed          = 4  // 已关闭
} ZGNotificationManagerState;


@interface ZGNotificationManager : NSObject

// 开启消息服务
- (void)openWithAppKey:(NSString *)appkey andDeviceId:(NSString *)deviceId;

// 当前状态
- (ZGNotificationManagerState)state;

// 注册device token
- (void) registerDeviceToken:(NSString *)deviceToken;
// 获取客户端ID
- (NSString *) getClientId;

// 清除未读消息数量
- (void) clearMessageCount;
// 标记消息已读
- (void) setMessageReaded:(NSString *) messageId;

// 设置消息屏蔽
- (void) setMessageShield:(BOOL) shield;
// 获取消息屏蔽
- (BOOL) getMessageShield;

// 设置消息屏蔽时间
- (void) setMessageReceiveTimeStart:(int) start AndEnd:(int) end;
// 获取消息屏蔽时间
- (NSDictionary *) getMessageReceiveTime;

// 关闭消息服务
- (void)close;

#pragma mark - 通知
- (void)showNotification;
- (void)showNotificationWithID:(NSUInteger)ID;
- (void)showNotificationWithType:(NSString *)type;
- (void)showNotificationWithObject:(ZGNotification *)notification;

@end


