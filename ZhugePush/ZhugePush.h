#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ZhugePush : NSObject

// 注册APNS远程消息类型
+ (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types categories:(NSSet *)categories;

// 注册设备ID(从诸葛统计平台中取得，保持两者一致)
+ (void)registerDeviceId:(NSString *)deviceId;

// 注册deviceToken
+ (void)registerDeviceToken:(NSData *)deviceToken;

// 初始化
+ (void)startWithAppKey:(NSString *)appKey launchOptions:(NSDictionary *)launchOptions;

// 处理接收到的消息
+ (void)handleRemoteNotification:(NSDictionary *)userInfo;

// 是否开启SDK日志打印(默认:关闭)
+ (void)setLogEnabled:(BOOL)value;

@end
