#import <Foundation/Foundation.h>

@interface ZGNotification : NSObject
extern NSString *const ZGNotificationTypeMini;
extern NSString *const ZGNotificationTypeTakeover;

@property (nonatomic, readonly) NSUInteger ID;
@property (nonatomic, readonly) NSUInteger messageID;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSData *image;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *callToAction;
@property (nonatomic, strong) NSURL *callToActionURL;

+ (ZGNotification *)notificationWithJSONObject:(NSDictionary *)object;

- (instancetype)init __unavailable;
@end
