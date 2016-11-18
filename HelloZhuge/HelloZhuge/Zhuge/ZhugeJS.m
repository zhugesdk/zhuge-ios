//
//  ZhugeJS.m
//  HelloZhuge
//
//  Created by jiaokang on 2016/10/18.
//  Copyright © 2016年 37degree. All rights reserved.
//

#import "ZhugeJS.h"
#import "Zhuge.h"

@implementation ZhugeJS

-(void)track:(NSString *)eventName Property:(NSString *)pro{

    Zhuge *zhuge = [Zhuge sharedInstance];
    NSData *data = [pro dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSLog(@"track name is %@,pro is %@",eventName,json);
    [zhuge track:eventName properties:json];

}

-(void)identify:(NSString *)uid Properties:(NSString *)pro{
    
    Zhuge *zhuge = [Zhuge sharedInstance];
    NSData *data = [pro dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSLog(@"identify name is %@,pro is %@",uid,json);

    [zhuge identify:uid properties:json];
}
@end
