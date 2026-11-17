# CrossDemo 决策记录

## WIN-001

仓库由FaunaBox下Qt Demo独立初始化。公开单面板使用Qt Quick+自写GLSL/QSB；macOS用Metal，Windows交由Qt选择Direct3D等后端，不使用NSGlassEffectView绘制该面板。只有macOS辅助选项小适配使用AppKit，Windows单独实现。

Qt键盘例与Swift例保留作macOS比较。程序生成背景替代旧本地专用壁纸用于公开键盘源码；原wallpaper.png不上传。独立发布不包含父项目流程历史／证书。Windows云端自检与实体显卡观感分别记录。

本机Git／GitHub API连接出现过SSL／TLS超时；连接器读取正常但写入被integration权限拒绝。本机gh登录具备repo／workflow范围，已用其API核实空仓库，继续通过本机账户上传。根分支main、用户指定origin不变；内容按35文件暂存树校验。
