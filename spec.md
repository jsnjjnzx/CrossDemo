# CrossDemo 需求规格

## REQ-WIN-001

Qt Quick单面板的动态液态玻璃在Windows11 x64和macOS使用同一QML／GLSL实现。应用内运动背景取样，无桌面捕获、真实功能或持久化。窗口1180x820，面板600x386，保留拖动、暂停、色带和材质柔化对照。

## REQ-DELIVERY-001

当前交付：Actions44106602358已成功生成Windows x64便携包，包含Qt/QML和VC运行库。编译树17项、移除SDK搜索路径后的部署包25项RHI图形检查通过。2026-11-17用户报告Windows实机正常运行、与Mac版几乎无差别，视觉效果认可；未提供硬件、DPI或量化性能数据。

GitHub仓库jsnjjnzx/CrossDemo，Actions生成包含Qt/QML与所需运行库的Windows便携zip，部署后运行自身窗口GPU像素对照，用户Windows实机观感已获认可。旧Qt原生键盘／Swift比较例仅支持macOS。上传内容不含app、缓存、签名密钥或来源不明背景；不包含FaunaBox产品源码。
