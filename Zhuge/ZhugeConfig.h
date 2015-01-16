#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif
//
//  ZhugeConfig.h
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>

/* SDK版本 */
#define ZG_SDK_VERSION @"2.0"

/* 默认应用版本 */
#define ZG_APP_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]

/* 渠道 */
#define ZG_CHANNEL @"App Store"

/* 发送策略 */
// 默认是启动时发送(SEND_INTERVAL)
typedef enum {
    SEND_REALTIME  = 1, // 实时发送，app每产生一个事件都会发送到服务器。
    SEND_WIFI_ONLY = 2, // 仅在WIFI下启动时发送，非WIFI情况缓存到本地。
    SEND_ON_START  = 3, // 启动时发送，本次启动产生的所有数据在下次启动时发送。
    SEND_INTERVAL  = 4  // 间隔一段时间发送，每隔一段时间一次性发送到服务器，默认10秒。
} ReportPolicy;

@interface ZhugeConfig : NSObject

// SDK版本
@property (nonatomic, copy) NSString *sdkVersion;
// 应用版本(默认:info.plist中CFBundleShortVersionString对应的值)
@property (nonatomic, copy) NSString *appVersion;
// 渠道(默认:@"App Store")
@property (nonatomic, copy) NSString *channel;

// 两次会话时间间隔(默认:30秒)
@property (nonatomic) NSUInteger sessionInterval;

// 发送策略(默认:SEND_INTERVAL)
@property (nonatomic, readwrite) ReportPolicy policy;
// 每天最大上报事件数，超出部分缓存到本地(默认:1000个)
@property (nonatomic) NSUInteger sendMaxSizePerDay;
// 本地缓存事件数(默认:1000个)
@property (nonatomic) NSUInteger cacheMaxSize;
// 上报时间间隔，只有发送策略是SEND_INTERVAL时有效(默认:10秒)
@property (nonatomic) NSUInteger sendInterval;

// 是否开启SDK日志打印(默认:关闭)
@property (nonatomic) BOOL isLogEnabled;
// 是否开启崩溃报告(默认:开启)
@property (nonatomic) BOOL isCrashReportEnabled;
// 是否允许从官网更新配置(默认:开启)
@property (nonatomic) BOOL isOnlineConfigEnabled;

- (void) updateOnlineConfig:(NSString *) configString;

// 是否开启PING(默认:关闭)
@property (nonatomic) BOOL isPingEnabled;
// PING时间间隔(默认:30秒)
@property (nonatomic) NSUInteger pingInterval;

@end
