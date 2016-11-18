//
//  ZhugeJS.h
//  HelloZhuge
//
//  Created by jiaokang on 2016/10/18.
//  Copyright © 2016年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
@protocol ZhugeJSPro <JSExport>
-(void)track:(NSString *)eventName Property:(NSString *)pro;
-(void)identify:(NSString *)uid Properties:(NSString *)pro;
@end
/** 
 
*/
@interface ZhugeJS : NSObject<ZhugeJSPro>

@end
