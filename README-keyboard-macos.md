# macOS 原生玻璃键盘比较例

新增：[Swift原生液态玻璃对照](Swift原生液态玻璃/README.md)，与Qt单界面Demo同布局和背景，使用Swift/AppKit的系统玻璃供手动比较。

新增：[单界面液态玻璃](单界面液态玻璃/README.md)是另一项独立Qt Quick实验，运动背景／可拖动单面板，使用自写shader进行透光和折射；包位于该子目录。本页下文仍说明前一版Qt Widgets键盘与原生AppKit玻璃。

独立的 Qt 6 C++ / Widgets 实验，macOS 26+。Qt 管理窗口、四行 38 键布局、绘制、键盘／鼠标和动画；Objective-C++ 小桥接给每个键帽接入 Apple 公开 `NSGlassEffectView`。玻璃来自系统合成器，指针追光／抬升／回弹是 Qt 自定义反馈。没有真实启动、搜索、绑定、全局热键或持久化。

双击本目录的 **Qt Glass Keyboard.app**。右上角四个按钮依次切换背景、Clear／Regular 材质、明暗外观、关闭；悬停显示 tooltip。鼠标划过、点击键帽或按对应键查看反馈；拖动空白移动窗口，Esc 关闭，Tab 切换焦点、空格按压。搜索条只展示外观。

默认是应用内蓝色参考图，便于对照取样与边缘。切换为“桌面”后，窗口自身背景透明，玻璃由系统处理窗后内容；没有屏幕截图、壁纸读取、录屏权限或纹理捕获。浅色主题适合明亮背景，深色主题适合深背景。背景、应用前后台与系统辅助显示选项都会影响系统材质；不能承诺所有环境与 Apple 宣传图逐像素一致。

系统“减少透明度”／“增强对比度”启用时使用实底；“减少动态效果”关闭位移与回弹，仍保留焦点／按压反馈。这些选项每秒只读刷新，不更改系统设置。图标只从本机应用读取，缺失时用原创色块符号；不会启动应用。当前桥接只支持 macOS，未声称 Windows 能使用苹果材质。

## 构建与测试

```bash
bash build.sh
open "Qt Glass Keyboard.app"
```

需要 Xcode 的 macOS 26+ SDK、CMake、Ninja 和 Qt 6 Widgets（已在本机发现 Qt 6.11.1）。脚本读取项目已有忽略的 `config/macos-signing.local.json` 中开发证书，缺证书则停止，Qt frameworks 与实际使用的 Cocoa／Widget 样式插件通过 `macdeployqt` 打包，不需另装 Qt 运行环境。不替换 `dist/local-test/FaunaBox.app`。缓存位于 `build/local-test/qt-glass-demo/`，本目录只交付一个 app。

构建前正常关闭本 Demo，脚本拒绝覆盖运行包；旧包只有在新包签名和自检成功后才归档替换。`--self-test` 检查真实 Qt／AppKit 视图关系、38 键／不重叠／缩放边界、图标资源、可访问名、材质切换、辅助回退与悬停位移后自动退出。macOS GUI 自检需要 WindowServer 会话，不能用无 GUI／受限沙箱的启动失败判定渲染失败。

用户本轮选择手动验收；未运行 Terra 或 Computer Use。构建和结构自检不代表真实液态玻璃观感、连续扫过性能、读屏或多显示器已验收。

## 来源与实现取舍

- [Apple NSGlassEffectView](https://developer.apple.com/documentation/appkit/nsglasseffectview)：只使用 SDK 公开的 style、cornerRadius、contentView、tintColor；当前 SDK 的 `effectIsInteractive` 标记 macOS 27，26 上不调用。
- [Qt native window / winId](https://doc.qt.io/qt-6/qwidget.html#native-widgets-vs-alien-widgets)：Qt native widget 与 AppKit 的组合入口。
- [Qt ShaderEffect](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html)：研究了自定义 shader 路线；本例选原生玻璃，未引入 QML／shader 工具链。
- [fsalinas26/qt-liquid-glass](https://github.com/fsalinas26/qt-liquid-glass/tree/3b109e4de93f370f7e7b90d1b8f005c33a7657c3)：研究 Qt/native-host 组合方式。该版 README 明示包含私有扩展 selectors，仓库树未见 LICENSE；仅作为方案参考，未复制源码、未引入该库及其私有接口。
- [Ss168638/Liquid-Glass-Dock-QML](https://github.com/Ss168638/Liquid-Glass-Dock-QML)：比较 QML shader／背景捕获路线，未引入代码、捕获功能或依赖。
- 公开背景 `assets/demo-background.png` 为本仓库程序生成；旧本地 `wallpaper.png` 不提交。

Qt 和 macOS 的第三方框架仍受各自许可证约束。本仓库按用户要求公开源码；Windows Actions只构建单面板例。
