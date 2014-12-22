//
//  HomeViewController.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "HomeViewController.h"
#import "Zhuge.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //页面开始
//    [[Zhuge sharedInstance] pageStart:@"首页"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //页面结束
//    [[Zhuge sharedInstance] pageEnd:@"首页"];
}


@end
