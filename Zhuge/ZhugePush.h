#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZhugeConfig.h"

@interface ZhugePush : NSObject

// 注册APNS远程消息类型
- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types categories:(NSSet *)categories;

// 注册设备ID(从统计平台中取得，保持两者一致)
- (void)registerDeviceId:(NSString *)deviceId;

// 注册deviceToken
- (void)registerDeviceToken:(NSData *)deviceToken;

// 初始化
- (void)startWithAppKey:(NSString *)appKey launchOptions:(NSDictionary *)launchOptions;

// 处理接收到的消息
- (void)handleRemoteNotification:(NSDictionary *)userInfo;

// 配置文件
- (void) setConfig:(ZhugeConfig *) config;

@end
