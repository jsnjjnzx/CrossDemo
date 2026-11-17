# CrossDemo

Qt Quick 液态玻璃的 Windows／macOS 对照实验。同一块可拖动玻璃面板、持续运动的背景、边缘折射、柔化和高光。Qt 单面板的玻璃由自写 GLSL/QSB 绘制，不依赖苹果原生玻璃组件。

2026-11-17用户Windows实机反馈：正常运行，与Mac版几乎没有差别，视觉效果认可。这是当前Demo的用户主观验收；未提供设备配置或量化性能数据，不能外推到所有硬件和完整产品。

## Windows 测试包

2026-11-17已通过的版本：[下载 Windows x64 便携包](https://github.com/jsnjjnzx/CrossDemo/actions/runs/44106602358/artifacts/14338667795)（约30MB，Actions保留30天），[构建记录](https://github.com/jsnjjnzx/CrossDemo/actions/runs/44106602358)。源码提交`7662e2d`，完整部署后的25项图形检查通过。

打开 [Windows Qt Demo Actions](https://github.com/jsnjjnzx/CrossDemo/actions/workflows/windows.yml)，进入最新成功的构建，在 Artifacts 下载 **CrossDemo-Windows-x64**。完整解压后双击 `QtLiquidSurface.exe`，保留旁边的 DLL、`platforms`、`qml` 目录。无需安装 Qt 或 Visual Studio。

目标 Windows 11 x64。拖动面板；底部三个按钮依次暂停／播放、切高反差色带、切柔化。悬停显示标签，Tab／方向键／空格可操作，Esc关闭。时间、日期和天气为示例，没有真实启动／搜索功能。

CI用Direct3D 11 WARP验证图形正确性，正常启动按Qt默认方式选择本机图形后端。CI不代表实体显卡的性能或观感已通过。实际构建结果见[test-report.md](test-report.md)。

## 三个例子

| 目录 | 内容 | 平台 |
|---|---|---|
| [单界面液态玻璃](单界面液态玻璃/README.md) | Qt Quick + C++ + 自写shader，Windows构建目标 | Windows／macOS；Linux未验证 |
| [Swift原生液态玻璃](Swift原生液态玻璃/README.md) | Swift/AppKit系统NSGlassEffectView，同形式对照 | macOS26+ |
| [根目录键盘例](README-keyboard-macos.md) | Qt Widgets通过公开AppKit接口绘制系统玻璃 | macOS26+ |

单面板仅取样应用内背景，不读取桌面／其他窗口，不申请录屏、不存储真实偏好。Windows读取动画、高对比和透明度偏好，macOS读取对应辅助显示选项。字体、DPI、驱动、背景来源和系统材质应分别比较。

## 从源码构建

需要Qt 6.11.1（Quick、ShaderTools）、CMake和对应C++工具链。Windows安装Qt MSVC2022 x64及Visual Studio 2022后，在PowerShell7运行：

```powershell
./scripts/build-windows.ps1 -QtRoot 'C:/Qt/6.11.1/msvc2022_64'
```

输出为`dist/windows/`。脚本编译Release、部署Qt/QML和VC运行库，再在移除SDK搜索路径后复测。Actions使用同一流程，推送main自动构建，也可手动触发。

macOS在仓库根构建单面板：

```bash
cmake -S "单界面液态玻璃" -B build/qt-surface -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(qtpaths6 --query QT_INSTALL_PREFIX)"
cmake --build build/qt-surface
ctest --test-dir build/qt-surface --output-on-failure
```

三个macOS例子的`build.sh`使用稳定开发签名，需要`CROSSDEMO_SIGNING_IDENTITY`环境变量提供证书身份；位于原父工程时兼容其本地签名配置。缺证书停止，不降级ad-hoc。运行包拒绝覆盖，需先正常退出。

本仓库仅包含Demo源码、文档和程序生成素材，不上传构建包、证书、父工程配置或旧本地专用壁纸。组件说明见[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。
