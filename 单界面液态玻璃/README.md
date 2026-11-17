# Qt 单界面液态玻璃

Qt 6.11 Quick / QML + GLSL 运行示例。中央一块可拖动玻璃，后方是持续流动的应用内色带。默认用通透材质，底部可以暂停、切高反差折射对照图、切柔化材质；悬停按钮显示标签。拖动玻璃或Tab聚焦面板后用方向键移动；Esc关闭。

这是Qt自定义光学近似，玻璃的纹理输入就是同一窗口里的动态背景，没有读取桌面或其他应用，也没有抓屏权限。它不调用NSGlassEffectView，不冒称Apple官方材质；Objective-C++仅只读系统“减少动态效果／减少透明度／增强对比度”，启用时相应停动或实底。

圆角距离场构造28点宽的弧形倒角和表面法线，以1.46折射率近似Snell光线偏移，再取样实时ShaderEffectSource纹理。边缘有Fresnel亮度、方向高光、轻微色散；中央是浅透镜与9点柔化。指针高光跟随鼠标，拖动面板时光学与文字共用同一几何。没有背景运动时的独立闪光动画。时间／日期／天气均为界面示例。

```bash
bash "单界面液态玻璃/build.sh"
open "单界面液态玻璃/Qt Liquid Surface.app"
```

本例已按Windows／macOS条件化工程：macOS辅助选项使用AppKit，Windows使用公开Win32只读接口；玻璃仍是同一QML／GLSL。图形后端交由Qt选择，qsb生成Metal／HLSL等资源。Windows结果见仓库根test-report.md，Linux未验证。Windows脚本和Actions在仓库根，独立克隆时macOS缓存使用本仓库build/local-test/；签包需要CROSSDEMO_SIGNING_IDENTITY，运行包拒绝覆盖。

`--self-test --render-dir <目录>` 只读取本窗口的GPU渲染画面：比较无折射／有折射、背景运动、柔化、实底不透及拖动几何，保存PNG证据后退出。默认`ctest`不写图片。像素对照证明采样发生变化，不能代替用户对Apple式质感和流畅度的认可；本轮用户选择手验，无Terra或Computer Use。

2026-11-17验证：Release／QSB、17项GPU检查与打包后25项含7图保存检查通过，依赖／严格签名通过。证据在缓存的evidence/和build-and-package.log。未测窗口拖动后的任意缩放、多屏、长期性能及读屏。

实现参考Qt官方 [ShaderEffect](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html)、[ShaderEffectSource](https://doc.qt.io/qt-6/qml-qtquick-shadereffectsource.html)、[qt_add_shaders](https://doc.qt.io/qt-6/qt-add-shaders.html)。新背景和GLSL自写，没有复制第三方实现或新增素材依赖。
