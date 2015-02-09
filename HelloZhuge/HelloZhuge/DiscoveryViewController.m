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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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

- (IBAction)invoke:(id)sender {
    if (self.eventName.text != nil && self.eventName.text.length !=0) {
        NSString* event = self.eventName.text;
        if (self.prop1.text != nil && self.prop1.text.length !=0 &&
            self.value1.text != nil && self.value1.text.length !=0) {
            NSDictionary* properties = @{self.prop1.text : self.value1.text};
            [[Zhuge sharedInstance] track: event properties: properties];
        } else {
            [[Zhuge sharedInstance] track: event];
        }
        

    }

}

@end
