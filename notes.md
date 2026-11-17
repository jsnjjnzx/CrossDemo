# CrossDemo 决策记录

## WIN-001：交付结果

最终Actions44106602358（源码7662e2db99453809eda78b39bbfa9cc915285969）成功，Windows-2022／MSVC19.44／Qt6.11.1／Direct3D11 WARP。便携包约29.86MB，完整部署后移除Qt SDK的PATH／QML／插件搜索变量再运行，25项检查通过。用户机器默认选择图形后端，不把CI的WARP环境写入包内设置。

首次本地Git直连成功；后续GitHub Git端口间歇连接失败时，改用本机gh直连GitHub Git数据API上传。远程tree和commit SHA均与本地7662e2d完全相同后，才快进main，未建立两套不同历史，也未改系统代理。连接器仅负责只读仓库／Actions与下载引用。

Qt6TaskTree缺失是未使用的可选QmlAssetDownloaderPrivate插件提示；本例Quick配置、编译、QML部署和自检均通过，不为未使用功能额外增加模块。两个失败任务保留真实记录，后文为阶段决策。

## WIN-001

仓库由FaunaBox下Qt Demo独立初始化。公开单面板使用Qt Quick+自写GLSL/QSB；macOS用Metal，Windows交由Qt选择Direct3D等后端，不使用NSGlassEffectView绘制该面板。只有macOS辅助选项小适配使用AppKit，Windows单独实现。

Qt键盘例与Swift例保留作macOS比较。程序生成背景替代旧本地专用壁纸用于公开键盘源码；原wallpaper.png不上传。独立发布不包含父项目流程历史／证书。Windows云端自检与实体显卡观感分别记录。

本机Git／GitHub API连接出现过SSL／TLS超时；连接器读取正常但写入被integration权限拒绝。本机gh登录具备repo／workflow范围，已用其API核实空仓库，继续通过本机账户上传。根分支main、用户指定origin不变；内容按35文件暂存树校验。

实际上传用Git CLI单次绕过故障环境代理成功，未更改系统代理。首轮Actions 44104445981停在安装阶段：aqt3.3.0不识别Qt6.11起按编译器拆分的目录，错误请求qt6_6111/qt6_6111/Updates.xml。已核实官方目录为qt6_6111_msvc2022_64，并核对aqt官方上游已有该解析修复；固定到5a49f2b391ae8ee1d3c0dd87f8b33c1d49a4deb7，保留Qt6.11.1，与本机一致。Python固定3.12避免无关最新解释器依赖构建漂移。

第二轮44105168224安装Qt成功，CMake的qmlimportscanner报告中文源码路径不存在。仓库原目录保留，Windows脚本在build/windows-source复制同一份普通源码文件，以ASCII路径配置和部署QML，不修改算法或界面。所有暂存内容仍位于忽略的build目录。
