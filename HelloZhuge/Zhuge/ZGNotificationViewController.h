#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "ZGNotification.h"

@protocol ZGNotificationViewControllerDelegate;

@interface ZGNotificationViewController : UIViewController

@property (nonatomic, strong) ZGNotification *notification;
@property (nonatomic, weak) id<ZGNotificationViewControllerDelegate> delegate;

- (void)hideWithAnimation:(BOOL)animated completion:(void (^)(void))completion;

@end

@interface ZGTakeoverNotificationViewController : ZGNotificationViewController

@property (nonatomic, strong) UIImage *backgroundImage;

@end

@interface ZGMiniNotificationViewController : ZGNotificationViewController

- (void)showWithAnimation;

@end

@protocol ZGNotificationViewControllerDelegate <NSObject>

- (void)notificationController:(ZGNotificationViewController *)controller wasDismissedWithStatus:(BOOL)status;

@end
