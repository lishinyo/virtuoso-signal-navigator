# Release: 0.3.5

更新日期：2026-11-18。许可证：[MIT](LICENSE)。本目录是可独立分发的项目根目录。历史固定版 0.3.4 的 ZIP、备份和安装目录保留。

```text
runtime-version: 0.3.5
runtime-sha256-lf: 5c5823c7bf2ec026718febeeb8d02f66e6300596eb4c8c2e435d9789f442eac1
```

本版在 0.3.4 上新增统计与 Show 精简：Pin / Nets 的全局标量总数、有效完成数与比例、Open、Unverified 和 Pending；Show 为 All / Pin / Nets / Pin Open / Net Open / Unverified。其他物理连接与 PAD 规则沿用 0.3.4。上面的摘要针对 `src/signal_navigator.il` 的 UTF-8、LF 内容，发布工具据此拒绝运行脚本被无意修改的包。后续修改应更新版本与摘要，保留历史包。

## 内容和依赖

- `src/signal_navigator.il`：单文件运行核心，包含导航、原理图端口、连通状态与 PAD 检查。
- `examples/site_config.template.il`：其他工艺的层名、PAD 单元及核心端子 profile 模板。
- `examples/design_targets.template.il`：具体设计的范围和网络到 PAD 核心端子对应模板。
- `docs/`：安装、使用、适配、验收、维护交接说明。
- `tests/`：可选测试；PAD 的 41 项集成测试依赖文档列出的站点 PAD，不能原样用于任意 PDK。
- `tests/statistics_filters.il`：20 项针对 UI、内存缓存与统计语义的专项用例，不创建或保存设计。
- `tools/`：只用 Python 标准库的发布和校验工具；运行插件不需要 Python。

运行需要目标站点自己的 Virtuoso、相应许可、PDK 和设计库。默认 PAD profile 是准确库名/单元名匹配的参考适配，并非通用 PAD 规则。其他 PAD 通过独立配置注册，参见 [PAD 移植指南](docs/PAD_PORTING.md)。本包不含商业库、生产设计、真实设计截图、个人路径、Bridge 或路径预测模块。

## 使用顺序

1. 按 [安装说明](docs/INSTALL.md) 加载运行脚本。
2. 根据新站点修改并加载工艺配置，再 `lsnStart()` 绑定目标版图。
3. 用 PAD setup 指定实际目标，或加载修改后的设计对应文件。
4. 按 [移植验收表](docs/PAD_PORTING.md#移植验收表) 核对实际位置与状态。

0.3.5 的 20 项 UI/统计专项已在 Virtuoso IC25.1 独立只读会话中全部通过，另在代表性实际版图中核对两类 Open、单网更新保留其他缓存、修改计数与 trace 集合不变。41 项完整 PAD 通过记录仍属于 0.3.4，本版未重跑它。发布阶段另核对源文件摘要、文档、SKILL 文本结构、打包内容及压缩包校验；详见 [验证记录](docs/VALIDATION.md)。

## 分发与恢复

ZIP 内含 `SHA256SUMS`，ZIP 旁有独立 `.sha256`。可以用 `python tools/verify_release.py /path/to/package.zip` 校验。开源包可作为新 Git 仓库的根目录，或直接复制运行文件与本地配置；制作发布包不会自动上传。

0.3.4 的工作区工程、已安装工程和原启动入口另有本机私有 ZIP 备份。该备份不属于公开包，也不备份 PDK、生产版图或未保存的界面状态。恢复方法见 [维护接手说明](docs/MAINTAINER_HANDOFF.md)。
