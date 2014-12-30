//
//  ProfileViewController.h
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileViewController : UIViewController
- (IBAction)identify:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *uid;
@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *email;
@end
