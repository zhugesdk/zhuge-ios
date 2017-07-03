//
//  JSDemo.h
//  HelloZhuge
//
//  Created by jiaokang on 2016/10/14.
//  Copyright © 2016年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol JSObjectPro <JSExport>

-(void)testNoParameter;
-(void)TestOneParameter:(NSString *)mes;
-(void)TestTwoParameter:(NSString *)mes1 SecoundMess:(NSString *)mes2;
-(NSString *)one:(NSString *)mes Two:(NSString *)mess Three:(NSString *)thre;
@end

@interface JSDemo : NSObject<JSObjectPro>

@end
