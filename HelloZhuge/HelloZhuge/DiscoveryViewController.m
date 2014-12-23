//
//  DiscoveryViewController.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "DiscoveryViewController.h"
#import "Zhuge.h"

@interface DiscoveryViewController ()

@end

@implementation DiscoveryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //页面开始
    [[Zhuge sharedInstance] pageStart:@"发现"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //页面结束
    [[Zhuge sharedInstance] pageEnd:@"发现"];
}


- (IBAction)scan:(id)sender {
    [[Zhuge sharedInstance] track:@"扫一扫"];
}

- (IBAction)feed:(id)sender {
    [[Zhuge sharedInstance] track:@"朋友圈"];

}

- (IBAction)shopping:(id)sender {
    [[Zhuge sharedInstance] track:@"购物" properties: @{@"商家":@"京东"}];
}

- (IBAction)showMiniNotice:(id)sender {
    
    NSMutableDictionary *notice = [NSMutableDictionary dictionary];
    notice[@"type"] = @"mini";
    notice[@"id"] = [NSNumber numberWithInt:1217];
    notice[@"message_id"] = [NSNumber numberWithInt:1217001];
    notice[@"title"] = @"推荐有礼";
    notice[@"body"] = @"推荐办卡送1000积分";
    notice[@"image_url"] = @"http://37degree.com/img/fenxi-icon.png";
    notice[@"cta"] = @"推荐给好友";
    notice[@"cta_url"] = @"http://www.baidu.com";
    
    [[Zhuge sharedInstance].noticeMgr showNotificationWithObject:[ZGNotification notificationWithJSONObject: notice]];
}

- (IBAction)showTakeoverNotice:(id)sender {
    
    NSMutableDictionary *notice = [NSMutableDictionary dictionary];
    notice[@"type"] = @"takeover";
    notice[@"id"] = [NSNumber numberWithInt:1217];
    notice[@"message_id"] = [NSNumber numberWithInt:1217001];
    notice[@"title"] = @"推荐有礼";
    notice[@"body"] = @"推荐办卡送1000积分";
    notice[@"image_url"] = @"http://37degree.com/img/fenxi-icon.png";
    notice[@"cta"] = @"推荐给好友";
    notice[@"cta_url"] = @"http://www.baidu.com";
    
    [[Zhuge sharedInstance].noticeMgr showNotificationWithObject:[ZGNotification notificationWithJSONObject: notice]];

}
@end
