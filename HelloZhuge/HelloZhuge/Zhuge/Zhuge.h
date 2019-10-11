//
//  Zhuge.h
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZhugeConfig.h"
#import "ZhugeEventProperty.h"

@interface Zhuge : NSObject

#pragma mark - 获取实例

/**
 获取诸葛统计的实例。
 */
+ (nonnull Zhuge*)sharedInstance;

/**
 获得诸葛配置实例。
 */
- (nonnull ZhugeConfig *)config;

/**
 获得诸葛设备ID。
 */
- (nonnull NSString *)getDid;
-(nonnull NSString *)getSid;
#pragma mark - 开启统计
/**
 诸葛上传地址
 */
-(void)setUploadURL:(nonnull NSString*)url andBackupUrl:(nullable NSString *)backupUrl;

-(void)setUtm:(nonnull NSDictionary *)utmInfo;

/**
 开启诸葛统计。
 
 @param appKey 应用Key，网站上注册应用时自动获得
 */
- (void)startWithAppKey:(nonnull NSString*)appKey launchOptions:(nullable NSDictionary*)launchOptions;

-(void)startWithAppKey:(nonnull NSString *)appKey andDid:(nonnull NSString*)did launchOptions:(nullable NSDictionary *)launchOptions;
#pragma mark - 追踪用户行为

/**
 标识用户。
 @param userId     用户ID
 @param properties 用户属性
 */
- (void)identify:(nonnull NSString*)userId properties:(nullable   NSDictionary *)properties;

/**
 userID不变，仅更新用户属性
 @param properties 属性
 */
-(void)updateIdentify:(nonnull NSDictionary *)properties;

/**
 设置事件环境信息，通过这个地方存入的信息将会给之后传入的每一个事件添加环境信息
 */
-(void) setSuperProperty:(nonnull NSDictionary *)info;

-(void) setPlatform:(nonnull NSDictionary *)info;
- (void)track:(nonnull NSString *)event;

/** 追踪收入事件
 *  @param 事件属性
 */
- (void)trackRevenue:(nullable NSDictionary *)properties;

/**
 追踪自定义事件。
 
 @param event      事件名称
 @param properties 事件属性
 */
- (void)track:(nonnull NSString *)event properties:(nullable NSDictionary *)properties;
/**
 开始追踪一个耗时事件，这个借口并不会真正的统计这个事件。当你调用endTrack时，会统计两个接口之间的耗时，
 并作为一个属性添加到事件之中
 @param eventName 事件名称
 */
-(void)startTrack:(nonnull NSString *)eventName;

-(void)endTrack:(nonnull NSString *)eventName properties:(nullable NSDictionary *)properties;
#pragma mark - 推送
// 支持的第三方推送渠道
typedef enum {
    ZG_PUSH_CHANNEL_XIAOMI = 1, // 小米
    ZG_PUSH_CHANNEL_JPUSH = 2, // 极光推送
    ZG_PUSH_CHANNEL_UMENG = 3, // 友盟
    ZG_PUSH_CHANNEL_BAIDU = 4, // 百度云推送
    ZG_PUSH_CHANNEL_XINGE = 5, // 信鸽
    ZG_PUSH_CHANNEL_GETUI = 6 // 个推
} ZGPushChannel;


// 处理接收到的消息
- (void)handleRemoteNotification:(nonnull NSDictionary *)userInfo;

// 设置第三方推送用户ID
- (void)setThirdPartyPushUserId:(nonnull NSString *)userId forChannel:(ZGPushChannel) channel;
@end
