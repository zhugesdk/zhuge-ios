//
//  DiscoveryViewController.h
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DiscoveryViewController : UIViewController

- (IBAction)scan:(id)sender;
- (IBAction)feed:(id)sender;
- (IBAction)shopping:(id)sender;
- (IBAction)invoke:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *eventName;
@property (weak, nonatomic) IBOutlet UITextField *prop1;
@property (weak, nonatomic) IBOutlet UITextField *value1;

@end

