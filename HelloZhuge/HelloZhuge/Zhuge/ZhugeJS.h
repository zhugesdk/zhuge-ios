//
//  ZhugeJS.h
//  HelloZhuge
//
//  Created by jiaokang on 2016/10/18.
//  Copyright © 2016年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
@protocol ZhugeJSPro <JSExport,WKScriptMessageHandler>
@property (nonatomic) NSString *did;
-(void)track:(NSString *)eventName Property:(NSString *)pro;
-(void)identify:(NSString *)uid Property:(NSString *)pro;
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;
@end
/** 
 
*/
@interface ZhugeJS : NSObject<ZhugeJSPro>
- (NSString *)did;
@end
