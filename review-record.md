# CrossDemo 审查记录

## WIN-001：计划

上传前主审：单面板CMake只在Apple启用OBJCXX/AppKit，MSVC使用UTF-8和W4/WX，移除强制Metal。Windows辅助只读SystemParametersInfo和EnableTransparency；玻璃算法与QML保持。Actions固定依赖commit、contents只读，部署VC CRT与QML，移除SDK路径后复测；WARP作为CI渲染环境不冒称实体GPU性能。自检失败阻止成功产物上传。

审查35文件清单：仅Demo源码、独立六文档和自生成32KB背景；旧本地壁纸／app／证书／父工程配置均忽略。Mac脚本兼容父工程并支持独立签名环境变量。云端编译／部署及Windows效果尚未确认。

核对Qt单面板平台条件、Windows辅助设置公开读取、默认后端、MSVC、部署与自检、Actions权限／固定依赖及Git上传内容。只提交Demo源码／文档／自有素材，排除构建包、真实配置与未确认许可素材。完成后记录实际结果。
