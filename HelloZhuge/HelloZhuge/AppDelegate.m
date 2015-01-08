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
    [zhuge.config setIsLogEnabled:YES]; // 默认关闭
    
    // 可以自定义版本和渠道
    [zhuge.config setAppVersion:@"2.0-dev"]; // 默认是info.plist中CFBundleShortVersionString值
    [zhuge.config setChannel:@"App Store"]; // 默认是@"App Store"

    // 开启行为追踪
    [zhuge startWithAppKey:@"a03fa1da94ec4c23a7325f8dad4629c8" launchOptions:launchOptions];
    
    
    // 开启推送通知
    #if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_8_0
        [ZhugePush registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                       UIUserNotificationTypeSound |
                                                       UIUserNotificationTypeAlert)
                                           categories:nil];
    #elif __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
        [ZhugePush registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                       UIRemoteNotificationTypeSound |
                                                       UIRemoteNotificationTypeAlert)
                                           categories:nil]];
        }
    #else
        [ZhugePush registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                       UIRemoteNotificationTypeSound |
                                                       UIRemoteNotificationTypeAlert)
                                           categories:nil]];
    #endif
    [ZhugePush registerDeviceId:[zhuge getDeviceId]];
    [ZhugePush startWithAppKey:@"a03fa1da94ec4c23a7325f8dad4629c8" launchOptions:launchOptions];
    [ZhugePush setLogEnabled:YES];
    
    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken");
    [ZhugePush registerDeviceToken:deviceToken];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@",error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification: %@" ,userInfo);
    [ZhugePush handleRemoteNotification:userInfo];
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
