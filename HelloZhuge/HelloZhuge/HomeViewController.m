//
//  HomeViewController.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "HomeViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "ZhugeJS.h"
//#import "JSDemo.h"
@interface HomeViewController ()<UIWebViewDelegate>
@property (nonatomic, strong) JSContext *jsContext;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect frame = CGRectMake(10, 100, self.view.bounds.size.width, self.view.bounds.size.height);
    UIWebView *webView =[[UIWebView alloc]initWithFrame:frame];
    
    [webView setDelegate:self];
//    NSString *path = [[NSBundle mainBundle]pathForResource:@"JsDemo" ofType:@"html"];
//    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self.view addSubview:webView];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"JsDemo" withExtension:@"html"];

    [webView loadRequest:[[NSURLRequest alloc] initWithURL:url]];

    
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{

    NSLog(@"didFinish");
    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.jsContext[@"zhugeTracker"] = [[ZhugeJS alloc] init];
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
    };
}
#pragma mark - JSObjcDelegate

- (void)callCamera {
    NSLog(@"callCamera");
    // 获取到照片之后在回调js的方法picCallback把图片传出去
    JSValue *picCallback = self.jsContext[@"picCallback"];
    [picCallback callWithArguments:@[@"photos"]];
}

- (void)share:(NSString *)shareString {
    NSLog(@"share:%@", shareString);
    // 分享成功回调js的方法shareCallback
    JSValue *shareCallback = self.jsContext[@"shareCallback"];
    [shareCallback callWithArguments:nil];
}
@end
