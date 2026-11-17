# CrossDemo 测试报告

## WIN-001：计划

上传前结果：本机Qt6.11.1 Release及QSB重新构建通过，移除强制Metal后默认后端的17项GPU检查通过，CTest 1/1、2.32秒。Ruby标准YAML解析Windows workflow结构通过；三份Mac build.sh的bash -n通过。独立Git暂存35文件，diff --cached --check通过，清单排除app、签名／本地配置、缓存及旧wallpaper.png。

Windows源码／PowerShell／部署流程尚待首次Actions真实执行；不能把本机检查写成Windows构建通过。以下为开始时的计划。

待执行本机macOS跨平台源码构建／GPU回归、Actions Windows Release构建、Qt/QML与VC运行库部署、部署后GPU像素对照与zip检查。云端自检仅用于渲染正确性，用户实际Windows观感、DPI、驱动／性能未验证。
