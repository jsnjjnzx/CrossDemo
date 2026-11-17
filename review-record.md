# CrossDemo 审查记录

## WIN-001：计划

上传前主审：单面板CMake只在Apple启用OBJCXX/AppKit，MSVC使用UTF-8和W4/WX，移除强制Metal。Windows辅助只读SystemParametersInfo和EnableTransparency；玻璃算法与QML保持。Actions固定依赖commit、contents只读，部署VC CRT与QML，移除SDK路径后复测；WARP作为CI渲染环境不冒称实体GPU性能。自检失败阻止成功产物上传。

审查35文件清单：仅Demo源码、独立六文档和自生成32KB背景；旧本地壁纸／app／证书／父工程配置均忽略。Mac脚本兼容父工程并支持独立签名环境变量。云端编译／部署及Windows效果尚未确认。

首轮安装失败定位到aqt3.3.0解析旧目录；核对官方6.11.1目录和aqt官方上游处理win64_编译器后缀的源码，固定修复commit，未通过改源文件或降低Qt版本掩盖问题。Python固定到3.12，运行权限仍contents只读。

第二轮扫描器路径失败修复仅影响Windows构建脚本：复制原目录普通源码到ASCII build/windows-source，不复制app／目录，不改QML与shader。配置、windeployqt及自检使用同一暂存源码，原目录布局保持。

核对Qt单面板平台条件、Windows辅助设置公开读取、默认后端、MSVC、部署与自检、Actions权限／固定依赖及Git上传内容。只提交Demo源码／文档／自有素材，排除构建包、真实配置与未确认许可素材。完成后记录实际结果。
