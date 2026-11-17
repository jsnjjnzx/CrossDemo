# CrossDemo 测试报告

## WIN-001：用户Windows实机验收（2026-11-17）

来源：用户在本次对话报告已实际测试，Windows版运行与Mac版几乎无差别，效果非常好。结果：用户确认正常运行，并接受当前单面板Demo的主观视觉效果。

该结果是用户实机反馈，独立于下文云端WARP检查；代理未在实体Windows上复测，也没有新增截图或硬件／DPI／量化性能数据。多显卡、混合DPI、FPS／能耗、长时间稳定性和读屏仍未验证。本次仅文档更正，未重跑源码测试／构建。以下为交付时的检查和历史阶段记录；其中“用户待验”状态以本节为准。

## WIN-001：最终云端结果（2026-11-17）

- 成功运行：[44106602358](https://github.com/jsnjjnzx/CrossDemo/actions/runs/44106602358)，源码提交`7662e2db99453809eda78b39bbfa9cc915285969`。
- Windows Server2022 runner，MSVC19.44，Qt6.11.1，x64 Release；C++／QSB编译通过。Qt6TaskTree是未使用私有资源下载插件的可选依赖提示，本例没有因此缺少运行依赖。
- 构建树CTest1/1、17项图形检查，5.80秒通过；部署后移除Qt SDK搜索路径，Direct3D11 WARP再次25项检查通过。边缘折射差14.97/255、面板外差0、运动背景差65.1725、柔化差10.8834。
- Qt/QML插件及app-local VC运行库完整性检查通过，便携程序自检退出码0。WARP是云端渲染正确性检查，不代表实体GPU帧率或能耗。
- [便携包14338667795](https://github.com/jsnjjnzx/CrossDemo/actions/runs/44106602358/artifacts/14338667795)：29,859,154字节；GitHub记录SHA256 `6a55b3f286ab190e96d85fb73ad009d075977bafafd50943005c21604ad1af7e`。
- [渲染证据14339361107](https://github.com/jsnjjnzx/CrossDemo/actions/runs/44106602358/artifacts/14339361107)：7张自身窗口GPU图及日志，3,408,680字节。两项Actions产物保留30天。

本机Mac同一跨平台源码Release／默认Metal的17项检查通过（2.32秒），键盘公开资源替换后CMake构建通过；YAML、三脚本bash -n、Git diff和上传边界检查通过。

渲染证据ZIP本地SHA256／CRC通过，已审阅Windows自身GPU输出07-interface.png，布局／文字完整且边缘有偏折。源图和portable日志保存于本地忽略的build/ci-evidence/，不提交二进制测试证据。

未执行Windows实体机器／独显／混合DPI／持续性能／读屏／用户视觉验收、CU或代码签名；Windows包为未签名实验包。以下保留失败及准备阶段记录，不将其计为通过。

## WIN-001：计划

上传前结果：本机Qt6.11.1 Release及QSB重新构建通过，移除强制Metal后默认后端的17项GPU检查通过，CTest 1/1、2.32秒。Ruby标准YAML解析Windows workflow结构通过；三份Mac build.sh的bash -n通过。独立Git暂存35文件，diff --cached --check通过，清单排除app、签名／本地配置、缓存及旧wallpaper.png。

Windows源码／PowerShell／部署流程尚待首次Actions真实执行；不能把本机检查写成Windows构建通过。以下为开始时的计划。

首次Actions 44104445981失败于Qt安装器仓库布局解析，未执行C++编译或GPU测试，无Windows包。已依据Qt官方目录和aqt上游源码修复安装器选择，待新一轮实际结果；失败未记为通过。

第二轮44105168224：Qt6.11.1安装成功，MSVC19.44识别成功，但qmlimportscanner不能识别中文源码路径，CMake配置失败；未编译或交付Windows包。改用忽略目录下的ASCII源码暂存路径，等待复验。Qt6TaskTree的可选插件依赖提示也记录，当前真正终止点是扫描器路径。

待执行本机macOS跨平台源码构建／GPU回归、Actions Windows Release构建、Qt/QML与VC运行库部署、部署后GPU像素对照与zip检查。云端自检仅用于渲染正确性，用户实际Windows观感、DPI、驱动／性能未验证。
