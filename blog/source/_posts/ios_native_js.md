---
title: iOS 与 JS 交互开发知识总结
comments: true
date: 2017-10-23 11:21:16
updated: 2017-10-23 11:21:16
tags: 
- hybrid
- jsbridge
categories: 
- ios
---

{% asset_img hybrid.jpg %}

## 前言

Web 页面中的 JS 与 iOS Native 如何交互是每个 iOS 猿必须掌握的技能。而说到 Native 与 JS 交互，就不得不提一嘴 Hybrid。

Hybrid 的翻译结果并不是很文明（擦汗，不知道为啥很多翻译软件会译为“杂种”，但我更喜欢将它翻译为“混合、混血”），Hybrid Mobile App 我对它的理解为通过 Web 网络技术（如 HTML，CSS 和 JavaScript）与 Native 相结合的混合移动应用程序。

那么我们来看一下 Hybrid 对比 Native 有哪些优劣：

{% asset_img hybrid_vs_native.jpg %}

因为 Hybrid 的灵活性（更改 Web 页面不必重新发版）以及通用性（一份 H5 玩遍所有平台）再加上门槛低（前端猿可以无痛上手开撸）的优势，所以在非核心功能模块使用 Web 通过 Hybrid 的方式来实现可能从各方面都会优于 Native。而 Native 则可以在核心功能和设备硬件的调用上为 JS 提供强有力的支持。

## 索引

- Hybrid 的发展简史
- JavaScriptCore 简介
- iOS Native 与 JS 交互的方法
- WKWebView 与 JS 交互的特有方法
- JS 通过 Native 调用 iOS 设备摄像头的 Demo
- 总结

## Hybrid 的发展简史

下面简述一下 Hybrid 的发展史：

### 1.H5 发布

{% asset_img html5.png %}

Html5 是在 2014 年 9 月份正式发布的，这一次的发布做了一个最大的改变就是“从以前的 XML 子集升级成为一个独立集合”。

### 2.H5 渗入 Mobile App 开发

Native APP 开发中有一个 webview 的组件（Android 中是 webview，iOS 有 UIWebview和 WKWebview），这个组件可以加载 Html 文件。

在 H5 大行其道之前，webview 加载的 web 页面很单调（因为只能加载一些静态资源），自从 H5 火了之后，前端猿们开发的 H5 页面在 webview 中的表现不俗使得 H5 开发慢慢渗透到了 Mobile App 开发中来。

### 3.Hybrid 现状

虽然目前已经出现了 RN 和 Weex 这些使用 JS 写 Native App 的技术，但是 Hybrid 仍然没有被淘汰，市面上大多数应用都不同程度的引入了 Web 页面。

## JavaScriptCore

JavaScriptCore 这个库是 Apple 在 iOS 7 之后加入到标准库的，它对 iOS Native 与 JS 做交互调用产生了划时代的影响。

JavaScriptCore 大体是由 4 个类以及 1 个协议组成的：

{% asset_img javascriptcore_framework.jpg %}

- JSContext 是 JS 执行上下文，你可以把它理解为 JS 运行的环境。
- JSValue 是对 JavaScript 值的引用，任何 JS 中的值都可以被包装为一个 JSValue。
- JSManagedValue 是对 JSValue 的包装，加入了“conditional retain”。
- JSVirtualMachine 表示 JavaScript 执行的独立环境。

还有 JSExport 协议：
> 实现将 Objective-C 类及其实例方法，类方法和属性导出为 JavaScript 代码的协议。

这里的 JSContext，JSValue，JSManagedValue 相对比较好理解，下面我们把 JSVirtualMachine 单拎出来说明一下：

### JSVirtualMachine 的用法和其与 JSContext 的关系

{% asset_img jsvirtualmachine.jpg %}

官方文档的介绍：

> JSVirtualMachine 实例表示用于 JavaScript 执行的独立环境。 您使用此类有两个主要目的：支持并发 JavaScript 执行，并管理 JavaScript 和 Objective-C 或 Swift 之间桥接的对象的内存。

关于 JSVirtualMachine 的使用，一般情况下我们不用手动去创建 JSVirtualMachine。因为当我们获取 JSContext 时，获取到的 JSContext 从属于一个 JSVirtualMachine。

每个 JavaScript 上下文（JSContext 对象）都属于一个 JSVirtualMachine。 每个 JSVirtualMachine 可以包含多个上下文，允许在上下文之间传递值（JSValue 对象）。 但是，每个 JSVirtualMachine 是不同的，即我们不能将一个 JSVirtualMachine 中创建的值传递到另一个 JSVirtualMachine 中的上下文。

JavaScriptCore API 是线程安全的 —— 例如，我们可以从任何线程创建 JSValue 对象或运行 JS 脚本 - 但是，尝试使用相同 JSVirtualMachine 的所有其他线程将被阻塞。 要在多个线程上同时（并发）运行 JavaScript 脚本，请为每个线程使用单独的 JSVirtualMachine 实例。

### JSValue 与 JavaScript 的转换表

| OBJECTIVE-C | JAVASCRIPT | JSVALUE CONVERT | JSVALUE CONSTRUCTOR |
| --- | --- | --- | --- |
| nil | undefined |  | valueWithUndefinedInContext |
| NSNull | null |  | valueWithNullInContext: |
| NSString | string | toString |  |
| NSNumber | number, boolean | toNumber<br />toBool<br />toDouble<br />toInt32<br />toUInt32 | valueWithBool:inContext:<br />valueWithDouble:inContext:<br />valueWithInt32:inContext:<br />valueWithUInt32:inContext: |
| NSDictionary | Object object | toDictionary | valueWithNewObjectInContext: |
| NSArray | Array object | toArray | valueWithNewArrayInContext: |
| NSDate | Date object | toDate |  |
| NSBlock | Function object |  |  |
| id | Wrapper object | toObject<br />toObjectOfClass: | valueWithObject:inContext: |
| Class | Constructor object |  |  |

## iOS Native 与 JS 交互

对于 iOS Native 与 JS 交互我们先从调用方向上分为两种情况来看：

- JS 调用 Native
- Native 调用 JS

{% asset_img call_eachother.jpg %}

### JS 调用 Native

其实 JS 调用 iOS Native 也分为两种实现方式：

- 假 Request 方法
- JavaScriptCore 方法

#### 假 Request 方法

原理：其实这种方式就是利用了 webview 的代理方法，在 webview 开始请求的时候截获请求，判断请求是否为约定好的假请求。如果是假请求则表示是 JS 想要按照约定调用我们的 Native 方法，按照约定去执行我们的 Native 代码就好。

##### UIWebView

UIWebView 代理有用于截获请求的函数，在里面做判断就好：

``` obj-c
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    // 与约定好的函数名作比较
    if ([[url scheme] isEqualToString:@"your_func_name"]) {
        // just do it
    }
}
```
##### WKWebView

WKWebView 有两个代理，一个是 WKNavigationDelegate，另一个是 WKUIDelegate。WKUIDelegate 我们在下面的章节会讲到，这里我们需要设置并实现它的 WKNavigationDelegate 方法：

``` obj-c
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    // 与约定好的函数名作比较
    if ([[url scheme] isEqualToString:@"your_func_name"]) {
        // just do it
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}
```

> Note: `decisionHandler` 是当你的应用程序决定是允许还是取消导航时，要调用的代码块。 该代码块使用单个参数，它必须是枚举类型 `WKNavigationActionPolicy` 的常量之一。如果不调用 `decisionHandler` 会引起 crash。

这里补充一下 JS 代码：

``` js
function callNative() {
    loadURL("your_func_name://xxx");
}   
```
然后拿个 button 标签用一下就好了：
```
<button type="button" onclick="callNative()">Call Native!</button>
```

#### JavaScriptCore 方法

iOS 7 有了 JavaScriptCore 专门用来做 Native 与 JS 的交互。我们可以在 webview 完成加载之后获取 JSContext，然后利用 JSContext 将 JS 中的对象引用过来用 Native 代码对其作出解释或响应：

``` obj-c
// 首先引入 JavaScriptCore 库
#import <JavaScriptCore/JavaScriptCore.h>

// 然后再 UIWebView 的完成加载的代理方法中
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // 获取 JS 上下文
    jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    // 做引用，将 JS 内的元素引用过来解释，比如方法可以解释成 Block，对象也可以指向 OC 的 Native 对象哦
    jsContext[@"iosDelegate"] = self;
    jsContext[@"yourFuncName"] = ^(id parameter){
        // 注意这里的线程默认是 web 处理的线程，如果涉及主线程操作需要手动转到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
        // your code
        });
    }
}
```

而 JS 这边代码更简单了，干脆声明一个不解释的函数（约定好名字的），用于给 Native 做引用：

``` js
var parameter = xxx;
yourFuncName(parameter);
```

### iOS Native 调用 JS

iOS Native 调用 JS 的实现方法也被 JavaScriptCore 划分开来：

- webview 直接注入 JS 并执行
- JavaScriptCore 方法

#### webview 直接注入 JS 并执行

在 iOS 平台，webview 有注入并执行 JS 的 API。

##### UIWebView

UIWebView 有直接注入 JS 的方法：

``` obj-c
NSString *jsStr = [NSString stringWithFormat:@"showAlert('%@')", @"alert msg"];
[_webView stringByEvaluatingJavaScriptFromString:jsStr];
```
> Note: 这个方法会返回运行 JS 的结果（`nullable NSString *`），它是一个同步方法，会阻塞当前线程！尽管此方法不被弃用，但最佳做法是使用 `WKWebView` 类的 `evaluateJavaScript：completionHandler：method`。
>
> 官方文档：
> The stringByEvaluatingJavaScriptFromString: method waits synchronously for JavaScript evaluation to complete. If you load web content whose JavaScript code you have not vetted, invoking this method could hang your app. Best practice is to adopt the WKWebView class and use its evaluateJavaScript:completionHandler: method instead.

##### WKWebView

不同于 UIWebView，WKWebView 注入并执行 JS 的方法不会阻塞当前线程。因为考虑到 webview 加载的 web content 内 JS 代码不一定经过验证，如果阻塞线程可能会挂起 App。

``` obj-c
NSString *jsStr = [NSString stringWithFormat:@"setLocation('%@')", @"北京市东城区南锣鼓巷纳福胡同xx号"];
[_webview evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
    NSLog(@"%@----%@", result, error);
}];
```
> Note: 方法不会阻塞线程，而且它的回调代码块总是在主线程中运行。
> 
> 官方文档：
> Evaluates a JavaScript string.
The method sends the result of the script evaluation (or an error) to the completion handler. The completion handler always runs on the main thread.

#### JavaScriptCore 方法

上面简单提到过 JavaScriptCore 库提供的 JSValue 类，这里再提供一下官方文档对 JSValue 的介绍翻译：

> JSValue 实例是对 JavaScript 值的引用。 您可以使用 JSValue 类来转换 JavaScript 和 Objective-C 或 Swift 之间的基本值（如数字和字符串），以便在本机代码和 JavaScript 代码之间传递数据。

不过你也看到了我贴在上面的 OC 和 JS 数据类型转换表，那里面根本没有限定为官方文档所说的基本值。如果你不熟悉 JS 的话，我这里解释一下为什么 JSValue 也可以指向 JS 中的对象和函数，因为 JS 语言不区分基本值和对象以及函数，在 JS 中“万物皆为对象”。

好了下面直接 show code：

``` obj-c
// 首先引入 JavaScriptCore 库
#import <JavaScriptCore/JavaScriptCore.h>

// 先获取 JS 上下文
self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
// 如果涉及 UI 操作，切回主线程调用 JS 代码中的 YourFuncName，通过数组@[parameter] 入参
dispatch_async(dispatch_get_main_queue(), ^{
    JSValue *jsValue = self.jsContext[@"YourFuncName"];
    [jsValue callWithArguments:@[parameter]];
});
```
上面的代码调用了 JS 代码中 YourFuncName 函数，并且给函数加了 @[parameter] 作为入参。为了方便阅读理解，这里再贴一下 JS 代码：

``` js
function YourFuncName(arguments){
    var result = arguments;
    // do what u want to do
}
```

## WKWebView 与 JS 交互的特有方法

{% asset_img wkwebview.jpg %}

关于 WKWebView 与 UIWebView 的区别就不在本文加以详细说明了，更多信息还请自行查阅。这里要讲的是 WKWebView 在与 JS 的交互时特有的方法：

- WKUIDelegate 方法
- MessageHandler 方法

### WKUIDelegate 方法

对于 WKWebView 上文提到过，除了 WKNavigationDelegate，它还有一个 WKUIDelegate，这个 WKUIDelegate 是做什么用的呢？ 

WKUIDelegate 协议包含一些函数用来监听 web JS 想要显示 alert 或 confirm 时触发。我们如果在 WKWebView 中加载一个 web 并且想要 web JS 的 alert 或 confirm 正常弹出，就需要实现对应的代理方法。

> Note: 如果没有实现对应的代理方法，则 webview 将会按照默认操作去做出行为。
> 
> - Alert: If you do not implement this method, the web view will behave as if the user selected the OK button.
> - Confirm: If you do not implement this method, the web view will behave as if the user selected the Cancel button.

我们这里就拿 alert 举例，相信各位读者可以自己举一反三。下面是在 WKUIDelegate 监听 web 要显示 alert 的代理方法中用 Native UIAlertController 替代 JS 中的 alert 显示的栗子 ：

``` obj-c
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    // 用 Native 的 UIAlertController 弹窗显示 JS 将要提示的信息
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提醒" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // 函数内必须调用 completionHandler
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}
```

### MessageHandler 方法

MessageHandler 是继 Native 截获 JS 假请求后另一种 JS 调用 Native 的方法，该方法利用了 WKWebView 的新特性实现。对比截获假 Request 的方法来说，MessageHandler 传参数更加简单方便。

#### MessageHandler 指什么？

WKUserContentController 类有一个方法:
``` obj-c
- (void)addScriptMessageHandler:(id <WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name;
```
该方法用来添加一个脚本处理器，可以在处理器内对 JS 脚本调用的方法做出处理，从而达到 JS 调用 Native 的目的。

那么 WKUserContentController 类和 WKWebView 有毛关系呢？

在 WKWebView 的初始化函数中有一个入参 configuration，它的类型是 WKWebViewConfiguration。WKWebViewConfiguration 中包含一个属性 userContentController，这个 userContentController 就是 WKUserContentController 类型的实例，我们可以用这个 userContentController 来添加不同名称的脚本处理器。

{% asset_img wkusercontentcontroller.jpg %}

##### MessageHandler 的坑

那么回到 `- (void)addScriptMessageHandler:name:` 方法上面，该方法添加一个脚本消息处理器（第一个入参 scriptMessageHandler），并且给这个处理器起一个名字（第二个入参 name）。不过这个函数在使用的时候有个坑：scriptMessageHandler 入参会被强引用，那么如果你把当前 WKWebView 所在的 UIViewController 作为第一个入参，这个 viewController 被他自己所持有的 `webview.configuration. userContentController` 所持有，就会造成循环引用。

{% asset_img retaincycle.jpg %}

我们可以通过 `- (void)removeScriptMessageHandlerForName:` 方法删掉 userContentController 对 viewController 的强引用。所以一般情况下我们的代码会在 `viewWillAppear` 和 `viewWillDisappear` 成对儿的添加和删除 MessageHandler：

``` obj-c
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webview.configuration.userContentController addScriptMessageHandler:self name:@"YourFuncName"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webview.configuration.userContentController removeScriptMessageHandlerForName:@"YourFuncName"];
}
```
##### WKScriptMessageHandler 协议

WKScriptMessageHandler 是脚本信息处理器协议，如果想让一个对象具有脚本信息处理能力（比如上文中 webview 的所属 viewController 也就是上面代码的 self）就必须使其遵循该协议。

WKScriptMessageHandler 协议内部非常简单，只有一个方法，我们必须要实现该方法（@required）：

``` obj-c
// WKScriptMessageHandler 协议方法，在接收到脚本信息时触发
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    // message 有两个属性：name 和 body
    // message.name 可以用于区别要做的处理
    if ([message.name isEqualToString:@"YourFuncName"]) {
        // message.body 相当于 JS 传递过来的参数
        NSLog(@"JS call native success %@", message.body);
    }
}
```

补充 JS 的代码：

``` js
// <name> 换 YourFuncName，<messageBody> 换你要的入参即可
window.webkit.messageHandlers.<name>.postMessage(<messageBody>)
```

搞定收工！

## JS 通过 Native 调用 iOS 设备摄像头的 Demo

徒手撸了一个 Demo，实现了 JS 与 Native 代码的交互，达到用 JS 在 webview 内调用 iOS 设备摄像头的功能。Demo 内含权限申请，用户拒绝授权等细节（技术上就是 JS 和 Native 相互传值调用），还请各位大佬指教。

向各位基佬低头，献上我的膝盖~[（Demo 地址）](https://github.com/Lision/HybridCameraDemo)

## 总结

- 这篇文章简单的介绍了一下 Hybrid Mobile App（其中还包括 Hybrid 的发展简史）。
- 介绍了 JavaScriptCore 的组成，并且把 JSVirtualMachine 与 JSContext 和 JSValue 之间的关系用图片的形式表述出来（JSVirtualMachine 包含 JSContext 包含 JSValue，都是 1 对 n 的关系，且由于同一个 JSVirtualMachine 下的代码会相互阻塞，所以如果想异步执行交互需要在不同的线程声明 JSVirtualMachine 并发执行）。
- 从调用方向的角度把 JS 与 iOS Native 相互调用的方式方法分别用代码示例讲解了一遍。
- 介绍了 WKWebView 与 JS 交互特有的方法：WKUIDelegate 和 MessageHandler。
- 提供了一个 JS 通过 Native 调用 iOS 设备摄像头的 Demo。

文章写得比较用心（是我个人的原创文章，转载请注明 [https://lision.me/](https://lision.me/)），如果发现错误会优先在我的 [个人博客](https://lision.me/) 中更新。如果有任何问题欢迎在我的微博 [@Lision](https://weibo.com/lisioncode) 联系我~

希望我的文章可以为你带来价值~