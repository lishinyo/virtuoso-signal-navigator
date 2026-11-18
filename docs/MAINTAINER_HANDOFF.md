# 0.3.5 维护与接手说明

更新日期：2026-11-18。0.3.4 固定包保留；0.3.5 添加统计与 Open 分类。先读 [RELEASE.md](../RELEASE.md)、[PAD 移植指南](PAD_PORTING.md) 和 [实现结构](ARCHITECTURE.md)。当前运行核心的校验值记录在 RELEASE.md；打包工具会核对它。

## 产品要求与已实现功能

最初需求是在很大版图中按网络名、端口名查找信号：点击后居中到接入点，逐次按钮循环、反向访问、整体高亮及逻辑连线。标签线索和模块范围必须明确区分，不能假装已经找到正式 pin。现已包括搜索、排序、总线展开、旋转/镜像坐标、只读标签/金属定位和未放置提示。

0.3 主线随后加入物理连接分组、最后一列的完成状态、缺失端点与只轮询待连接位置；原理图总线端点及导入模块的层级金属定位已修正。Check selected 仅替换所选网缓存，其他结果保留；真实修改后保留旧结论并标 needs recheck。0.3.5 的 Show 为 All / Pin / Nets / Pin Open / Net Open / Unverified。

0.3.5 顶部统计分别显示整个绑定版图中 Pin / Nets 的标量总数、有效完成数与比例、Open、Unverified 和 Pending，排除总线聚合。统计不受搜索筛选影响，不自动检查。Open 与 Unverified 可重叠；过期结果归 Pending，不能抬高完成率。原用户要求移除的是 Show 里的 Connected/检查状态选项，检查按钮和最后一列的详细状态保留。

Pin 的用户含义固定为“关联原理图中需要后续接 PAD 的顶层 I/O”，与正式 layout pin、是否放置以及端口方向无关。模块内部器件 pin 不属于这个筛选。不要重新拆出 Pin not placed / Physical pin 子分类。

0.3.4 将内部连通与 PAD 义务分离。只有所有核心端点和全部必需 PAD 核心目标接通才 Connected；没有 PAD 时保持待接。PAD setup 支持真实实例列表、允许角色、显式多目标、可靠自动意图、冲突检查、定位、父级装配、配置保存恢复。一个端子的多个等价图形按 OR；多个必需目标按 AND。只有小型 I/O pin 图形不代表已经连 PAD。

曾探索的 0.4 路径预测已经放弃，本项目不包含或加载该模块。不要把逻辑总览亮线描述为推荐走线路径。

## 目录与运行结构

| 路径 | 用途 |
| --- | --- |
| `src/signal_navigator.il` | 唯一必需运行文件；lsn 为导航、lsnc 为物理连接、lsnp 为 PAD |
| `examples/config.il` | 通用导航配置 |
| `examples/site_config.template.il` | 工艺/PAD profile 的适配模板 |
| `examples/design_targets.template.il` | 每个设计的显式范围与目标模板 |
| `docs/PAD_CONNECTION.md` | 当前 PAD 界面和 API |
| `docs/PAD_PORTING.md` | 不同 PDK/PAD 的移植方法和边界 |
| `docs/VALIDATION.md` | 区分各版的实际验证记录 |
| `tests/` | 可选配置、合成版图、缓存和原 PAD 集成用例 |
| `tools/package_release.py` | 固定摘要、内容审计、确定性 ZIP 和清单 |
| `tools/verify_release.py` | 核对解压路径、清单、ZIP 摘要和固定核心 |

安装不依赖 Python/Bridge/WSL。物理状态依赖目标环境的原生 physical trace 及许可。脚本读设计而不保存设计，只能删除自己创建的 trace，不能清除用户的既有 trace。用户明确 Save config 才持久写对应文件；配色另有短暂临时文件写入。

同一文件中存在为兼容早期导航而保留的基础定义，后部的增强定义才是最后生效的实现。不要只读最前面的同名函数就改动。PAD 段由 `BEGIN PAD SUPPORT` 标出，但运行时没有外部源文件生成步骤；发布维护直接以这个完整文件为准。

## 验证和已知边界

原 0.3.0 配置/合成测试、0.3.2 的 24 项缓存筛选测试、0.3.4 的 41 项 PAD 专项是不同日期的记录，不叠加声称为本次全量回归。冻结整理只运行文本、固定摘要和包完整性检查，不重复启动 EDA 或测试生产设计。

0.3.5 新增的 `tests/statistics_filters.il` 在 IC25.1 独立只读会话中 20 项通过，另核对代表性真实网络的分类、Check selected 缓存保持与修改计数不变；这不是重新运行完整 PAD 或旧全量用例。原生测试不得借用用户的活动工作会话。

0.3.4 PAD 用例引用站点已安装的真实 PAD，不附带库数据；其他工艺必须设计自己的接入坐标与负向用例。纯通用合成测试不覆盖 PAD 语义。Connected 含推断落点时仍带星号；未知几何、未知 PAD、扫描限制和不支持的阵列必须保留未知。

## 移交到另一台机器

1. 解压公开 ZIP，校验文件；保留解压出的 LICENSE 和源文件内 MIT 声明。
2. 在目标 Linux/Virtuoso 环境读取自身 PDK，按移植指南制作 `site.local.il`。
3. 运行核心、载入站点配置、绑定正确核心；用界面或 `design.local.il` 指定目标。
4. 新机器已有设计库应单独迁移或引用；公开 ZIP 不包含设计、PDK、cds.lib 或许可证。
5. 完成站点验收后再用于正常布局导航。不要把已保存的旧工艺 profile 当作新工艺的事实。

## 备份和回退

私有冻结备份包含 `workspace-project/`、`installed-project/`、`installed-entry/load.il`、此前精简交付记录，以及逐文件摘要的 `BACKUP_MANIFEST.json`。它保存整理前的精确字节；公开 ZIP 是补齐移植资料后的可分发工程。两者用途不同，私有备份中可能含本机路径和开发记录，不应上传。

需要恢复时，先把私有 ZIP 解压到一个新目录并核对清单，保留现有安装作为另一份副本，再选用旧源文件加载。`installed-entry/load.il` 中的原机绝对路径只适合原机，换机器必须改为目标 Linux 路径。无需恢复 PDK 或覆盖设计库；该备份也不包含这些内容。

## 后续维护约定

0.3.4 是保留的固定版本；本工作树继续开发为 0.3.5。工艺差异优先通过站点 profile 和设计对应解决；运行行为改变需更新版本与摘要，保留历史发布包和备份。提交问题使用原创小例子，不带真实设计、PDK、商业文档或个人配置。贡献许可沿用 MIT。
