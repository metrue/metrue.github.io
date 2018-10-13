---
title: 逆向 Mac 应用 Bartender
comments: true
date: 2018-10-01 20:45:48
updated: 2018-10-01 20:45:48
tags:
- re
- macOS
categories:
- reverse
---

{% asset_img header_pic.png %}

## 前言

> 本文内容**仅作为学习交流**，希望大家多多支持正版软件。
>
> Emmmmm... 其实最初是准备写一篇关于 iOS 应用的逆向笔记的，不过一直没找到合适的目标 App 以及难度适宜的功能点来作为写作素材... 
> 
> 破解了 Bartender 之后我觉得对于 Bartender 的破解过程难度适中，非常适合当做素材来写，且不论是 Mac App 还是 iOS App，逆向的思路都是相通的，所以就写了这篇文章~

国庆之前，果果放出了最新操作系统 macOS Mojave 的正式版本，相信很多小伙伴都跟我一样在正式版发布后紧跟着就升级了系统（此前由于工作设备参与项目产出需要确保系统稳定性所以没敢尝鲜的同学应该不只我一个人哈）。

升级到正式版 macOS Mojave 之后，我兴致勃勃的在新系统中各处探索了一番，然后将系统切换到 Dark Mode 后打开 Xcode 心满意足地敲（搬）起了代码（砖）... 

嘛~ 又是一个惬意的午后，有时候人就是这么容易满足（笑）~ 

等等！这是什么鬼！？我的 Bartender 怎么不能正常工作了（其实现在回想起来应该是试用期到期了）...

{% asset_img bartender_invalid.png %}

本文将以 Bartender 为目标 App，讲解如何通过静态分析工具 Hopper 逐步分析 Bartender 的内部实现逻辑并结合动态分析等手段逐步破解 Bartender 的过程与思路~

## 索引

- Bartender
- Hopper
- 逆向过程 & 思路
- 总结

## Bartender

{% asset_img bartender_show.jpg %}
{% asset_img bartender_hide.jpg %}

[Bartender](https://www.macbartender.com/) 是一款可以帮助我们整理屏幕顶部菜单栏图标的工具。

随着我们安装的 App 不断增多，屏幕顶部菜单栏上面的图标也会对应不断增加。这些 App 的图标并非出自一家之手，风格各异，随着数目增多逐渐显得杂乱不堪。

我们可以通过 Bartender 来**隐藏**或**重新排列**这些恼人的小图标，可以将没什么用但是运行起来却要显示的 App 图标**始终隐藏**，将偶尔会用的 App 图标隐藏到 Bartender 功能按钮后面（用到的时候可以通过点击 Bartender 功能按钮**切换显隐**），只显示常用的或者我们认为好看的应用图标。

除此之外 Bartender 还具备一些其他更加深入的功能（比如支持全部菜单栏条目范围的搜索等等），毫无疑问它是一款非常棒的菜单栏图标管理工具。

{% asset_img bartender_honor.jpg %}

> Note: 重申，Bartender 仅售 15 刀，还是推荐各位使用正版，本文仅作为学习交流。

## Hopper

{% asset_img hopper_darkmode.jpg %}

[Hopper](https://www.hopperapp.com/) 是一款不错的 mac OS 与 Linux 反汇编工具，同时还提供一定的反编译能力，可以利用它来调试我们的程序。此外，Hopper 还支持控制流视图模式，Python 脚本，LLDB & GDB，并且提供了 Hopper SDK 可供扩展，在 Hopper SDK 的基础上你甚至可以扩展自己的文件格式和 CPU 支持。

值得一提的是 Hopper 的作者是一名独立开发者，他的日常工作环境也是在 mac OS 上，所以在 mac OS 上的 Hopper 是完全使用 Cocoa Framework 实现的，而 Linux 版本的 Hopper 则选择使用 Qt 5 来实现。

个人认为 Hopper 在 mac OS 上面的运行表现非常好，很多细节（比如类型颜色区分等）都做的不错，功能简洁的同时快捷键也很好记（Hopper 提供的功能已经覆盖了绝大多数使用场景）。

最关键的一点是收费良心，个人证书只要 99 刀，当之无愧的人人都买得起的逆向工具！当然如果你觉得贵，Hopper 还提供试用，试用形式类似于 Charles，每次开启后可以试用 30 分钟，一般情况下这已经够用了。

> Note: Hopper v4.4.0 支持 Mojave Dark Mode。

## 逆向过程 & 思路

这一章节的内容会详细的讲述我个人在破解 Bartender 过程中的想法以及中间遇到问题时解决问题的思路，之前没有涉足逆向或者逆向经验尚浅的同学可能会觉得比较晦涩，这种情况最好结合自己的实际操作反复阅读没有理解的地方直到真正弄明白为止。

相信自己，每一份努力终会有所回报！当有朝一日自己也可以通过自己的逆向技术破解 & 定制化自己感兴趣的 App 时，你会发现一切的努力都是值得的。

### 获取目标二进制

从 [Bartender 官网](https://www.macbartender.com/)下载最新的 Bartender，截止本文提笔之前 Bartender 的最新版本为 3.0.47。

将下载好的压缩包解压之后得到 Bartender 3.app，将 Bartender 3.app 文件复制到自己的 Application 文件夹下。右键点击 Bartender 3.app 选择“显示包内容”，在 Contents 目录下找到 MacOS 目录，里面有我们要的目标二进制文件 Bartender 3。

### 从“授权”着手

打开 Hopper，将目标二进制文件拖入 Hopper，在弹出的弹窗中选择 OK 后等待 Hopper 分析完毕。

{% asset_img hopper_interface.jpg %}

在左侧的分栏中选择 `Proc.` ，这可以让我们查看 Hopper 分析出来的方法。分栏下面有搜索框，内部可以通过输入关键词来过滤出我们想要的结果。因为一般的 App 都是通过某些方法判断是否授权的，这里我们先输入 ` is` （注意 is 前面加空格），然后观察过滤出来的结果。

{% asset_img hopper_filter.jpg %}

果不其然，发现里面有三个 `[xxx isLicensed]` 方法，点击方法 Hopper 会跳转至方法处。

> Note: 三处 `[xxx isLicensed]` 的方法内部逻辑几乎一样，这里拿 `[Bartender_3.AppDelegate isLicensed]` 讲解，其他两处不做赘述。

{% asset_img is_licensed.png %}

Emmmmm... 这里的汇编代码还是比较简单的，虽然我不是很了解 x86 的汇编指令，不过 Hopper 已经帮助我们做了一些辅助性工作。其中开始处的 `push rbp` 以及结束处 `pop rbp` 可以简单理解为入栈出栈，`call sub_100067830` 可以理解为调用地址 `0x100067830` 处的方法，`pop` 之前的 `movsx eax, al` 和 ARM64 中的 `mov` 指令类似，可以理解为将 `al` 内存储的东西移动到 `eax` 寄存器中，**`eax` 寄存器用于存储 x86 的方法返回值**。

我们可以看出这里调用了地址 `0x100067830` 处的函数，拿到结果之后又调用了 `imp___stubs__$S10ObjectiveC22_convertBoolToObjCBoolyAA0eF0VSbF` 方法将结果做了转化，最后将结果赋值给 eax 寄存器用于结果返回。其中 `imp___stubs__$S10ObjectiveC22_convertBoolToObjCBoolyAA0eF0VSbF` 我们可以根据名称推测出该方法的作用应该是将 `Bool` 转化为 Objective-C 的 BOOL 而已。

那么关键信息应该在 `sub_100067830` 处，双击 `sub_100067830` Hopper 会跳转到 `0x100067830` 处，这样我们就可以分析其中的具体实现了。不过 `0x100067830` 内部的实现比较复杂，跳转过去之后发现汇编代码非常多，还有很多跳转... 这时候我们可以通过 Hopper 顶部中间靠右一点的分栏，点击显示为 `if(b) f(x);` 的按钮查看伪代码。

Hopper 解析出来的伪代码风格类似 Objective-C 代码，可以看到 `0x100067830` 内部通过 `NSUserDefaults` 以及其他的逻辑实现，其中还包括其他的形式为 `sub_xxxxxx` 的方法调用，这种情况下如果我们继续跳转到这些方法的地址查看其内部实现很有可能陷入递归中... 

{% asset_img sub_100067830.jpg %}

那么这种情况该如何处理呢？

分析问题，我们找到 `[xxx isLicensed]` 并且觉得这有可能就是 Bartender 中判断授权与否的函数，那么我们只需要将三处 `[xxx isLicensed]` 的返回值改为 `true` 即可。所以这里我们没有必要一步步的看其内部实现，先返回 `[Bartender_3.AppDelegate isLicensed]` 处。前面讲过在 x86 汇编中 `eax` 寄存器用于存储方法的返回值，我们在 `[Bartender_3.AppDelegate isLicensed]` 按快捷键 `option + A` 插入汇编代码 `mov eax, 0x1` 将 `eax` 永远赋值为 `1` 即 `true` 之后跟 `ret` 即 return 指令直接让函数返回 `true` 就可以达到我们的目的了。

{% asset_img hopper_return_0x1.png %}

用快捷键 `shift + command + E` 导出二进制文件，覆盖到原 Bartender 目录中，尝试运行。你会发现一开始是成功的，屏幕顶部的菜单栏图标也被正常管理了，但是过了大约 10s 之后一切又变回了原样，并且还会弹出一个试用期到期的弹窗...

{% asset_img bartender_trialended.jpg %}

### 重拾思路

那么我们刚才修改的三处 `[xxx isLicensed]` 为什么没有产生作用呢？其实它已经产生作用了，虽然我们不可以正常使用 Bartender，但是打开 Bartender 的 License 界面我们可以发现这里的界面已经显示我们付过款了，**尽管这并没有什么卵用就是了...**

{% asset_img bartender_paid.jpg %}

到这里我们似乎没有什么头绪了，因为延时方法有很多，光是凭借这一条线索很难定位到阻止我们破解的目标代码位置。

逆向过程中的思路很重要，如果**遇到思路断了的情况不要着急也不要气馁**，我们可以重新运行程序，尝试不同的操作并观察操作对应的表现 & 结果。

经过反复运行程序，我发现每次重新启动 Bartender 都可以有大约 10s 的可用时间，如果启动之后直接主动点击 Bartender 的功能按钮则会直接弹出试用期到期弹窗且顶部菜单栏图标也会直接回到之前杂乱的样子。

这时候我的思路从延时方法转移到了这个 Trial ended 弹窗以及 Bartender 的功能按钮点击之后的对应方法上。这就是**动态分析**，它可以帮助我们重新找回思路。

### 按钮响应方法

有了思路，对应的方法并不难找。我们可以利用 Hopper 的 Tag Scope 先把可能出现的区域找出来，再到对应的区域下的方法列表中寻找我们的目标方法位置。

{% asset_img hopper_tag_scope.jpg %}
{% asset_img status_item_click.png %}

这里我很快就找到了目标函数 `-[_TtC11Bartender_311AppDelegate bartenderStatusItemClickWithSender:]`, 其内部调用了 `sub_100029ac0(arg2);` 其中 `arg2` 就是 `sender`，也就是这个 Bartender 的功能按钮了。

``` objc
int sub_100029ac0(int arg0) {
    sub_100022840(arg0);
    rbx = **_NSApp;
    if (rbx == 0x0) goto loc_100029f44;

loc_100029ae7:
    [rbx retain];
    r14 = [[rbx currentEvent] retain];
    rdi = rbx;
    if (r14 == 0x0) goto loc_100029bef;

loc_100029b18:
    [rdi release];
    if (([r14 modifierFlags] & 0x80000) != 0x0) goto loc_100029b6e;

loc_100029b33:
    [r14 retain];
    if ((([r14 modifierFlags] & 0x40000) != 0x0) || ([r14 type] == 0x4)) goto loc_100029b66;

loc_100029bcc:
    rbx = [r14 type];
    [r14 release];
    if (rbx == 0x3) goto loc_100029b6e;

loc_100029bec:
    rdi = r14;
    goto loc_100029bef;

loc_100029bef:
    [rdi release];
    r14 = [[swift_getInitializedObjCClass(@class(NSUserDefaults)) standardUserDefaults] retain];
    if (*qword_1000e7e70 != 0xffffffffffffffff) {
            swift_once(qword_1000e7e70, sub_100069790);
    }
    rbx = *qword_1000ee1f8;
    r15 = *qword_1000ee200;
    swift_bridgeObjectRetain(rbx);
    r15 = (extension in Foundation):Swift.String._bridgeToObjectiveC() -> __ObjC.NSString(rbx, r15);
    swift_bridgeObjectRelease(rbx);
    rbx = [[r14 objectForKey:r15] retain];
    [r15 release];
    [r14 release];
    if (rbx != 0x0) {
            swift_getObjectType(rbx);
            var_50 = rbx;
    }
    else {
            intrinsic_movaps(var_40, 0x0);
            var_50 = intrinsic_movaps(var_50, 0x0);
    }
    rax = sub_10001c9a0(&var_50, &var_78);
    if (var_58 != 0x1) goto loc_100029cd8;

loc_100029ccd:
    sub_10001c2f0(&var_78);
    goto loc_100029d44;

loc_100029d44:
    if (*(int8_t *)(r13 + *objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded) == 0x1) {
            rax = sub_1000230e0(0x1);
    }
    else {
            *(int8_t *)(r13 + *objc_ivar_offset__TtC11Bartender_311AppDelegate_performDelayedClicks) = 0x1;
            rax = sub_1000215f0();
            if ((rax & 0x1) == 0x0) {
                    rbx = *objc_ivar_offset__TtC11Bartender_311AppDelegate_performDelayedClicks;
                    rax = *(int8_t *)(r13 + rbx);
                    rax = !rax & 0x1;
                    *(int8_t *)(r13 + rbx) = rax;
            }
    }
    return rax;

loc_100029cd8:
    rcx = *qword_1000e8a98;
    if (rcx == 0x0) {
            rcx = swift_getObjCClassMetadata(swift_getInitializedObjCClass(@class(NSDictionary)));
            *qword_1000e8a98 = rcx;
    }
    rax = swift_dynamicCast(&var_28, &var_78, *type metadata for Any + 0x8);
    if (rax == 0x0) goto loc_100029d44;

loc_100029d24:
    r14 = var_28;
    if ([r14 count] == 0x0) goto loc_100029d8f;

loc_100029d3c:
    [r14 release];
    goto loc_100029d44;

loc_100029d8f:
    r15 = [objc_allocWithZone(@class(NSAlert)) init];
    rbx = sub_1000a7f20("No menu items have been setup", 0x1d, 0x1, rcx, 0x6);
    r12 = (extension in Foundation):Swift.String._bridgeToObjectiveC() -> __ObjC.NSString(rbx, 0x1);
    swift_bridgeObjectRelease(rbx);
    [r15 setMessageText:r12];
    [r12 release];
    rbx = sub_1000a7f20("No menu items have been setup in Bartender Preferences, so Bartender is not doing anything yet. Would you like to open preferences now.", 0x87, 0x1, rcx, 0x6);
    r12 = (extension in Foundation):Swift.String._bridgeToObjectiveC() -> __ObjC.NSString(rbx, 0x1);
    swift_bridgeObjectRelease(rbx);
    [r15 setInformativeText:r12];
    [r12 release];
    [r15 setAlertStyle:0x1];
    rbx = sub_1000a7f20("Open Preferences", 0x10, 0x1, rcx, 0x6);
    r12 = (extension in Foundation):Swift.String._bridgeToObjectiveC() -> __ObjC.NSString(rbx, 0x1);
    swift_bridgeObjectRelease(rbx);
    rbx = [[r15 addButtonWithTitle:r12] retain];
    [r12 release];
    [rbx release];
    rbx = sub_1000a7f20("Dismiss", 0x7, 0x1, rcx, 0x6);
    r12 = (extension in Foundation):Swift.String._bridgeToObjectiveC() -> __ObjC.NSString(rbx, 0x1);
    swift_bridgeObjectRelease(rbx);
    rbx = [[r15 addButtonWithTitle:r12] retain];
    [r12 release];
    [rbx release];
    if ([r15 runModal] == 0x3e8) {
            sub_100029a10();
    }
    [r15 release];
    rax = [r14 release];
    return rax;

loc_100029b6e:
    *(int8_t *)(r13 + *objc_ivar_offset__TtC11Bartender_311AppDelegate_performDelayedClicks) = 0x0;
    rdi = r14;
    if (([rdi modifierFlags] & 0x40000) == 0x0) {
            sub_100020de0();
    }
    else {
            if (*(int8_t *)(r13 + *objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded) == 0x1) {
                    sub_1000230e0(0x1);
            }
            else {
                    sub_100020fe0(rdi);
            }
    }
    rax = [r14 release];
    return rax;

loc_100029b66:
    [r14 release];
    goto loc_100029b6e;

loc_100029f44:
    asm { ud2 };
    rax = sub_100029f46();
    return rax;
}
```

> PS: 为了便于读者结合后面分析部分的内容快速定位（Command + F），上面的伪代码没有使用截图形式展示。

其中很醒目的是 `objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded` 我们按照之前的方法，将伪代码先切回汇编模式，找到对应的汇编代码处。

{% asset_img if_trial_ended.png %}

这是一段明显的 `if` 语句汇编代码，看下面的 `mov edi, 0x1` 这一小节就是指 `objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded` 为 `true` 之后执行的代码，表示**要是试用期到期就执行 `0x1000230e0` 处的方法**。我们记下这个地址之后把这两处的汇编代码通过上文插入汇编代码的方式修改一下，将这个 `objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded` 直接替换为 `0x0` 即 `false` 。

{% asset_img if_false.png %}

在逆向工程中，切忌不可以冒进，时值今日几乎所有应用都会采取措施来增加其逆向难度。这时候千万不要想着一步到位，应该在适量修改之后尝试导出二进制，用动态分析的方法验证一下结果。因为我们这时候不是正向开发者，在没有见到上下文的情况下修改代码很可能会把程序改成一个不可用的状态（比如正常功能损坏或者频繁 Crash），所以最好步步为营。

这里我们导出修改之后的二进制文件，按照 Bartender 的原路径覆盖之前的二进制文件验证一下结果。我在这个阶段运行时发现如果正常开启 Bartender 还是会有一个 10s 左右的可用时长，之后依然会弹出试用期到期弹窗，并且程序变为不可用状态；而如果重启 Bartender 在试用期弹窗弹出之前点击功能按钮则可以正常切换，但是再次点击按钮却切换不回来了，并且程序运行 10s 左右仍会弹出试用期到期弹窗，但是菜单栏上面的图标不会变失效，只是切不回去而已。

### 功能破解

到目前为止如果不在乎功能仅仅想要隐藏菜单栏的图标已经是可以凑合用了，但是这显然不是我们想要的最终结果。

通过上面运行程序后观察到的情况我推测在 `-[_TtC11Bartender_311AppDelegate bartenderStatusItemClickWithSender:]` 内部切换回来的逻辑中仍然有地方对是否到期做了判断，我们上面只是成功修改了切换过去的逻辑，那么切换回来的逻辑在哪呢？

按逻辑推测，正向切换的时候是使用 `objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded` 做判断，反向切换应该同理才对，我们去追踪 `objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded` 的使用，最终发现 `sub_10001f870` 中使用了 `objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded` 且 `sub_10001f870` 被 `sub_100029a10` 调用，`sub_100029a10` 又被 `sub_100029ac0` 调用，`sub_100029ac0` 就是上文在 `-[_TtC11Bartender_311AppDelegate bartenderStatusItemClickWithSender:]` 中被调用的函数，这不仅满足了被 Bartender 功能按钮所引用的条件，同时还对 `objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded` 有所引用，所以我用插入汇编的方式将 `sub_10001f870` 中关于 `objc_ivar_offset__TtC11Bartender_311AppDelegate_trialEnded` 的使用改为了 `0x0`，即 `false`。

嘛~ 导出二进制覆盖，发现这次的 Bartender 已经可以正常使用功能了，不过试用期到期的弹窗问题依然存在，尽管它并不影响使用，但我还是无法接受这样一个半成品的状态。

### 完美破解

还记得上文中得出的 `0x1000230e0` 吗，如果试用期到期则会执行 `0x1000230e0` 地址处的方法，我们通过快捷键 `G` 跳转到 `0x1000230e0` 地址，看一下里面的实现逻辑。

```
void sub_1000230e0(int arg0) {
    r14 = arg0;
    r15 = r13 + *objc_ivar_offset__TtC11Bartender_311AppDelegate_trialOverWindow;
    rbx = swift_unknownWeakLoadStrong(r15);
    if (rbx != 0x0) {
            [rbx center];
            [rbx release];
            rbx = **_NSApp;
            if (rbx != 0x0) {
                    [rbx retain];
                    [rbx activateIgnoringOtherApps:sign_extend_64($S10ObjectiveC22_convertBoolToObjCBoolyAA0eF0VSbF(r14 & 0xff))];
                    [rbx release];
                    rbx = swift_unknownWeakLoadStrong(r15);
                    if (rbx != 0x0) {
                            [rbx makeKeyAndOrderFront:0x0];
                            [rbx release];
                    }
                    else {
                            asm { ud2 };
                            sub_100023199();
                    }
            }
            else {
                    asm { ud2 };
                    loc_100023195();
            }
    }
    else {
            asm { ud2 };
            loc_100023191();
    }
    return;
}
```

通过上面的伪代码，我们可以初步判断这个 `0x1000230e0` 内部就是弹出试用期到期弹窗的方法。接着我们通过快捷键 `X` 查看关于 `0x1000230e0` 的引用，可以发现有三处调用，一个一个看下去发现第一个 `sub_100022840` 中的调用最像是延时调用，因为其中有 Hopper 反编译出来的 Dispatch 相关的伪代码。

```
	$Ss10SetAlgebraPyxqd__cs8SequenceRd__7ElementQyd__ADRtzlufCTj(&var_A0, r13);
    swift_release(*__swiftEmptyArrayStorage);
    (extension in Dispatch):__ObjC.OS_dispatch_queueasyncAfterdeadlineqosflags.execute(Dispatch.DispatchTime, Dispatch.DispatchQoS, Dispatch.DispatchWorkItemFlags, @convention(block) () -> ()) -> ()(var_40, var_68, var_B0, var_30);
    (*(var_D0 + 0x8))(var_B0, var_C8);
    (*(var_C0 + 0x8))(var_68, var_B8);
    _Block_release(var_30);
    swift_release(var_D8);
    (var_38)(var_40, var_70, rdx);
    [var_A8 release];
    sub_1000230e0(0x0);
    rbx = var_48;
    goto loc_100022df5;
```

切到汇编模式，找到对应的汇编代码。

{% asset_img call_trial_window.jpg %}

由于 `sub_1000230e0(0x0);` 是在 Dispatch 中调用的，考虑到修改后程序的稳定性，这里通过 Hopper 的 Modify 菜单中提供的 NOP Region 填平 `call sub_1000230e0` 汇编代码。

{% asset_img nop.jpg %}

老规矩，导出二进制文件覆盖 Bartender 中的二进制后重启 Bartender 验收成果。

{% asset_img bartender_valid.png %}

清爽~ 这次运行 Bartender 发现不但可以正常使用功能，之前烦人的试用期到期弹窗也被我们成功干掉了。

## 总结

- 文章简单介绍了本次要破解的目标 Mac 应用 Bartender，如果各位同学还没有找到合适的顶部菜单栏图标管理工具不妨试着使用 Bartender。
- 文章介绍了 maxOS 与 iOS 逆向工程中主流的静态分析工具 Hopper，从文章后面破解 Bartender 的实战过程中就可以看出 Hopper 对于我们逆向过程的帮助有多么大。
- 文章最后详细讲述了我在破解 Bartender 过程中的经历，从**初始常规思路**到不起作用**思路被截断**再到通过动态分析**重拾思路**...一直到最后的**完美破解**中间经历了许多关键节点，希望对大家有所帮助。

每一次逆向的过程都是未知的，有的时候可能会很顺利（直接 `mov eax, 0x1` + `ret` 就搞定），有的时候可能会很曲折，有的时候可能还会以失败收尾。我写这篇文章主要是想与大家交流在逆向过程中的常规方法以及遇到困难时的一些解决思路，其实不论是 Bartender 还是其他应用，不论是 Mac 应用还是 iOS 应用，逆向的思路都是相通的，愿各位同学日后可以举一反三。

如果有任何问题欢迎在文章下方留言或在我的微博 [@Lision](https://weibo.com/lisioncode) 联系我，真心希望我的文章可以为你带来价值~