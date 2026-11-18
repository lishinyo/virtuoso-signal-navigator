# Pin 与 PAD 接入检查

适用于 0.3.4。本功能不放置 PAD、不画线、不保存用户版图，也不加载路径预测。

其他 PDK、不同 PAD 或另一台电脑：先读 [PAD 工艺适配](PAD_PORTING.md)。下方的内建单元是原适配参考，不要求新环境必须使用同一批 PAD，也不意味着其他 PAD 的端子功能相同。

## 完成条件

Pin 指关联原理图的顶层输入、输出、双向端口。小型 layout pin 图形或端口标签只是出线位置，不能代替实际 PAD。

检查分为两个状态：核心端点是否物理连通，以及指定 PAD 核心端子是否接入。Pin 只有在全部必要核心端点及所有指定 PAD 目标完成后，才进入 Connected。内部 Nets 沿用原连通规则。一个有效核心位置也可以通过实际 PAD 接入完成，不强行要求存在两个内部位置。

| 显示 | 含义 |
| --- | --- |
| Internal connected / Internal open / Internal unverified | 核心位置已连通 / 分岛 / 存在未知 |
| PAD pending | 当前检查范围没有识别到支持的 PAD，还需要接 PAD |
| PAD unassigned | 已有 PAD，但没有可靠的端子对应 |
| PAD unconnected | 目标明确，实际金属尚未接通 |
| PAD unverified | 范围、目标、接入图形或追踪存在无法确认的情况 |
| Connected (including PAD) | 核心与全部指定 PAD 目标完成 |
| Connected* (including PAD; inferred landing) | 同上，但包含标签或导入接入点假设，不代替 LVS |

明确待接/未接的 Pin 可以通过 Open 筛选；对应不明或证据不足进入 Unverified。Show 继续只有一个 Pin 类别。过期结果仍保留 needs recheck 标记，修改一条对应关系只使那条 Pin 的 PAD 签名过期，不清空其他结果。

## 默认 PAD 与端子

依据工作区版图说明及本机真实 symbol、schematic、layout 查询：

| 库/单元 | 允许的核心目标 | 物理接入依据 |
| --- | --- | --- |
| DBH_ANALOG_PAD/IOPAD | IO | 实际 BOND 开口对应的 MET6 导体，含子实例变换 |
| DBH_ANALOG_PAD/VDDPAD | VDD | 对应电源 bond metal；不能只碰到其他 ESD 环 |
| DBH_ANALOG_PAD/GNDPAD | GND | 对应地 bond metal；不能只碰到其他 ESD 环 |
| DBH_1830AN18BA_AN18GPIO5V_ISO_MINI_75U/PH18C0810_ISO_75 | I、Z、OEN、IE、DS | 实际端口标签下的金属；一个端子在 M2/M3 可有多个接入图形 |

GPIO 的 I 是输入到 PAD 单元的数据端，即核心到 PAD 的数据；Z 是 PAD 单元输出到核心的数据端。OEN/IE/DS 是控制端。配置必须依据实际电路，工具不推断控制电平、不验证工作模式或供电设置。外部 PAD 端、DVDD/DVSS/SUB 环不是该单元的普通信号核心目标，默认不允许这样分配。

多组不同逻辑信号可以使用同一个 GPIO 的不同核心端子；同一个核心端子不能显式分给两个不同网络，也不能覆盖已经明确的逻辑网络对应。不同图形属于同一 terminal 时按可选接入面处理，连接其中一个可验证图形即可；多个显式必需 PAD 目标则必须全部完成。

这批默认 PAD 的 layout 没有正式 OA terminal。不能简单依赖 `term~>pins`；插件已实现标签/层级金属和 bond-metal 接入读取。某些标签位于金属边界时会保守核对实际内部点；仍无法可靠追踪的候选保留 unknown 原因，不改成通过。

## 原生界面的操作

1. 仍在导航页选择某个单独 Pin。总线聚合行需要先选择具体位。
2. 点击 **PAD setup / connection targets**。
3. 默认检查范围是当前绑定版图。Recognized PAD instances 列表显示实例路径、库/单元及允许的核心端子。
4. 选择实际 PAD 实例和 Core terminal，点击 **Add required target**。可以为同一个 Pin 添加多个必需目标。下表显示显式或已有逻辑绑定得到的对应关系。
5. **Locate terminal** 定位实际目标；**Check this Pin** 更新该 Pin 的状态。用户手工补线后可再次检查。未接时轮询包括核心出线点和 PAD；PAD 尚不存在时只定位已有核心位置，不制造外部坐标。
6. **Remove explicit target** 只删除选中的显式对应，不删除 PAD 或走线。实际 layout instTerm / source binder 得到的目标始终保留，显式目标是补充，不能用它掩盖已有的其他必需连接。

自动对应只使用真正的网络对象、原理图端子及已有实例绑定，不能把同名标签或最近的 PAD 当成关联依据。导入 GDS 缺少这些数据时必须人工指定。

## PAD 位于上一层顶层

如果当前查看的是核心 cell，而 PAD 在装配顶层：在 PAD setup 填写检查顶层的 Library/Cell/View，以及核心在该顶层中的 **Core instance path**，例如 `I_WRAP/I_CORE`。点击 Apply scope；新开的范围窗口是只读打开，已存在的窗口只作查询。

实例路径必须对应当前绑定的准确核心 occurrence。重复核心实例不能按相同 cell 名随意挑一个。支持普通实例的旋转、镜像、层级变换；不猜测阵列/mosaic 元素坐标。

PAD 端点在它所属的范围窗口定位，总览会将核心坐标换算到该范围，Back view 返回相应窗口的旧视野。绑定的核心导航上下文保持不变。检查时整个装配范围的实际金属可连接原本在核心内分开的端点。

## 保存与恢复对应配置

Config 填写一个**新的绝对 Linux 文件路径**，如 `/home/user/project/pad_targets_01.il`。Save config 保存 profile、检查范围及该范围内的显式对应；不保存版图，拒绝覆盖已有文件。Load config 读取用户自己保存的本地 SKILL 配置，不应加载来源不明的代码。

重新开启 Virtuoso 后，先加载导航器并绑定目标核心，再加载这份 PAD 配置。文件使用库/单元/视图、实例路径、端子名，不保存临时 dbId 或窗口号。

等效 API 示例（名字仅示意，必须换成自己的真实设计）：

```lisp
; 当前绑定核心内的 PAD
lsnPadBind("ANALOG_OUT" list("PAD_A0") "IO")
; 同一 GPIO 的不同端子可属于不同顶层 Pin
lsnPadBind("SIG_FROM_PAD" list("GPIO_0") "Z")
lsnPadBind("SIG_TO_PAD" list("GPIO_0") "I")
lsnPadBind("SIG_OE" list("GPIO_0") "OEN")
; 一个电源 Pin 有两个必需 PAD
lsnPadBind("VDD" list("VDD_0") "VDD")
lsnPadBind("VDD" list("VDD_1") "VDD")
; PAD 在上一级；此接口可重用现有窗口或只读打开
lsnPadUseScope("design_lib" "chip_top" "layout" list("I_CORE"))
lsnPadBind("ANALOG_OUT" list("PAD_RING" "PAD_A0") "IO")
lsnPadSaveConfig("/home/user/project/pad_targets_01.il")
```

换工艺时可注册明确的 profile，格式是 `(核心端子名 定位方式 数据...)`：

```lisp
lsnPadRegisterProfile("my_pad_lib" "MY_IO_CELL"
  list(list("CORE_IN" "label" list("CORE_IN"))))
```

`label` 先读同名正式 terminal，没有时读配置标签及真实金属。`bond` 使用明确的开口层和金属层，例如 `list("IO" "bond" "BOND" "MET6")`，仅适用于已确认被该角色直接导通的被动 PAD。不要把它套到有缓冲/电平转换的 GPIO 数据通路。

`lsnpDedicatedPadLibraries` 只列明确的专用 PAD 库。注册同一设计库中的自定义 PAD 单元不会使整库的普通模块被误判为 PAD。专用库内未知单元、无法展开的 PAD 阵列、扫描上限、缺少接入图形等会明确报告；不能当作空白或已接通。

完整的站点与设计模板见 [site_config.template.il](../examples/site_config.template.il) 和 [design_targets.template.il](../examples/design_targets.template.il)。profile 注册、层名配置和实例对应是三件事，不要仅替换默认 PAD 名称就假定物理接入正确。

## 验证与边界

新增 PAD 集成检查在独立一次性测试库中引用已安装的真实模拟/GPIO PAD，41 项通过，覆盖待接、错误对应、真实补线、多目标、备选接入、自动逻辑意图、显式与自动目标并存、配置往返、保持其他缓存、用户 trace 保留、父级装配及坐标。测试生成器只允许新建 `LSN_DEMO_PAD_` 库和新目录，修改/保存的仅是测试库；不复制 PDK，不修改原生产设计。原全套历史测试与预测未重跑。

Connected 仍是当前检查范围、指定意图和可解析金属/通孔的连通结论。它不证明 PAD 功能配置正确、没有短路、ESD/闩锁规则合格、封装键合关系完成，也不替代 DRC/LVS。默认未认证所有 PDK、PAD 变种、数组、其他 Virtuoso 大版本或加密层级。
