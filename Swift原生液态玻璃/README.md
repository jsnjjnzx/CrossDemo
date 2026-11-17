# Swift 原生液态玻璃对照

与旁边的Qt单界面Demo同形式：1180×820内容区，600×386面板、56圆角、相同名义字号和文字、相同位置的三个圆按钮。Swift/AppKit负责界面，`NSGlassEffectView`负责真实系统玻璃；Metal只按Qt背景公式绘制色带，没有移植Qt玻璃shader，也没有叠手绘玻璃高光。

双击本目录 **Swift Liquid Surface.app**，同时打开 `../单界面液态玻璃/Qt Liquid Surface.app`。拖动面板或聚焦后用方向键移动；底部依次暂停、切高反差色带、切Clear／Regular。Esc关闭、⌘Q退出，Tab切焦点、空格按下按钮。与Qt一致，时间／日期／天气是示例内容。

推荐先让两版都显示高反差色带并暂停，在相同内容区尺寸下观察边缘如何弯折、色带与文字交界、圆角厚度和高光；然后播放并慢慢拖动。背景公式和初始phase相同，但两个独立app没有逐帧同步。Qt的“柔化”是自定义采样参数，Swift第三个按钮切换系统Clear／Regular，二者不宣称等价。系统材质会受辅助显示和窗口状态影响；不要把不同尺寸、材质或背景相位混作同条件。

原生背景按所在屏幕最大刷新率请求绘制，以对齐Qt默认跟随屏幕刷新的目标；实际帧率、延迟、能耗未经测量，不用请求值声称性能一致。

这项对比反映的是 **Qt自定义光学与Apple系统材质这两种实现栈**，并不是Swift／C++语言天然产生不同玻璃。前一版Qt键盘Demo本身也曾通过桥接使用NSGlassEffectView；同一系统API可以被不同语言调用。原生文字使用AppKit文本控件，Qt使用QML文本，字形栅格化微差也属于实现栈差异。

## 构建和验证

```bash
bash "Swift原生液态玻璃/build.sh"
open "Swift原生液态玻璃/Swift Liquid Surface.app"
```

macOS26+、Xcode Swift6和Metal。仅系统框架；签名读取项目已有本地忽略配置，不添加第三方依赖。单一app位于本目录，缓存／证据在`build/local-test/swift-surface-demo/`。构建拒绝覆盖运行包，需先正常退出；新包签名及自检成功才替换旧包。不改Qt源码、Qt包、正式FaunaBox包、真实设置或系统权限。

`--self-test --evidence-dir <目录> --qt-reference-dir <Qt证据目录>`检查布局、真实NSGlass内容归属、样式、可访问降级和GPU背景。Qt缓存存在时，构建脚本比较两种背景在已知phase、相同像素尺寸下的玻璃外区域。生成的`native-background-only.png`只有背景；`comparison-checks.json`记录结果。自身离屏背景不能捕获系统合成器的最终玻璃；本轮用户选择手验，没有Computer Use，不将结构检查或背景一致性说成玻璃视觉通过。

2026-11-17验证：Swift6优化构建、24项检查、稳定签名通过；两种背景的玻璃外平均通道差分别0.06536/255、0.08954/255。Qt源码和原包可执行哈希保持。Swift原生包约236KB。最终玻璃观感、实际持续性能、多屏及读屏待手验。

系统“减少透明度／增强对比度”改为实底并保留内容；“减少动态效果”停止背景。暂停、最小化或被完全遮挡时停止持续绘制，辅助选项只读刷新。玻璃取样来自本窗口下方的Metal背景，不读取其他窗口／壁纸／桌面，不申请录屏。

## 官方依据

- [NSGlassEffectView](https://developer.apple.com/documentation/appkit/nsglasseffectview)：公开系统玻璃；内容放入`contentView`，圆角和Clear／Regular使用公开属性。
- [contentView](https://developer.apple.com/documentation/appkit/nsglasseffectview/contentview)：真实前景的原生归属。没有将任意装饰子视图冒充玻璃内部内容。
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)：参考自定义形状、内容／材质分层；本例用AppKit公开对等API。
- [Landmarks官方示例](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)：参考系统材质与背景内容的使用方式。当前在线样例版本标注macOS27/Xcode27，未原样集成；本机26可用性按本地SDK和实际编译核对。

本机SDK将AppKit `effectIsInteractive`标为macOS27，因此26上没有调用它，也没有用私有selector绕过。系统折射强度、色散或倒角法线没有在这里伪造为公开可调参数。新源码和背景移植自本项目Qt实验，未复制第三方样例代码。
