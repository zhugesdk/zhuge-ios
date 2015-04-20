# IOS SDK 集成指南

## 安装SDK
最简单的安装方式是使用[CocoaPods](http://cocoapods.org/)  
 1. 安装CocoaPod `gem install cocoapods`  
 2. 项目目录下创建`Podfile`文件，并加入一行代码: `pod 'Zhuge'`  
 3. 项目目录下执行`pod install`，CocoaPods会自动安装Zhuge SDK，并生成工作区文件*.xcworkspace，打开该工作区即可。

你也可以直接下载来安装：  
 1. 下载[SDK](https://github.com/zhugesdk/zhuge-ios)：  
 2. 把`Zhuge`目录拖拽到项目中  
 3. 安装所有依赖： 
    `UIKit`、`Foundation`、`SystemConfiguration`、`CoreTelephony`、`'Accelerate`、`CoreGraphics`、`QuartzCore`

## 兼容性和ARC
 1. 诸葛SDK仅支持iOS 6.0以上系统，您需要使用Xcode 5和IOS 7.0及以上开发环境进行编译，如果您的版本较低，强烈建议升级。  
 2. 诸葛SDK默认采用ARC，如果您的项目没有采用ARC，您需要在编译(`Build Phases -> Compile Sources`)时，为每个Zhuge文件标识为`-fobj-arc`。

## 诸葛用户追踪ID方案
 1. 诸葛首选采用IDFA作为用户追踪的ID，这需要您的应用安装`AdSupport`依赖包。
 2. 如果您的应用中没有广告，采用IDFA可能会审核被拒，请在编译时加入`ZHUGE_NO_ADID`标志，诸葛将会采用IDFV作为追踪的ID。  
   xcode设置方法:  
   ```
	Build Settings > Apple LLVM 6.0 - Preprocessing > Processor Macros > Release : ZHUGE_NO_ADID=1
	```

 3. 我们鼓励调用identify方法加入自己的用户ID，这样可以把因版本升级等生成的多个ID合并到您自己统一的用户ID下。
 

## 初始化
在集成诸葛SDk时，您首先需要用AppKey启动。Appkey是在官网上创建项目时生成。

```
#import "Zhuge/Zhuge.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[Zhuge sharedInstance] startWithAppKey:@"Your App Key" launchOptions:launchOptions];
}
```

如果您需要修改SDK的默认设置，如打开日志打印、设置版本渠道等时，一定要在`startWithAppKey`前执行。参考代码：

```
    Zhuge *zhuge = [Zhuge sharedInstance];

    // 打开SDK日志打印
    [zhuge.config setLogEnabled:YES]; // 默认关闭
    
    // 自定义应用版本
    [zhuge.config setAppVersion:@"0.9-beta"]; // 默认是info.plist中CFBundleShortVersionString值
    
    // 自定义渠道
    [zhuge.config setChannel:@"My App Store"]; // 默认是@"App Store"

    // 开启行为追踪
    [zhuge startWithAppKey:@"Your App Key" launchOptions:launchOptions];

```

## 识别用户身份
您可以通过调用`identify:properties:`来记录用户身份信息。

```
    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    user[@"name"] = @"zhuge";
    user[@"gender"] = @"男";
    user[@"birthday"] = @"2014/11/11";
    user[@"avatar"] = @"http://tp2.sinaimg.cn/2885710157/180/5637236139/1";
    user[@"email"] = @"hello@zhuge.io";
    user[@"mobile"] = @"18901010101";
    user[@"qq"] = @"91919";
    user[@"weixin"] = @"121212";
    user[@"weibo"] = @"122222";
    user[@"location"] = @"北京朝阳区";
    user[@"公司"] = @"37degree";
    [[Zhuge sharedInstance] identify:@"1234" properties:user];
```
##### 预定义的属性：

为了便于分析和页面显示，我们抽取了一些共同的属性，要统计以下数据时，可按照下面格式填写。 

|属性Key     | 说明        | 
|--------|-------------|
|name    | 名称|
|gender  | 性别(值:男,女)|
|birthday| 生日(格式: yyyy/MM/dd)|
|avatar   | 头像地址|
|email   | 邮箱|
|mobile   | 手机号|
|qq      | QQ账号|
|weixin  | 微信账号|
|weibo   | 微博账号|
|location   | 地域，如北京|

**长度限制**:Key最长支持25个字符，Value最长支持255个字符，一个汉字按3个字符计算。

## 自定义事件
您可以通过调用`track:properties:`来跟踪自定义事件。

```
    [[Zhuge sharedInstance] track:@"购物" properties: @{@"商家":@"京东"}];
```

## 推送通知

在startWithAppKey调用之前，指定开发环境或生产环境，同时注册APNS推送功能。

```
// 推送指定deviceToken上传到开发环境或生产环境，默认NO，上传到开发环境
// 发布到Ad Hoc环境或App Store时，请指定为YES
[zhuge.config setApsProduction:NO];

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        [zhuge registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                       UIUserNotificationTypeSound |
                                                       UIUserNotificationTypeAlert)
                                           categories:nil];
    } else {
        [zhuge registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                       UIRemoteNotificationTypeSound |
                                                       UIRemoteNotificationTypeAlert)
                                           categories:nil];
    }
#else
        [zhuge registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                       UIRemoteNotificationTypeSound |
                                                       UIRemoteNotificationTypeAlert)
                                           categories:nil];
#endif
zhuge
```

提交APNS注册后返回的deviceToken

```
-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[Zhuge sharedInstance] registerDeviceToken:deviceToken];
}

```

处理推送通知

```
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[Zhuge sharedInstance] handleRemoteNotification:userInfo];
}
```

## 第三方推送
诸葛同时支持第三方推送，如果您正在使用第三方推送，请在startWithAppKey调用之后设置第三方推送的用户ID

```
[zhuge setThirdPartyPushUserId:@"第三方推送的用户ID" forChannel:ZG_PUSH_CHANNEL_GETUI];
```




