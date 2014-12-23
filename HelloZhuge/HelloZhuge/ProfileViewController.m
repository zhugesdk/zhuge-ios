//
//  ProfileViewController.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "ProfileViewController.h"
#import "Zhuge.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //页面开始
//    [[Zhuge sharedInstance] pageStart:@"我"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //页面结束
//    [[Zhuge sharedInstance] pageEnd:@"我"];
}

- (IBAction)identify:(id)sender {
    NSNumber *uid = @(round([[NSDate date] timeIntervalSince1970]));

    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    user[@"name"] = [NSString stringWithFormat:@"zhuge-%@", uid];
    user[@"gender"] = @"男";
    user[@"birthday"] = @"2014/11/11";
    user[@"avatar"] = @"http://tp2.sinaimg.cn/2885710157/180/5637236139/1";
    user[@"email"] = [NSString stringWithFormat:@"zhuge-%@@zhuge.io", uid];
    user[@"mobile"] = @"18901010101";
    user[@"qq"] = [NSString stringWithFormat:@"%@", uid];
    user[@"weixin"] = [NSString stringWithFormat:@"wx%@", uid];
    user[@"weibo"] = [NSString stringWithFormat:@"wb%@", uid];
    user[@"location"] = @"北京 朝阳区";
    user[@"公司"] = @"37degree";
    [[Zhuge sharedInstance] identify:[NSString stringWithFormat:@"%@", uid] properties:user];

}

@end
