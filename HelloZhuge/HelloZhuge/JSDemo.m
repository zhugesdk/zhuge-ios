//
//  JSDemo.m
//  HelloZhuge
//
//  Created by jiaokang on 2016/10/14.
//  Copyright © 2016年 37degree. All rights reserved.
//

#import "JSDemo.h"

@implementation JSDemo

//一下方法都是只是打了个log 等会看log 以及参数能对上就说明js调用了此处的iOS 原生方法
-(void)testNoParameter{
    
    NSLog(@"this is ios TestNOParameter");
}
-(void)TestOneParameter:(NSString *)mes{
    
    NSLog(@"this is ios TestOneParameter=%@",mes);
}
-(void)TestTwoParameter:(NSString *)mes1 SecoundMess:(NSString *)mes2{
    
    NSLog(@"this is ios TestTowParameter=%@  Second=%@",mes1,mes2);
    NSLog(@"dsadasdsaad");
}
-(NSString *)one:(NSString *)mes Two:(NSString *)mess Three:(NSString *)thre{
    
    NSLog(@"this is three param %@, %@, %@",mes,mess,thre);
    NSData *data = [thre dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSLog(@"json is %@, %@",json,NSStringFromClass([json class]));
    return @"hello";
}
@end
