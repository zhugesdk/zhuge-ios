//
//  ProfileViewController.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "ProfileViewController.h"
#import "Zhuge.h"

@interface ProfileViewController ()
- (IBAction)getSessionID:(id)sender;
- (IBAction)getDeviceID:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *info;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString * did = [[Zhuge sharedInstance] getDid];
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
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    [self.view endEditing:YES];
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
    [[Zhuge sharedInstance] identify:self.uid.text properties:user];
}

- (IBAction)getSessionID:(id)sender {
    NSString *info = [[Zhuge sharedInstance]getSid];
    [self.info setText:[NSString stringWithFormat:@"sessionID : %@",info]];
    
}

- (IBAction)getDeviceID:(id)sender {
    NSString *info = [[Zhuge sharedInstance]getDid];
    [self.info setText:[NSString stringWithFormat:@"deviceID : %@",info]];
}
@end
