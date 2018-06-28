//
//  ZhugeExceptionHandler.h
//  HelloZhuge
//
//  Created by jiaokang on 2018/6/27.
//  Copyright © 2018年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZhugeExceptionHandler : NSObject
// 崩溃日志

+ (void)setDefaultHandler;
+ (NSUncaughtExceptionHandler *)getHandler;
+ (void)TakeException:(NSException *) exception;
@end
