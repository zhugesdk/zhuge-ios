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
    [[Zhuge sharedInstance] track:@"朋友圈" properties: @{@"商家":@"京东"}];
}
@end
