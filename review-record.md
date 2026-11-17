# CrossDemo 审查记录

## WIN-001：反馈记录审查（2026-11-17）

已核对用户明确的Windows实际运行与视觉认可，将验收状态同步到spec／backlog／notes／test-report／AGENTS及README。只记录当前Demo的主观比较，不把未提供的设备配置或性能指标写成已通过；不把用户报告写成代理执行。本轮源码与workflow无修改，成功包继续对应7662e2d／Actions44106602358，无需重编。

## WIN-001：最终主审

审查Windows-only辅助实现、CMake平台／编译器条件、QML和GLSL保持、ASCII暂存路径、固定安装器修复、动态部署／SDK隔离后复测、VC CRT、Actions最小权限和产物链接。源码／workflow修复均实际重新构建，未弱化shader像素断言以使CI通过。

核实成功任务44106602358与本地7662e2d同一Git提交；Windows编译和完整部署后25项检查已通过。独立repo及父工程隔离，公开Git清单不含app、旧专用壁纸、证书、缓存或产品源码。历史失败明确保留，未将WARP当硬件性能。用户实体Windows验收与签名分发未完成；本轮可交实验便携包。以下为阶段审查记录。

下载的渲染证据ZIP通过SHA256／CRC核对，已目视检查07-interface.png：内容、文字与背景完整，边缘可见偏折，无整体纹理翻转；属于自身GPU静态输出审阅，仍不计用户物理显示器验收。

## WIN-001：计划

上传前主审：单面板CMake只在Apple启用OBJCXX/AppKit，MSVC使用UTF-8和W4/WX，移除强制Metal。Windows辅助只读SystemParametersInfo和EnableTransparency；玻璃算法与QML保持。Actions固定依赖commit、contents只读，部署VC CRT与QML，移除SDK路径后复测；WARP作为CI渲染环境不冒称实体GPU性能。自检失败阻止成功产物上传。

审查35文件清单：仅Demo源码、独立六文档和自生成32KB背景；旧本地壁纸／app／证书／父工程配置均忽略。Mac脚本兼容父工程并支持独立签名环境变量。云端编译／部署及Windows效果尚未确认。

首轮安装失败定位到aqt3.3.0解析旧目录；核对官方6.11.1目录和aqt官方上游处理win64_编译器后缀的源码，固定修复commit，未通过改源文件或降低Qt版本掩盖问题。Python固定到3.12，运行权限仍contents只读。

第二轮扫描器路径失败修复仅影响Windows构建脚本：复制原目录普通源码到ASCII build/windows-source，不复制app／目录，不改QML与shader。配置、windeployqt及自检使用同一暂存源码，原目录布局保持。

核对Qt单面板平台条件、Windows辅助设置公开读取、默认后端、MSVC、部署与自检、Actions权限／固定依赖及Git上传内容。只提交Demo源码／文档／自有素材，排除构建包、真实配置与未确认许可素材。完成后记录实际结果。
