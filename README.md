**快速开始**

1. 安装 [CocoaPods](http://cocoapods.org/) ，安装命令: `gem install cocoapods`.
2. 在项目目录下创建`Podfile`文件，文件内容为:

```ruby
pod 'Zhuge'
```

3. 在项目目录下执行`pod install`。  
   CocoaPods会自动下载Zhuge SDK，并创建一个Xcode工作区(workspace)。  
   使用命令`open {YOUR-PROJECT}.xcworkspace`打开工作区。

4. 向`AppDelegate.m`文件中添加初始化代码:

```objc
#import <Zhuge/Zhuge.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[Zhuge sharedInstance] startWithAppKey:@"Your App Key"];
}
```

5. 开始追踪用户行为:

```objc
[[Zhuge sharedInstance] track:@"分享" properties:@{@"渠道":@"微博"}];
```

**了解更多 [完整文档 »](http://docs.zhuge.io/sdks/ios)**
