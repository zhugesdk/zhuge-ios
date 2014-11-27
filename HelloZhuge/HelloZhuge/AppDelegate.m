//
//  AppDelegate.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "AppDelegate.h"
#import "Zhuge.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /*  
     正式环境 
     */
    // [[Zhuge sharedInstance] startWithAppKey:@"0a824f87315749a49c16fcbaea277707"];

    /* 
     开发调试时
     */
    Zhuge *zhuge = [Zhuge sharedInstance];
    
    // 关闭从线上更新配置
    [zhuge.config setIsOnlineConfigEnabled:NO]; // 默认开启
    
    // 设置上报策略
    //[zhuge.config setPolicy:SEND_ON_START]; // 启动时发送(默认)
    [zhuge.config setPolicy:SEND_REALTIME]; // 实时发送
    [zhuge.config setPolicy:SEND_INTERVAL]; // 按时间间隔发送
    [zhuge.config setSendInterval:30]; //默认间隔是10秒发送一次，最大不能超过一天(86400)

    // 打开SDK日志打印
    [zhuge.config setIsLogEnabled:YES]; // 默认关闭
    
    // 可以自定义版本和渠道
    [zhuge.config setAppVersion:@"0.9-beta"]; // 默认是info.plist中CFBundleShortVersionString值
    [zhuge.config setChannel:@"My App Store"]; // 默认是@"App Store"

    // 开启行为追踪
    [zhuge startWithAppKey:@"0a824f87315749a49c16fcbaea277707"];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {
 
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

}

@end
