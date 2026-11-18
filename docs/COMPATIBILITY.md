# 兼容性与验证范围

0.3.4 固定发布补充：PAD 适配可通过独立 profile 与设计配置完成，不要求使用内建 PAD。当前支持正式 terminal、同一 PAD master 的准确标签加落点金属、或符合条件的被动开口加金属。其他工艺必须按 [PAD 移植指南](PAD_PORTING.md) 验收；未知结构不能凭 profile 名称成为已连接。

0.3.1 补充：总线逐位映射要求 `dbProduceMemName`，层级金属查询要求 `dbGetTrueOverlaps` / `dbConcatTransform`。物理连接状态另依赖原生 `lntAddTrace` / `lntGetTraceInfo` / `lntRemoveTrace` 及许可；不可用时仍保留导航并标记无法确认。连接检查限顶层编辑坐标。此前 0.3.0 的全量测试记录不是本版的新一轮全量测试，也没有新增其他 Virtuoso 大版本的兼容承诺。

## 已知环境

| 环境 | 当前状态 |
|---|---|
| Virtuoso IC25.1，Linux 图形会话 | 已进行实际运行验证 |
| AlmaLinux 10.2 / WSL2 上的该安装 | 本项目的一个实际验证环境；不等于 Cadence 官方支持声明 |
| 原生 Linux 的其他发行版 | 待按目标安装和设计验收 |
| IC6.1.x、ICADVM、IC23.x 等其他版本 | 未实测，不宣称已兼容 |
| 原生 Windows Virtuoso | 未测试，项目按 Linux 主机环境说明 |
| 纯 nograph、无图形窗口 | 无法显示导航面板 |

项目不附带或替代 EDA 软件许可证。安装中具有某个函数名，不保证相应产品许可、模式及运行行为可用。

## 必需能力

`lsnCheckEnvironment()` 列出关键 UI、窗口、数据库和高亮接口，包括：layout form、report field、dock window、明确的图形窗口、视野平移缩放、窗口高亮集、pin/net/term 读取、图形相交查询和坐标变换。

所有调用仍依赖目标安装的核心 SKILL 语言及常规 UI 支持；该检查是关键能力检查，不是完整 ABI 或许可证测试。出现 undefined function 时，先查目标版本安装手册，确认名称和参数再移植。

## 可选能力和降级

| 能力 | 可用时 | 不可用时 |
|---|---|---|
| lxGetSchematic | 取得实际源引用 | 使用显式 sourceOverride，或只浏览版图已有网络 |
| bndGetBoundObjects | 源到版图实例/端点对应，支持标签回退 | 依赖已有版图 terms/instTerms；源端点可能无法定位 |
| drLoadDrf + makeTempFileName | 初始化独立配色 | 使用现有 y0/y1/y2 高亮层 |
| 可写临时目录 | 正常加载配色后清理文件 | 配色降级，Status 仍有效 |

没有 docking API 时当前不提供另一套 UI 自动降级；核心检查会阻止打开不完整面板。

## 明确限制

- 当前编辑层级和直接实例；没有全芯片所有层级的端点递归列表。
- 不展开 mosaic 的 row/column 索引，也不承诺复杂多对多绑定的完整覆盖。
- 标签文字检索限定所属 master，不递归查任意子 master 的文字，也不解析任意 textDisplay 的动态内容；命中标签后的实际金属查询可以进入普通实例层级。
- 仅简单括号兼容；不自动推断别名、网名重命名、总线位交换或名称大小写等价。
- 临近金属检查是几何线索，不是版图提取或网络归属证明。
- 单进程一个活动面板；配置/刷新/重开会重置导航状态。
- 编辑事件不后台监听；新增、删除、改名标签后需要 Refresh。
- 面板尺寸、字体和显示效果受远程桌面、DPI 和用户资源设置影响。
- PAD 定位策略只覆盖已描述的结构；不同 purpose 的 bond 开口、复杂 bump/RDL、无可靠端口或标签的 wrapper、混合独立 bond 域等不承诺仅靠配置适配。
- `lsnCheckEnvironment()` 是关键 API 存在检查，不完整覆盖 PAD 的每次调用、实际许可或正确工艺栈；应完成目标站点的负向/正向连通验收。

完整的移植验收见 [TESTING.md](TESTING.md)。
