//
//  AppDelegate.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "AppDelegate.h"
#import "Zhuge.h"
#import "ZhugePush.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    Zhuge *zhuge = [Zhuge sharedInstance];
    
    // 打开SDK日志打印
    [zhuge.config setLogEnabled:YES]; // 默认关闭
    
    // 自定义版本和渠道
    [zhuge.config setAppVersion:@"2.0-dev"]; // 默认是info.plist中CFBundleShortVersionString值
    [zhuge.config setChannel:@"App Store"]; // 默认是@"App Store"
    
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
    [zhuge startWithAppKey:@"a03fa1da94ec4c23a7325f8dad4629c8" launchOptions:launchOptions];
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
    NSLog(@"didReceiveRemoteNotification: %@" ,userInfo);
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[Zhuge sharedInstance] handleRemoteNotification:userInfo];
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    NSLog(@"handleActionWithIdentifier: %@" ,userInfo);
    completionHandler(UIBackgroundFetchResultNewData);
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
