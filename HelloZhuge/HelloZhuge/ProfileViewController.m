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
    NSString * did = [[Zhuge sharedInstance] getDeviceId];
    if (did) {
        self.uid.text = [did substringToIndex:6];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (IBAction)identify:(id)sender {
    NSNumber *id = @(round([[NSDate date] timeIntervalSince1970]));

    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    user[@"name"] = self.name.text;
    user[@"gender"] = @"男";
    user[@"birthday"] = @"2014/11/11";
    user[@"avatar"] = @"http://tp2.sinaimg.cn/2885710157/180/5637236139/1";
    user[@"email"] = self.email.text;
    user[@"mobile"] = @"18901010210";
    user[@"qq"] = [NSString stringWithFormat:@"%@", id];
    user[@"weixin"] = [NSString stringWithFormat:@"wx%@", id];
    user[@"weibo"] = [NSString stringWithFormat:@"wb%@", id];
    user[@"location"] = @"北京 朝阳区";
    user[@"公司"] = @"zhuge";
    [[Zhuge sharedInstance] identify:self.uid.text properties:nil];
}

@end
