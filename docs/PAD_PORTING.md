# 在其他工艺与版图中适配 PAD

适用于固定版 0.3.4。运行核心保持原样，工艺信息放在站点配置，实例对应放在设计配置。无需 WSL、Python 或 Bridge 来运行；这些只是开发环境选项。

## 先明确三层信息

| 层次 | 内容 | 更换时机 |
| --- | --- | --- |
| 通用核心 | 导航、原理图 Pin、连通追踪、状态、窗口和坐标变换 | 升级插件版本 |
| 工艺/站点配置 | 金属上下界、文字层映射、准确 PAD 库/单元、可连接核心端子与定位策略 | 更换 PDK、PAD 版本或层定义 |
| 设计配置 | 原理图引用、核心 occurrence、具体 PAD 实例、每个标量 Pin 的必需目标 | 更换设计、装配层级或 PAD 分配 |

内置 DBH profile 只针对已经核对的准确库/单元名，缺少这些库不妨碍脚本加载。它们不是可套用到其他 PAD 的默认功能定义。相同名称在另一工艺中也可能代表不同版本，必须重新核对，并用同一库/单元的 `lsnPadRegisterProfile()` 覆盖定义。只认准确名称，不按 PAD 字样、外形、距离或相似端口名猜测。

## 需要从目标环境取得什么

1. 技术数据库中的实际金属层名、上下界、通孔/连接栈及本机原生 physical trace 的可用性。`lsncStackLayers` 是下界和上界两个名字，不是逐层清单，不是 GDS layer number。
2. 设计的 user unit 和 DBU 精度。`unitLabel` 只改显示文字，不转换坐标。
3. 每种 PAD 的准确 library/cell、核心端子与外侧键合端的功能，以及供电、地和控制端所属域。
4. layout 中是否有正式 terminal/pin figures；若没有，是否有准确核心端子 label，以及 label 下真实导体。
5. 被动 bond PAD 是否有能代表该核心角色的开口层，开口是否为 `drawing`，以及其下真实金属层。
6. PAD 在核心内还是父级装配中，实际实例路径，以及源原理图是否有可靠的 instTerm / binder 信息。

symbol 方向不能代替电路功能检查。缓冲 GPIO 的核心输入和核心输出是不同逻辑端子，不能直接把外部大 PAD 当作所有信号的目标。电源、地、ESD 环也不能被当作普通信号接入面。

## 配置流程

将 [工艺模板](../examples/site_config.template.il) 和 [设计模板](../examples/design_targets.template.il) 复制到公开工程之外，分别命名为 `site.local.il` 和 `design.local.il`。替换示例、删除不使用的段落后，移除各自开头的保护性 `error(...)`。未修改的模板会明确停止，避免被当成已适配配置。

在 Virtuoso 所在 Linux 的 CIW 中，按顺序执行；路径全部替换成自己的真实路径：

```lisp
load("/path/to/project/src/signal_navigator.il")
load("/path/to/private/site.local.il")
lsnCheckEnvironment()
; 先激活目标核心版图
lsnStart()
; 先确认面板的 Layout / Schematic，再载入具体设计对应
load("/path/to/private/design.local.il")
```

也可以只加载工艺配置，再用 **PAD setup / connection targets** 人工建立设计对应。请在开始检查前完成 profile 配置。换到另一 PDK/项目时推荐新开 Virtuoso 会话，避免保留旧 profile、scope 或显式绑定；`lsnResetConfig()` 只重置导航选项，不会清空 PAD profile 或所有 PAD 对应。

`lsnpDedicatedPadLibraries` 用来指出“整个库都是 PAD”的专用库。新站点可替换成自己的专用库列表，无专用库时可为 `nil`；PAD 与普通模块混在一个库时，只注册准确 PAD 单元，不把该混合库加入专用列表。未知专用库单元会被报告，不能为消除警告随意把它们注册成信号 PAD。只有填充、拐角、ESD 辅助等无信号核心端子的单元，目前也没有通用的自动忽略认证机制。

## 两种定位策略

### 1. 正式 terminal 或标签下的真实金属

```lisp
lsnPadRegisterProfile("my_pad_lib" "MY_BUFFERED_IO"
  list(
    list("CORE_IN" "label" list("CORE_IN"))
    list("CORE_OUT" "label" list("CORE_OUT"))
    list("OUTPUT_ENABLE" "label" list("OUTPUT_ENABLE"))
  ))
```

描述符格式是 `(核心角色 "label" 标签名列表)`。核心角色必须对应该 PAD master 的真实核心端子；自动逻辑意图也依赖这个真实端子名。角色不是任意网络别名。插件优先读取同名正式 OA terminal 的图形；没有可用图形才查该 master 的准确标签及其真实金属落点。标签可以借助 `labelLayerMap` 映射文字层到金属层，落点查询可进入普通子实例。

标签名列表可用于明确的同义标签或同一端子的多个接入标记。它们必须确属同一核心角色；不是把多个逻辑信号合并。正式 terminal 的多个图形和同一角色的多个接入候选按 OR 处理，验证接通一个即可。因此注册前必须确认它们电气等价；若每个独立焊盘都必须接通，应建成多个必需目标，而不是塞进一个角色的候选列表。

标签搜索目前不递归寻找任意子 master 中的文字，只有金属落点查询支持普通实例层级。若核心端子标签仅存在于深层子单元、PAD wrapper 没有正式端口或标签，此模板不足以适配；保持 Unverified，另开版本扩展读取器。

### 2. 被动 bond PAD 的开口与金属

```lisp
lsnPadRegisterProfile("my_pad_lib" "MY_PASSIVE_PAD"
  list(list("IO" "bond" "PAD_OPEN" "M6")))
```

描述符格式是 `(核心角色 "bond" 开口层名 金属层名)`。当前实现搜索 `开口层名/drawing`，取实际层级开口范围内的金属接入点。适用于已经确认核心角色与键合金属直接导通、所有候选属于同一电位的被动 PAD。

不适用于有缓冲、隔离、串联器件或电平转换的输入输出路径；也不适用于同一 master 含多个互不相关 bond 域、仅有其他 purpose 的开口，或者任意无标签 bump/RDL 几何。不能仅换层名就声称支持这些结构。正式 OA terminal 存在时仍优先用其图形，所以也必须确认正式 terminal 的语义。

## 明确设计对应

```lisp
; 若 PAD 位于父级，先指定准确核心 occurrence；否则省略
lsnPadUseScope("design_lib" "chip_top" "layout" list("WRAP" "CORE"))
lsnPadBind("DOUT<0>" list("PAD_RING" "U_IO0") "CORE_IN")
lsnPadBind("DIN<0>" list("PAD_RING" "U_IO0") "CORE_OUT")
```

第一个参数是关联原理图中的标量顶层 Pin，第二个参数是从当前检查 scope 开始的真实 PAD 实例路径，第三个参数是已注册的真实核心角色。总线聚合不能直接绑定，应逐位绑定。

显式目标与可靠的自动目标取并集，不会覆盖或隐藏已有逻辑义务。同一 PAD 的不同核心端子可以分给不同网；同一端子不能分给不同网。一个 Pin 绑定两个 PAD 时，两者都必须接通。没有自动绑定的导入 GDS 必须人工指定，不根据最近的 PAD 推断。

父级 scope 支持普通实例的旋转、镜像和坐标变换。PAD 端点在相应父级窗口定位。重复核心必须指定准确 occurrence；不猜测 mosaic/array 元素。

通过 GUI 的 Save config 或 `lsnPadSaveConfig()` 保存到新的绝对 Linux 文件。保存文件包含 profile 快照和该 scope 的显式绑定；换工艺后直接载入旧快照可能重新覆盖新 profile，因此应修改并重新导出，不能只改文件路径。加载的是本地 SKILL 代码，只使用自己审阅过的文件。

## 移植验收表

在独立小设计或只读保存版本上核对；如果需要生成走线验证，使用明确新建的测试库，不在生产设计上自动画线。

| 场景 | 期望 |
| --- | --- |
| 内部连通、尚无 PAD | Internal connected / PAD pending；不进入 Connected |
| PAD 已放、对应未知 | PAD unassigned 或 Unverified；不能完成 |
| 对应正确、无金属连接 | PAD unconnected，或因接入证据不足显示 Unverified |
| 物理接通正确核心端子 | 核心及全部必需目标均通过后才 Connected |
| 只接外部 bond 或错误电源环 | 不能满足另一个 GPIO 核心角色 |
| 两个必需 PAD，只接一个 | 仍未完成 |
| 同一端子多个等价接入图形 | 一个可验证接入面即可，不重复要求全部图形 |
| 同一核心角色显式分给两个网 | 拒绝冲突 |
| 父级 PAD、旋转/镜像核心 | 定位与实际坐标一致，总览和 Back 使用正确窗口 |
| Check selected 更新一个 Pin | 其他已检查网络结果保持，修改相关配置后标记重查 |
| 保存/恢复配置 | 名称与实例路径正确，重新检查结果一致 |
| 缺少许可、未知专用 PAD、无法读取层级 | 明确未知，不得出现无依据的 Connected |

41 项原生回归是在文档记录的原适配 PAD 上通过的，不能替代此表在其他站点的验收。现有 PAD 集成测试引用原 PAD 的尺寸和端子坐标，换工艺后不要只替换库名就运行；新建小型站点用例，重新确定角色、坐标和独立预期。

## 当前不能由配置解决的差异

需要任意回调才能定位的 PAD、复杂阵列、加密或无法查询的层级、动态 textDisplay-only 端口、缺少任何可靠落点的几何、多个不等价图形被错误定义为同一角色，以及其他 Virtuoso 版本的 API 行为差异，都需要进一步实现和验收。0.3.4 固定包不自动兜底，证据不足保持 Unverified。

本功能验证指定端点之间的金属/通孔连通性，不证明没有短路，不检查 PAD 功能、电平、供电和封装关系，也不替代 DRC/LVS。
