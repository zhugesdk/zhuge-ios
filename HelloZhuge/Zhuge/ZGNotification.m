#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "ZGNotification.h"

@interface ZGNotification ()

- (id)initWithID:(NSUInteger)ID messageID:(NSUInteger)messageID type:(NSString *)type title:(NSString *)title body:(NSString *)body callToAction:(NSString *)callToAction callToActionURL:(NSURL *)callToActionURL imageURL:(NSURL *)imageURL;

@end

@implementation ZGNotification

NSString *const ZGNotificationTypeMini = @"mini";
NSString *const ZGNotificationTypeTakeover = @"takeover";

+ (ZGNotification *)notificationWithJSONObject:(NSDictionary *)object {
    if (object == nil) {
        NSLog(@"通知JSON不能为nil");
        return nil;
    }
    
    NSNumber *ID = object[@"id"];
    if (!([ID isKindOfClass:[NSNumber class]] && [ID integerValue] > 0)) {
        NSLog(@"无效的通知ID: %@", ID);
        return nil;
    }
    
    NSNumber *messageID = object[@"message_id"];
    if (!([messageID isKindOfClass:[NSNumber class]] && [messageID integerValue] > 0)) {
        NSLog(@"无效的消息ID: %@", messageID);
        return nil;
    }
    
    NSString *type = object[@"type"];
    if (![type isKindOfClass:[NSString class]]) {
        NSLog(@"无效的通知类型: %@", type);
        return nil;
    }
    
    NSString *title = object[@"title"];
    if (![title isKindOfClass:[NSString class]]) {
        NSLog(@"无效的通知标题: %@", title);
        return nil;
    }
    
    NSString *body = object[@"body"];
    if (![body isKindOfClass:[NSString class]]) {
        NSLog(@"无效的通知内容: %@", body);
        return nil;
    }
    
    NSString *callToAction = object[@"cta"];
    if (![callToAction isKindOfClass:[NSString class]]) {
        NSLog(@"无效的通知动作: %@", callToAction);
        return nil;
    }
    
    NSURL *callToActionURL = nil;
    NSObject *URLString = object[@"cta_url"];
    if (URLString != nil && ![URLString isKindOfClass:[NSNull class]]) {
        if (![URLString isKindOfClass:[NSString class]] || [(NSString *)URLString length] == 0) {
            NSLog(@"无效的通知URL: %@", URLString);
            return nil;
        }
        
        callToActionURL = [NSURL URLWithString:(NSString *)URLString];
        if (callToActionURL == nil) {
            NSLog(@"无效的通知URL: %@", URLString);
            return nil;
        }
    }
    
    NSURL *imageURL = nil;
    NSString *imageURLString = object[@"image_url"];
    if (imageURLString != nil && ![imageURLString isKindOfClass:[NSNull class]]) {
        if (![imageURLString isKindOfClass:[NSString class]]) {
            NSLog(@"无效的图片URL: %@", imageURLString);
            return nil;
        }
        
        NSString *escapedUrl = [imageURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        imageURL = [NSURL URLWithString:escapedUrl];
        if (imageURL == nil) {
            NSLog(@"无效的图片URL: %@", imageURLString);
            return nil;
        }
        
        NSString *imagePath = imageURL.path;
        if ([type isEqualToString:ZGNotificationTypeTakeover]) {
            NSString *imageName = [imagePath stringByDeletingPathExtension];
            NSString *extension = [imagePath pathExtension];
            // TODO
            //imagePath = [[imageName stringByAppendingString:@"@2x"] stringByAppendingPathExtension:extension];
            imagePath = [[imageName stringByAppendingString:@""] stringByAppendingPathExtension:extension];
        }
        
        imagePath = [imagePath stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];
        imageURL = [[NSURL alloc] initWithScheme:imageURL.scheme host:imageURL.host path:imagePath];
        
        if (imageURL == nil) {
            NSLog(@"无效的图片URL: %@", imageURLString);
            return nil;
        }
    }
    
    NSArray *supportedOrientations = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
    if (![supportedOrientations containsObject:@"UIInterfaceOrientationPortrait"] && [type isEqualToString:@"takeover"]) {
        NSLog(@"弹窗通知不支持横屏应用");
        return nil;
    }
    
    return [[ZGNotification alloc] initWithID:[ID unsignedIntegerValue]
                                    messageID:[messageID unsignedIntegerValue]
                                         type:type
                                        title:title
                                         body:body
                                 callToAction:callToAction
                              callToActionURL:callToActionURL
                                     imageURL:imageURL];
}

- (id)initWithID:(NSUInteger)ID messageID:(NSUInteger)messageID type:(NSString *)type title:(NSString *)title body:(NSString *)body callToAction:(NSString *)callToAction callToActionURL:(NSURL *)callToActionURL imageURL:(NSURL *)imageURL {
    if (self = [super init]) {
        BOOL valid = YES;
        
        if (!(title && title.length > 0)) {
            valid = NO;
            NSLog(@"通知标题为空: %@", title);
        }
        
        if (!(body && body.length > 0)) {
            valid = NO;
            NSLog(@"通知内容为空: %@", body);
        }
        
        if (!([type isEqualToString:ZGNotificationTypeTakeover] || [type isEqualToString:ZGNotificationTypeMini])) {
            valid = NO;
            NSLog(@"无效的通知类型: %@, 现在支持类型 %@ 或 %@", type, ZGNotificationTypeMini, ZGNotificationTypeTakeover);
        }
        
        if (valid) {
            _ID = ID;
            _messageID = messageID;
            self.type = type;
            self.title = title;
            self.body = body;
            self.imageURL = imageURL;
            self.callToAction = callToAction;
            self.callToActionURL = callToActionURL;
            self.image = nil;
        } else {
            self = nil;
        }
    }
    
    return self;
}

- (NSData *)image {
    if (_image == nil && _imageURL != nil) {
        NSError *error = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:_imageURL options:NSDataReadingMappedIfSafe error:&error];
        if (error || !imageData) {
            NSLog(@"图片URL下载失败: %@", _imageURL);
            return nil;
        }
        _image = imageData;
    }
    return _image;
}

@end
