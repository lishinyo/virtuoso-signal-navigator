# Virtuoso Signal Navigator

版本：0.3.5（只做导航，继续 0.3 主线）。许可证：[MIT](LICENSE)。[English overview](README.md)。

## 0.3.5：统计与分开的 Open 筛选

顶部统计分别显示原理图 Pin 与内部 Nets 的 Total、Connected 数及完成比例、Open、Unverified、Pending。统计覆盖整个当前绑定版图，不随 Find / Show 改变；总线聚合行单独计数，不和标量位重复累计。过期、未检查和只有单位置而无完成依据的记录进入 Pending，不提高完成率。Open 与 Unverified 可以重叠，不能把所有状态列直接相加。

Show 精简为 **All / Pin / Nets / Pin Open / Net Open / Unverified**。Pin Open 包含未接 PAD 的原理图端口；Net Open 只看内部网络。Connected、Not checked、Needs recheck、Single location 和 Bus 不再作为菜单选项，详细状态仍显示在最后一列。统计和筛选均不启动物理检查、不改变选择或其他网缓存。

## 固定版本与其他环境移植

0.3.4 的固定发布包、备份和已安装版本保留；0.3.5 是其上的独立更新，参见 [发布说明](RELEASE.md)。运行不需要 Python、Bridge 或 WSL；只使用目标环境已有的 Virtuoso、许可、PDK 和设计。

其他版图的 PAD 可以不同：用 [工艺配置模板](examples/site_config.template.il) 定义真实金属层、准确 PAD 库/单元及核心端子，再用 [设计对应模板](examples/design_targets.template.il) 或 PAD setup 指定具体实例。不必修改核心脚本。内建 PAD 是特定环境的参考适配，不能直接当成通用规则；配置能覆盖的结构和暂不支持的情况见 [PAD 移植指南](docs/PAD_PORTING.md)。两个模板均带保护，需替换示例并移除保护行后才加载。

交给另一台电脑或维护者时，先阅读 [维护接手说明](docs/MAINTAINER_HANDOFF.md)。公开包含完整源码、MIT 许可、文档、模板、可选测试、打包和校验工具，不含真实设计或商业库。冻结前的本机备份单独保留。

## 0.3.4：Pin 必须包含 PAD 接入才算完成

原理图顶层 Pin 的内部端点连通后，若尚无 PAD，最后一列显示 **Internal connected | PAD pending**，不再进入 Connected。存在 PAD 但没有可靠对应时显示 PAD unassigned；已对应但未接通显示 PAD unconnected；无法确认时显示 PAD unverified。只有所有核心端点和全部指定 PAD 核心端子均已物理接通，才显示 Connected (including PAD)。含标签/导入接入点假设时保留星号。

第二步也已实现：**PAD setup / connection targets** 可查看真实 PAD 实例、选择允许的核心侧端子、添加/删除必需目标、定位端子、选择上一级 PAD 顶层及核心实例路径、保存/加载对应配置。可从真实 layout instTerm 或原理图绑定自动取得意图；GDS 没有这些信息时由用户明确对应，不按名称相似或距离猜测。一个 Pin 可以有多个必须接通的 PAD；一个双向 PAD 的不同端子也可以分配给不同逻辑 Pin。

内建参考适配包括 DBH_ANALOG_PAD 的 IOPAD/VDDPAD/GNDPAD 和 PH18C0810_ISO_75 的 I/Z/OEN/IE/DS。GPIO 的外部 PAD 端和电源/ESD 环不作为这些信号的核心端子。版图尚无对应 PAD 时，插件只提示待接，不替用户放置 PAD 或画线。

完整操作、角色定义、上层顶层及配置接口见 [PAD 接入说明](docs/PAD_CONNECTION.md)。Show 仍只有一个 Pin 分类；普通内部 Nets 的判断不变，0.3.2 的单网缓存修复保留。

## 0.3.3：Pin 指需要连接 PAD 的原理图 I/O

Show 统一使用 **Pin**，按当前关联原理图的顶层 terminal 定义筛选，包含输入、输出、双向端口及总线各位/聚合行。无论版图是否放置 pin、是否已检查、是否已接通，都属于 Pin。模块内部的引脚或仅在版图生成的端口不会因此被算作顶层 Pin。

已移除 Show 中的 Ports、Pin not placed、Physical pin 分类，Nets 表示其他内部网络。位置表仍可说明有没有版图位置、正式 pin 或标签，连接状态也照常显示；这些物理细节不再拆成 Show 的 pin 类别。没有原理图引用时无法确认 Pin，不根据版图图形猜测。

## 0.3.2：单网更新与状态筛选

修复 Check selected 将其他导线状态重置的问题。现在强制检查只替换当前网络的缓存记录；物理追踪或只读打开其他单元不再触发整表清空。其他已检查结果保留，尚未检查的项目仍显示 Not checked。

版图/相关已打开单元的修改计数确有变化时，保留旧结论并附加 `[needs recheck]`；再次选择或轮询该网络会重新检查。修改计数采用保守快照，其他已打开单元的修改或关闭也可能要求重查，但不会删除旧结果。只有显式 Refresh、重载脚本或切换绑定设计/检查配置时重建缓存。

连接状态使用缓存中的结构化标记筛选，Pin 使用原理图顶层端口定义。改 Show 不启动物理检查，也不自动选择另一条网络；Find 与 Show 同时生效。0.3.5 当前菜单如下：

| Show 选项 | 含义 |
| --- | --- |
| All / Pin / Nets | 全部 / 原理图顶层 I/O / 其他内部网络；Pin 不依赖版图放置状态和检查缓存 |
| Pin Open | 原理图顶层 I/O 存在断开、待接 PAD 或已指定但未接通的 PAD 目标 |
| Net Open | 其他内部网络存在多个物理孤岛 |
| Unverified | 已检查且有物理端点/位置无法确认 |

Pin 可以同时具有 Open 和 Unverified 等连接状态。过期结果仍可按其上次状态筛选，并附 needs recheck；统计中的完成率只使用有效结果。按状态筛选后列表为空，只表示已有结果没有匹配项；可先用 All 检查，再切状态筛选。Pin 分类本身不需要先做检查。

## 0.3.1：原理图 I/O 与 EEPROM 改进

- 修复原理图总线端口只挂在聚合 net 上、读取单个位时漏掉模块端点的问题。总线按原理图声明顺序逐位对应，不按位号或同名模块猜测。
- 标签下的接入金属支持向下查询普通实例层级；EEPROM 顶层只有标签、金属在子单元内的端口现在可以定位。
- 表中显示原理图 IN / OUT / INOUT；顶层已有端口标签但没有正式 layout terminal 时，可以按标签定位。没有任何版图位置的 I/O 明确显示 `I/O pin not placed`，与 `Unverified` 分开。
- 保留连接状态、待连接位置、Previous / Next 和 `Unconnected / pending only`，忽略原理图 `basic/noConn` 的物理端点。
- 原生连接检查已经合入单文件，不加载 0.4 的预测、占用提取或 Python 求解模块。原 0.3.0 发布 ZIP 保持不变。

位置表的 `I/O direction` 来自原理图时标记 `(sch)`，只在版图有定义时标记 `(layout)`。符号本身若把端口定义为 INOUT，界面按原定义显示，不猜测 EEPROM 某个控制脚应为输入。

连接检查按 MET1–MET6 金属/通孔追踪，默认 `lsnHintDepth=32`（标签金属搜索）、`lsncStopLevel=64`（追踪层级）、最多 256 个位置和 64 次分量追踪。其他工艺加载前设置 `lsncStackLayers=list("M1" "M6")` 等真实层名。原生 physical trace API/许可不可用、只有模块范围或确无导体等情况仍显示 Unverified；不能仅凭原理图 I/O 定义把物理未知改成已接通。

`Connected*` 含标签端点假设。`Internal connected; I/O unplaced` 仅表示已找到的内部位置连通，外部 pin 仍缺失，不算整网完成。有坐标的待连接项可以过滤轮询；未放置 I/O 没有坐标，保留说明，不编造位置。

实际修改版图后按 Check selected 重查；命名、绑定或层级变化后按 Refresh 重建原理图和标签索引。Check list 只处理当前筛选的列表，Stop 停止后续队列，不能中断正在执行的单次原生追踪。

这是一个面向大规模 Virtuoso 版图的信号导航脚本：按名称查找网络和端口，逐个访问已有接入位置，并显示逻辑连接总览。

即使导入的数字模块没有正式 terminal/pin 对象，只要能够确认所属实例，且模块内保留了同名文字标签，也可以提供标签锚点；标签也找不到时，还能定位该实例的模块范围。不同依据会明确区分。

## 最快开始

只需复制一个运行文件：[src/signal_navigator.il](src/signal_navigator.il)。它必须位于运行 Virtuoso 的 Linux 主机可读取的目录中。

在 Virtuoso CIW 输入以下命令，将示例路径换成实际位置：

```lisp
load("/path/to/signal_navigator.il")
lsnStart()
```

先激活目标版图窗口。面板出现后，搜索信号，点击名称，再点击 **Next pin >** 逐点访问或 **Overview** 查看整体。

多个版图窗口同时打开、又没有当前有效版图时，脚本会要求明确选择，不按某个固定 cell 名称猜测。可用 `lsnStart(window(n))` 指定目标窗口，`n` 替换为窗口编号。

## 定位依据

| 状态 | 含义 | 能否当成正式连接证明 |
|---|---|---|
| Physical pin | 读到了正式 pin 的实际图形 | 表明该 pin 图形存在，仍不等于整条网已布通 |
| Label + metal | 同名标签锚点附近有同层或配置映射层的金属 | 只能作导航线索 |
| Label anchor | 找到标签，未找到满足查询条件的金属 | 只能作导航线索 |
| Block only | 仅确认了所属实例，可定位整个模块范围 | 不能当成端口位置 |
| 编号 0 的行 | 没有可提供的位置，原因显示在 Status 中 | 不作坐标猜测 |

正式 pin 使用黄色标记和青色逻辑线；标签与模块线索使用橙色标记及虚线。关闭自定义配色或配色初始化失败时，颜色依赖当前显示资源，**以 Status 文字为准**。

## 完整文档

1. [安装、升级与卸载](docs/INSTALL.md)
2. [详细使用说明](docs/USER_GUIDE.md)
3. [移植与配置参考](docs/PORTING.md)
4. [常见问题与排错](docs/TROUBLESHOOTING.md)
5. [兼容性与验证范围](docs/COMPATIBILITY.md)
6. [实现结构与扩展方法](docs/ARCHITECTURE.md)
7. [测试、打包与发布](docs/TESTING.md)
8. [PAD 工艺适配与移植验收](docs/PAD_PORTING.md)
9. [维护与接手](docs/MAINTAINER_HANDOFF.md)

## 运行条件与边界

运行脚本不需要 Python、Bridge、WSL、服务器或另一个 `.drf` 文件；它运行在现有 Virtuoso 进程中。主机需要具备文档列出的 API，以及使用相应 Virtuoso 功能的许可。已实际验证 IC25.1；其他版本尚不能称为已适配。

默认列出当前编辑层级的顶层端口与直接实例，支持实例旋转、镜像和坐标换算；标签接入查询可进入其普通子实例。物理连接检查要求顶层编辑坐标，edit-in-place 显示无法确认。没有全芯片递归逻辑端口枚举、阵列元素展开、自动画线、自动建立 pin 或 LVS 检查。

脚本不写设计数据库、不保存设计或更改 PDK。初始化独立配色时，会短暂写入一个临时文件，加载其显示资源后删除该文件。关闭面板用 `lsnClose()`；函数定义保留到本次 Virtuoso 会话结束。

本项目提供可公开复制的源代码、文档和通用测试。测试库生成器是单独、可选的开发辅助工具，会在调用者明确指定的新目录中创建示例数据；不会随主脚本加载而运行。
