//
//  AppDelegate.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "AppDelegate.h"
#import "Zhuge.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    Zhuge *zhuge = [Zhuge sharedInstance];

    // 打开SDK日志打印
    
    BOOL state = NO;
    
    while (!state) {
        NSLog(@"state is %@",state?@"YES":@"NO");
        state = !state;
    }
    
    // 自定义版本和渠道
    [zhuge.config setAppVersion:@"2.0-dev"]; // 默认是info.plist中CFBundleShortVersionString值
    [zhuge.config setChannel:@"App Store"]; // 默认是@"App Store"
    
//    zhuge.config.sendInterval = 20; //上报时间间隔。
    zhuge.config.cacheMaxSize = 300; //本地最大记录缓存数。
    zhuge.config.sendMaxSizePerDay = 1000; //每日最大上传记录数。

    // 推送指定deviceToken上传到开发环境或生产环境，默认YES，上传到生产环境
    [zhuge.config setApsProduction:NO];

//    [zhuge setUploadURL:@"https://dc.ajksosd.com" andBackupUrl:@""];
    // 启动诸葛
//    [zhuge startWithAppKey:@"067aefa9498e4f75b156d9eb378c1fe4" andDid:@"12314215" launchOptions:launchOptions];
    [[Zhuge sharedInstance]startWithAppKey:@"appkey" launchOptions:launchOptions];
    [zhuge.config setDebug:YES]; // 默认关闭

    // 第三方推送(启用第三方推送时，请在startWithAppKey后调用)
//    [zhuge setThirdPartyPushUserId:@"getui12345678901234567890" forChannel:ZG_PUSH_CHANNEL_GETUI];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    return YES;
}


-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@",error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (userInfo) {
        NSLog(@"didReceiveRemoteNotification: %@" ,userInfo);
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[Zhuge sharedInstance] handleRemoteNotification:userInfo];
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    if (userInfo) {
        NSLog(@"handleActionWithIdentifier: %@" ,userInfo);
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[Zhuge sharedInstance] handleRemoteNotification:userInfo];

}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[Zhuge sharedInstance] track:@"app resign active"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[Zhuge sharedInstance] track:@"app active"];
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
