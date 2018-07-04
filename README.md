---
诸葛3.0-iOS集成开发指南
---

##1. 安装SDK
最简单的安装方式是使用[CocoaPods](http://cocoapods.org/)  
 1. 安装CocoaPod `gem install cocoapods`  
 2. 项目目录下创建`Podfile`文件，并加入一行代码: `pod 'Zhugeio'`  
 3. 项目目录下执行`pod install`，CocoaPods会自动安装Zhuge SDK，并生成工作区文件*.xcworkspace，打开该工作区即可。

你也可以直接下载来安装：  
 1. 下载[SDK](http://sdk.zhugeio.com/Zhuge_iOS_SDK.zip)：  
 2. 把`Zhugeio`目录拖拽到项目中  
 3. 安装所有依赖： 
    `UIKit`、`Foundation`、`libz.tbd`

##2. 兼容性和ARC
 1. 诸葛SDK仅支持iOS 7.0以上系统，您需要使用Xcode 5和IOS 7.0及以上开发环境进行编译，如果您的版本较低，强烈建议升级。  
 2. 诸葛SDK默认采用ARC，如果您的项目没有采用ARC，您需要在编译(`Build Phases -> Compile Sources`)时，为每个Zhuge文件标识为`-fobj-arc`。

##3. 诸葛用户追踪ID方案
 1. 诸葛首选采用IDFA作为用户追踪的ID，这需要您的应用安装`AdSupport`依赖包。
 2. 如果您的应用中没有广告，采用IDFA可能会审核被拒，请在编译时加入`ZHUGE_NO_ADID`标志，诸葛将会采用IDFV作为追踪的ID。  
   XCode设置方法:  
   ```
	Build Settings > Apple LLVM 6.0 - Preprocessing > Processor Macros > Release : ZHUGE_NO_ADID=1
	```
 3. 如果您想自己控制用户追踪ID，可以在初始化时传入did作为诸葛用户追踪的ID，此did将作为设备的ID进行统计。

     ```
     [zhuge startWithAppKey :@"Your App Key"  andDid:@"did" launchOptions:launchOptions];
     ```

 

##4. 初始化
用你的应用的AppKey启动诸葛io SDK。

```
#import "Zhuge/Zhuge.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[Zhuge sharedInstance] startWithAppKey:@"Your App Key" launchOptions:launchOptions];
}
```


如果您需要修改SDK的默认设置，如设置版本渠道时，一定要在`startWithAppKey`前执行。参考代码：

```
    Zhuge *zhuge = [Zhuge sharedInstance];

    // 实时调试开关
    // 设置为YES，可在诸葛io的「实时调试」页面实时观察事件数据上传
    // 建议仅在需要时打开，调试完成后，请及时关闭
    [zhuge.config setDebug : NO];

	 [zhuge.config setExceptionTrack:YES]; //开启崩溃统计
    
    // 自定义应用版本
    [zhuge.config setAppVersion:@"0.9-beta"]; // 默认是info.plist中CFBundleShortVersionString值
    
    // 自定义渠道
    [zhuge.config setChannel:@"My App Store"]; // 默认是@"App Store"

    // 开启行为追踪
    [zhuge startWithAppKey:@"Your App Key" launchOptions:launchOptions];

```

### 4.1 崩溃统计

崩溃统计功能默认关闭，要开启崩溃统计，请在初始化之前开启。

```
    Zhuge *zhuge = [Zhuge sharedInstance];
	[zhuge.config setExceptionTrack:YES]; //开启崩溃统计
    [zhuge startWithAppKey:@"Your App Key" launchOptions:launchOptions];

```

如果您自己有设置```UncaughtExceptionHandler```,那么请在启动诸葛之前，设置自己的```handler```。

```
    NSSetUncaughtExceptionHandler(&SelfUncaughtExceptionHandler);
	Zhuge *zhuge = [Zhuge sharedInstance];
	[zhuge.config setExceptionTrack:YES]; //开启崩溃统计
    [zhuge startWithAppKey:@"Your App Key" launchOptions:launchOptions];

```

##5. 识别用户
为了保持对用户的跟踪，你需要为每一位用户记录一个唯一的ID，你可以使用用户id、email等唯一值来作为用户在诸葛io的ID。 另外，你可以在跟踪用户的时候， 记录用户更多的属性信息，便于你更了解你的用户：

```
    //定义诸葛io中的用户ID
    NSString *userId = [user getUserId]
    
    //定义属性
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"name"] = @"zhuge";
    userInfo[@"gender"] = @"男";
    userInfo[@"birthday"] = @"2014/11/11";
    userInfo[@"avatar"] = @"http://tp2.sinaimg.cn/2885710157/180/5637236139/1";
    userInfo[@"email"] = @"hello@zhuge.io";
    userInfo[@"mobile"] = @"18901010101";
    userInfo[@"qq"] = @"91919";
    userInfo[@"weixin"] = @"121212";
    userInfo[@"weibo"] = @"122222";
    userInfo[@"location"] = @"北京朝阳区";
    userInfo[@"公司"] = @"37degree";
    [[Zhuge sharedInstance] identify:userId properties:userInfo];
```

**长度限制**:Key最长支持25个字符，Value最长支持255个字符，一个汉字按3个字符计算。

##6. 自定义事件
你可以在`startWithAppKey `之后开始记录事件（用户行为），并可记录与该事件相关的属性信息

```
    //定义与事件相关的属性信息  
	NSMutableDictionary *properties = [NSMutableDictionary dictionary];  
	properties[@"视频名称"] = @"冰与火之歌";
	properties[@"分类"] = @"奇幻";
	properties[@"时间"] = @"5:10pm";
	properties[@"来源"] = @"首页"; 
	//记录事件
	[[Zhuge sharedInstance] track:@"观看视频" properties: 	properties];   
```

## 7.时长事件的统计

若您希望统计一个事件发生的时长，比如视频的播放，页面的停留，那么可以调用如下接口来进行：

```
Zhuge *zhuge = [Zhuge sharedInstance];
NSString *eventName = @"";
[zhuge startTrack:eventName];
```
说明：调用`startTrack`来开始一个事件的统计，eventName为一个事件的名称

```
Zhuge *zhuge = [Zhuge sharedInstance];
NSString *eventName = @"";
NSDictionary *pro = [NSDictionary dictionary];
[zhuge endTrack:eventName properties:pro];
```

说明：调用`endTrack`来记录事件的持续时长。调用`endTrack`之前，相同eventName的事件必须已经调用过`startTrack`，否则这个接口不会产生任何事件。


代码示例：

```
Zhuge *zhuge = [Zhuge sharedInstance];
NSString *eventName = @"观看视频";

//视频播放开始
[zhuge startTrack:eventName];
...
//视频观看结束
NSDictionary *pro = [NSDictionary dictionary];
pro[@"名称"] = @"非诚勿扰";
pro[@"期数"] = @"2016-11-02";
[zhuge endTrack:eventName properties:pro];
```
***注意：***startTrack与endTrack必须成对出现（eventName一致），单独调用一个接口是无效的。

## 8.在UIWebView中进行统计

如果你的页面中使用了**UIWebView**嵌入HTML,js 的代码，并且希望统计HTML中的事件，那么可以通过下面的文档来进行跨平台的统计。注意如果你的HTML是运行在浏览器的，那么还是无法统计的，下文仅针对使用**UIWebView**加载网页的情况。

* Objective C代码集成

  首先要找到您的UIWevView的UIWebViewDelegate对象，并在`webViewDidFinishLoad `时做如下处理:
  
  ```java 
  
	#import <JavaScriptCore/JavaScriptCore.h>
	#import "ZhugeJS.h"
	
	
	-(void)webViewDidFinishLoad:(UIWebView *)webView{

    JSContext *jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    jsContext[@"zhugeTracker"] = [[ZhugeJS alloc] init];
    jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
    };
}

  ```
  
* js代码统计

  集成了Object C代码之后，您就可以在js代码中进行统计。具体统计方式请参照JS集成文档。
##9. 在WKWebView中进行统计
如果你的页面中使用了**WKWebView**嵌入HTML,js 的代码，并且希望统计HTML中的事件，那么可以通过下面的文档来进行跨平台的统计。注意如果你的HTML是运行在浏览器的，那么还是无法统计的，下文仅针对使用**WKWebView**加载网页的情况。

* Objective C代码集成

	在你的WKWebView对象初始化时，为其配置一个**WKWebViewConfiguration**对象，对象的具体配置如下：
	
	
	```
	#import "ZhugeJS.h"
	····
	//初始化一个WKWebViewConfiguration
	WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
	//初始化一个WKUserContentController
    WKUserContentController* userContent = [[WKUserContentController alloc] init];
    //给WKUserContentController设置一个js脚本控制器
    [userContent addScriptMessageHandler:[[ZhugeJS alloc]init] name:@"zhugeTracker"];
    //将配置过脚本控制器的WKUserContentController设置给WKWebViewConfiguration
    config.userContentController = userContent;
    //使用配置好的WKWebViewConfiguration，创建WKWebView
    self.webView =[[WKWebView alloc]initWithFrame:frame configuration:config];
	```

* JS代码集成

	Native端配置好之后，即可在html页面中通过js进行移动端的打点，具体统计方式请参照JS集成文档。


##10. 设置自定义属性

* 事件自定义属性

```
 [Zhuge setSuperProperty:(NSDictionary *) pro];
```
若有一些属性对于您来说，每一个事件都要拥有，那么您可以调用``setSuperProperty ``将它传入。之后，每一个经过`track`,`endTrack`传入的事件，都将自动获得这些属性。

* 设备自定义属性

```
[Zhuge setPlatform:(NSDictionary *) pro];
```

诸葛默认展示的设备信息包含一些硬件信息，如系统版本，设备分辨率，设备制造商等。若您希望在展示设备信息时展示一些额外的信息，那么可以调用``setPlatform``传入，我们会将这些信息添加在设备信息中。

  
  


##11. 其他可选API

*  `[[Zhuge sharedInstance] getDid]`  您可以通过这个接口来获取当前设备在诸葛体系下的设备标识

* `[[Zhuge sharedInstance] getSid]`  您可以通过这个接口来获得当前应用所属的会话ID

    
* 实时调试

	你可以使用诸葛io提供的**实时调试**功能来查看实时布点数据，并确认是否准确

使用方法：
	
在诸葛统计初始化之前，调用如下代码，以开启实时调试（注意：建议仅在测试设备上开启）：

``` Java
[[Zhuge sharedInstance] setDebug:YES]
```

  然后在诸葛io中打开**实时调试**页面，即可实时查看上传的数据.

### 日志输出

要在xcode控制台查看诸葛io SDK输入的日志，请在最新版的xcode中设置：

`Build Settings > Apple LLVM 7.0 - Preprocessing > Preprocessor Macros > Debug : ZHUGE_LOG=1`

