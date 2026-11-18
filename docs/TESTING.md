# 测试、打包与发布

## 0.3.5 统计与筛选

当前专项入口为 `tests/statistics_filters.il` 中的 `lsnRunStatisticsTests()`。仅在独立、已经绑定的只读版图会话中调用。用临时内存记录验证六个菜单项、Pin/Net Open 分离、未放置 Pin 分类、混合 Open/Unverified、全局统计、总线排重、过期结果、零分母、搜索与单网更新后的即时刷新，并恢复原有索引和缓存；不创建、画线、追踪或保存设计。这个专项验证 UI/统计行为，不冒充真实物理连通回归。

最终测试文件在本机 IC25.1 独立只读会话中返回 20 项通过。另在实际保存版图上核对端口/内部网分类和真实 Check selected 的缓存保持，未保存或修改版图。完整记录见 [VALIDATION.md](VALIDATION.md)。

```lisp
load("/path/to/project/tests/statistics_filters.il")
lsnRunStatisticsTests()
```

`tests/status_cache_filters.il` 是 0.3.4 及更早菜单合同的历史辅助，不适用于 0.3.5 的精简菜单。旧 24 项与 PAD 的旧 41 项通过记录仍属于其原版本，不能声称本版已重新全部通过。PAD 回归中首个筛选断言已同步为 Pin Open。

## 0.3.4 PAD 专项

新增 `tests/pad_fixture.il` 和 `tests/pad_regression.il`。这是明确写入的新测试库生成器，只能在独立会话调用，并要求全新 `LSN_DEMO_PAD_` 库名和绝对路径。新库附着到调用者选定的现有工艺，只保存自建测试数据，以实例引用文档指定的真实 PAD；从不保存/修改 PDK 或生产设计。生产目录不能作为测试目标，既有库/目录会被拒绝。

加载这两个文件和最新导航核心后，用 `lsnRunPadTests(newLibName newAbsolutePath techLibName)` 执行。需要已安装的 DBH_ANALOG_PAD 与 PH18C0810_ISO_75；包内不附带商业 PAD 库。41 项在本机通过，包含正向真实接线、负向错误角色/冲突、多个目标/接入面、配置、用户 trace、上层装配和坐标。没有重跑旧全量测试或预测。

下方历史 24 项缓存/分类回归的 Connected Pin 用例，在 0.3.4 需要一个真正接好 PAD 的 Pin。只有内部连通但无 PAD 的 Pin 已不再是可用的 Connected 用例。

其他工艺不要原样执行此 PAD 用例：其接入坐标、金属层和角色针对原 PAD，单换库名不足以迁移。按 [PAD 移植验收](PAD_PORTING.md#移植验收表) 新建自己的小型用例。0.3.4 冻结整理没有重新启动这些原生测试，运行核心摘要保持一致。

0.3.3 已同步现有脚本的 Pin 语义：外部原理图 I/O 不受放置/检查状态影响，内部器件 pin 不属于此类，菜单只有一个 Pin。本次只做这一分类更正和语法检查，未重新运行原生回归；下文 24 项通过记录属于此前的 0.3.2。

## 0.3.2 缓存/筛选回归

`tests/status_cache_filters.il` 是本版新增的针对性只读 UI/缓存检查。在独立、已绑定的只读真实设计中，传入两个当前确实 Open 的网、一个只有标签位置的 Connected 网、一个有未放置 I/O 的单位置网、一个未检查网、一个总线名，以及一个尚未打开的其他现有 cellview 的三元素列表。函数为 `lsnRunStatusCacheTests(openA openB connectedName pinName uncheckedName busName auxiliary)`。第二个 open 网不要求是某一固定设计或版本；不要沿用旧记录假设某条用户已布好的网仍 Open。

此检查会打开指定辅助 cellview 为只读，在本插件缓存内临时构造混合/变更状态并恢复，不画线、不改设计、不保存、不加载预测。模拟修改计数仅发生在比较用的临时表中。必须用独立会话，不应在用户工作面板里运行。

当前保存版图的独立会话中 24 项通过，涵盖重复单网重查、额外视图打开、保留旧状态和新鲜度、所有新增类别/原分类、名称搜索组合、过滤时保留选择、混合类别和状态变化后离开当前列表。旧 0.3.1 的额外视图打开触发整表清空已先行复现。没有重跑预测或旧全量测试。

版本说明：下列原配置/合成测试来自 0.3.0 基线。0.3.1 本轮只对当前 EEPROM 和源 I/O 问题作了独立只读核对，没有重跑这些全套测试或预测测试；不能把历史通过数量当作本版新一轮验收。实际用例与当前限制见 CHANGELOG 和中文版 README。

## 测试分层

1. **配置测试**：不创建数据库，验证默认值、布尔 nil、单位参数、名称规则和错误配置的拒绝。
2. **合成版图测试**：显式新建独立 demo library 和原创的简单技术层，验证版图已有 pin、旋转/镜像坐标、标签锚点、layer map 和模块范围回退。
3. **真实环境集成验收**：在有实际源引用与绑定的设计上验证逐点导航。公开包不包含私有设计，不能仅凭前两层声称所有源绑定场景已通过。
4. **发布包检查**：检查必需文件、文档链接、隐私路径和意外设计数据，生成 ZIP、文件校验清单及 ZIP 校验值。

## 1. 配置测试

在已有 Virtuoso 会话中先加载运行文件，再加载测试文件。示例路径必须替换：

```lisp
load("/path/to/signal_navigator.il")
load("/path/to/project/tests/config_smoke.il")
lsnRunConfigTests()
```

成功时返回 15 个检查名称并打印 PASS。测试使用临时配置表，结束后恢复原配置和配置状态标记；不创建库或设计对象。

## 2. 独立合成版图

这是**可选的写入测试工具**。主运行脚本不会调用它。它会注册一个新 demo library 并创建少量技术数据和版图；必须在新工作目录、独立 `cds.lib` 的 Virtuoso 中执行，避免向正常项目添加示例库。

Linux shell 示例，保持 `CDSHOME` 按站点环境设置：

```bash
LSN_DEMO_DIR=$(mktemp -d /tmp/lsn-demo.XXXXXX)
cd "$LSN_DEMO_DIR"
printf 'INCLUDE $CDSHOME/share/cdssetup/cds.lib\n' > cds.lib
virtuoso
```

在这个独立会话的 CIW 中：

```lisp
load("/path/to/signal_navigator.il")
lsnResetConfig()
load("/path/to/project/tests/config_smoke.il")
load("/path/to/project/tests/demo_fixture.il")
lsnRunConfigTests()
demoWin=lsnCreateDemo("LSN_DEMO_NAV" strcat(getWorkingDir() "/LSN_DEMO_NAV"))
lsnRunDemoTests(demoWin)
```

生成器只接受以 `LSN_DEMO_` 开头的新库名和绝对路径，目标库或目录已存在则拒绝运行。不要删除或覆盖原测试目录来强行重复创建；可以换一个新目录和新库名。示例不借用、复制或修改 PDK。

合成测试使用默认配置。上述 `lsnResetConfig()` 只在独立测试会话中调用，清除个人自动加载配置（包括 sourceOverride），避免测试结果受个人层映射、回退开关或源引用影响。

成功时返回 12 个合成检查名称，设计窗口以只读方式打开。该示例故意不建立源原理图或实例绑定：已有 pin 的 UI 路径直接测试；标签/层映射/模块回退通过定位引擎直接测试。它不证明某个版本的 XL binder 或许可可用。

默认创建三个 cell：模拟 pin master、只有几何/标签的数字 master 和顶层版图。数字侧 `CTRL[0]` 在 M2 上，`CTRL[1]` 在 M2TXT 上，可用于对比 layer map 的效果。没有任何器件模型、工艺规则或仿真数据。

示例技术数据包含自己的制造网格和合法连接层定义。打开测试窗口时，辅助脚本临时指定该示例的约束组，并恢复原有的进程设置。这些操作只属于显式调用的测试辅助工具，不在导航运行文件中。

测试不自动删库。确认检查完成后，可以退出独立会话，再按生成时记录的精确目录自行清理该 demo 工作区；不要对共享设计根目录执行删除。

## 3. 目标站点的集成验收

选代表性小设计或按只读方式打开保存版本，记录以下结果：

| 检查 | 通过条件 |
|---|---|
| 目标窗口 | Layout 指向正确版图，多窗口时无随机跳转 |
| 源关联 | Schematic 指向实际源，不要求与版图同名 |
| 正式端口 | 定位到真实 pin 图形，而非整网包围框中心 |
| 手动循环 | 每次按钮只前进一步，末尾循环，反向也正确 |
| 旋转/镜像 | 用独立计算或已知坐标核对，不能只比较脚本自身两个输出 |
| 标签回退 | 由版图 instTerm 或源绑定确认所属实例，在其中找到锚点，Status 为 label 类型 |
| 纯模块回退 | 没有标签时适配所属模块，Status 不冒充 pin |
| 未放置实例 | 没有绑定的源端点保持缺失，不猜坐标 |
| 总线 | 位名、顺序和每位的候选符合实际 |
| 更新 | 移动后坐标更新；标签增删改名后刷新生效 |
| 清理 | Clear/Close 只清理本插件标记，设计内容未被保存或更改 |

配色初始化允许短暂临时文件写入；检查其初始化后已删除，不把“只读设计”误解为完全没有任何文件系统写入。

## 4. 当前验证记录

见 [VALIDATION.md](VALIDATION.md)。它区分实际运行、私有设计集成与未测试版本，不将函数存在检查当作完整兼容证明。

## 5. 构建发布包

运行脚本本身无需 Python。只有维护者选择使用下列打包工具时，才需要 Python 3.9+，且仅用标准库：

```bash
python tools/package_release.py --check-only
python tools/package_release.py --output dist/virtuoso-signal-navigator-0.3.5.zip
python tools/verify_release.py dist/virtuoso-signal-navigator-0.3.5.zip
```

工具采用显式文件/目录白名单，不把临时运行结果或任意整个工作区装入 ZIP。包内包含 SHA256SUMS，ZIP 旁另有 `.sha256` 校验值。0.3.4 还核对 [RELEASE.md](../RELEASE.md) 中固定的运行核心摘要。输出 ZIP 或其校验文件已存在时拒绝覆盖，应保留旧包，选择一个新输出路径。

打包范围为根目录的固定说明文件，以及 `src/`、`docs/`、`examples/`、`tests/`、`tools/` 下允许后缀的文本文件。工具不读取 `.gitignore`，但会拒绝任何 `*.local.il` 文件。个人配置及私有设计资料应放在这些公开目录之外；Git 忽略规则不能替代发布内容审阅。

该检查能发现常见误带文件和本机路径，不能代替维护者对新增内容的人工审阅。公开前确认自己的作者/贡献者信息和拟发布范围；MIT 许可证已随源码及根目录提供。

解压后在根目录可用 `sha256sum -c SHA256SUMS` 检查各文件。平台差异导致没有该命令时，也可用标准 SHA-256 工具核对。

`verify_release.py` 不解压文件，会核对每个成员的路径、清单与 ZIP 的准确文件集合、每个文件摘要、固定运行核心和 MIT 许可。相邻 ZIP `.sha256` 存在时一起验证；不在时会明确说明只验证内部清单。校验用于发现损坏或与已有摘要不一致，不是作者签名。

## 6. 外部发布

本项目目录可直接作为新的 Git 仓库根目录，也可分发生成的 ZIP。打包工具不创建远程仓库、不上传、不推送、不发布 release。发布账号、仓库名、作者署名及公开提交由维护者决定。
