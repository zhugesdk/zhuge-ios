//
//  ZhugeBase64.h
//  HelloZhuge
//
//  Created by 郭超 on 2017/11/22.
//  Copyright © 2017年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (ZhugeBase64)

+ (NSData *)zgDataWithBase64EncodedString:(NSString *)string;
- (NSString *)zgBase64EncodedStringWithWrapWidth:(NSUInteger)wrapWidth;
- (NSString *)zgBase64EncodedString;

@end


@interface NSString (ZhugeBase64)

+ (NSString *)zgStringWithBase64EncodedString:(NSString *)string;
- (NSString *)zgBase64EncodedStringWithWrapWidth:(NSUInteger)wrapWidth;
- (NSString *)zgBase64EncodedString;
- (NSString *)zgBase64DecodedString;
- (NSData *)zgBase64DecodedData;

@end

