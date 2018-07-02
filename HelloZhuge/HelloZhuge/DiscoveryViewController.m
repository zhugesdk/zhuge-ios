//
//  DiscoveryViewController.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "DiscoveryViewController.h"
#import "Zhuge.h"

@interface DiscoveryViewController ()
@property (weak, nonatomic) IBOutlet UITextField *upLoadText;
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

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    [self.view endEditing:YES];
}

- (IBAction)scan:(id)sender {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [[Zhuge sharedInstance] track:@"扫一扫"];
//    });
    NSLog(@"scan");
    [self performSelector:@selector(setTeamData)];
}

- (IBAction)feed:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[Zhuge sharedInstance] startTrack:@"朋友圈"];
    });
}

- (IBAction)shopping:(id)sender {
    
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [[Zhuge sharedInstance] endTrack:@"朋友圈" properties: @{@"商家":@"京东"}];
//
//    });
    NSArray *array = [[NSArray alloc]initWithObjects:@"1",@"2",@"324", nil];
    NSString *a = array[3];
    NSLog(@"a is %@",a);
}

- (IBAction)invoke:(id)sender {
    if (self.eventName.text != nil && self.eventName.text.length !=0) {
        NSString* event = self.eventName.text;
        if (self.prop1.text != nil && self.prop1.text.length !=0 &&
            self.value1.text != nil && self.value1.text.length !=0) {
            NSDictionary* properties = @{self.prop1.text : self.value1.text,@"是否为空":@YES};
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[Zhuge sharedInstance] track: event properties: properties];

            });
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[Zhuge sharedInstance] track: event];
            });
        }
    }
}

- (IBAction)setEventInfo:(id)sender {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if (self.prop1.text && self.value1.text) {
        [dic setObject:self.value1.text forKey:self.prop1.text];
    }
    if (self.prop2.text && self.value2) {
        [dic setObject:self.value2.text forKey:self.prop2.text];
    }
    if ([dic count]) {
        [[Zhuge sharedInstance] setSuperProperty:dic];
    }
    
    
}

- (IBAction)setDeviceInfo:(id)sender {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if (self.prop1.text && self.value1.text) {
        [dic setObject:self.value1.text forKey:self.prop1.text];
    }
    if (self.prop2.text && self.value2) {
        [dic setObject:self.value2.text forKey:self.prop2.text];
    }
    if ([dic count]) {
        [[Zhuge sharedInstance] setPlatform:dic];
    }
}
- (IBAction)upLoadWithURL:(UIButton *)sender
{
    [[Zhuge sharedInstance] setUploadURL:self.upLoadText.text andBackupUrl:@""];
}


@end
