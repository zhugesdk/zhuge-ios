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
    [zhuge.config setLogEnabled:YES]; // 默认关闭
    
    [zhuge.config setDebug:YES]; // 默认关闭
    
    // 自定义版本和渠道
    [zhuge.config setAppVersion:@"2.0-dev"]; // 默认是info.plist中CFBundleShortVersionString值
    [zhuge.config setChannel:@"App Store"]; // 默认是@"App Store"
    
    // 推送指定deviceToken上传到开发环境或生产环境，默认NO，上传到开发环境
    [zhuge.config setApsProduction:NO];

    // 开启推送
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        [zhuge registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                       UIUserNotificationTypeSound |
                                                       UIUserNotificationTypeAlert)
                                           categories:nil];
    } else {
        [zhuge registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                       UIRemoteNotificationTypeSound |
                                                       UIRemoteNotificationTypeAlert)
                                           categories:nil];
    }
#else
        [zhuge registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                       UIRemoteNotificationTypeSound |
                                                       UIRemoteNotificationTypeAlert)
                                           categories:nil];
#endif
    
    // 启动诸葛
    [zhuge startWithAppKey:@"e7a39acb186b4049b91306a4b6965e5d" launchOptions:launchOptions];
    
    // 第三方推送(启用第三方推送时，请在startWithAppKey后调用)
//    [zhuge setThirdPartyPushUserId:@"getui12345678901234567890" forChannel:ZG_PUSH_CHANNEL_GETUI];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken");
    [[Zhuge sharedInstance] registerDeviceToken:deviceToken];
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

    completionHandler(UIBackgroundFetchResultNewData);
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
