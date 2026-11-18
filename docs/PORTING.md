# 移植与配置参考

## 1. 移植目标

先让脚本在目标 Virtuoso 版本中加载，再确认设计连接信息，最后调整单位与标签层。不要一开始就修改核心遍历逻辑。

运行命令：

```lisp
lsnCheckEnvironment()
```

它检查关键 API 是否存在，不验证许可证签出、数据质量或全部行为。目标版本的安装手册和实际验收仍是依据，参见 [兼容性](COMPATIBILITY.md)。

## 2. 配置方法

先加载源文件，配置，再打开面板：

```lisp
lsnConfigure('localViewWidth 40.0)
lsnConfigure('unitLabel "um")
lsnStart()
```

修改配置后重新运行 `lsnStart()`。面板会重建并重置当前搜索、选择和导航状态。配置只在本次 Virtuoso 进程中保留；可把配置命令存入自己的文件，升级后再加载。

恢复全部默认值：

```lisp
lsnResetConfig()
lsnStart()
```

`lsnResetConfig()` 会先关闭本插件面板及标记。

这里的“全部”指 `lsnConfigure()` 管理的导航选项；不会重置 `lsncStackLayers`、PAD profile、scope 或全部 PAD 对应。切换工艺时按 [PAD 移植流程](PAD_PORTING.md) 在新会话配置。

## 3. 完整选项

| 选项 symbol | 默认值 | 含义与允许值 |
|---|---|---|
| localViewWidth | 30.0 | 正数；局部视野宽度，设计 user units |
| minViewSpan | 20.0 | 正数；总览最小跨度及模块范围定位的最小留白依据 |
| unitLabel | "user units" | 字符串；只改变界面文字，不转换坐标 |
| labelProbeRadius | nil | 正数或 nil；标签锚点附近查询半径，nil 时采用该 master 的一个 DBU；缺少有效精度时回退 0.001 user units |
| labelHints | t | t/nil；允许查找标签线索 |
| blockHints | t | t/nil；允许只定位已确认所属实例的模块范围 |
| normalizeBusBrackets | t | t/nil；精确标签未命中时兼容角括号与方括号的名称写法，保留大小写 |
| labelLayerMap | nil | 由二元素字符串列表组成的列表，例如 `list(list("M2TXT" "M2"))` |
| sameNameNetFallback | t | t/nil；源网络未取得绑定时，是否允许在当前版图找同名网络 |
| sourceOverride | nil | nil 自动发现；或 `list("lib" "cell" "schematic")` 明确指定原理图 |
| maxMetalExtents | 2000 | 正整数；总览中最多画多少个金属图形包围框 |
| chainLimit | 500 | 正整数；不超过此位置数时用邻近链式连接，超过时用星形示意 |
| annotationLimit | 50 | 正整数；超过此位置数时不在总览给每个位置加文字 |
| dockByDefault | nil | t/nil；默认停靠或浮动 |
| useCustomPalette | t | t/nil；启用本插件独立显示资源 |
| tempDir | nil | nil 或已存在目录的字符串；配色临时文件目录，nil 依次采用 TMPDIR、/tmp |

未识别的选项或无效类型会报错，不会静默忽略。布尔值 nil 是有效设置，不会被默认值重新覆盖。

## 4. 单位与数据库精度

`localViewWidth`、`minViewSpan` 和 `labelProbeRadius` 都使用数据库 user-coordinate units。不要把 `dbuPerUU=1000` 误解为坐标数值已经使用纳米。

例如一个以微米为 user unit、每微米 1000 DBU 的设计：30.0 表示 30 µm，自动查询半径为 0.001 µm。`unitLabel="um"` 只是显示说明。

如果目标数据库用其他 user unit，按相同的实际尺寸调整数值。可以先用已知 pin 的坐标或已知宽度检查倍率，再进行全设计操作。

## 5. 原理图关联与绑定

优先使用 `lxGetSchematic()` 取得当前设计实际的源引用。不同库、不同 cell 名是正常情况。

源发现不可用或需要明确选择时：

```lisp
lsnConfigure('sourceOverride list("demo_lib" "logic_top" "schematic"))
lsnStart()
```

这只以只读方式打开给定源，**不创建实例对应关系**。脚本先依据版图已有的 instTerm，或通过 `bndGetBoundObjects()` 取得的源到版图绑定，确认所属实例，再在该实例内部查找标签。两种依据都没有时，不在全芯片中按相同实例名猜测一个模块。

没有源时，列表仍可使用版图的 net、term 和 instTerm。没有源绑定、版图也没有正式连接信息的纯几何设计，不具备足够信息来重建全部逻辑关系。

同名网络回退默认为开启，用于绑定信息不完整、但源与版图网络名一致的情况。必须禁止此启发式时：

```lisp
lsnConfigure('sameNameNetFallback nil)
```

此时来自源的网络依靠已有网络绑定；没有源的版图网络浏览仍可使用自己的网络对象。

## 6. 标签层、用途与金属映射

默认检索所属 master 当前层级内所有 label 对象。先按端子名精确匹配；没有精确结果才用括号兼容匹配。大小写敏感，不自动扩展别名，也不把总线范围名当作每一位的端点。

命中后使用 label 的 `xy` 锚点，不使用文字包围盒中心。几何查询默认在标签的同名 layer 上进行，接受该层的任意 purpose，排除 label 本身，仅保留 rect、path、pathSeg、polygon。多个重叠候选时用包围框面积较小者辅助显示；它不因此成为正式 pin。

有些环境将文字放在单独的名称层，需要映射：

```lisp
lsnConfigure('labelLayerMap list(
  list("M1TXT" "M1")
  list("M2TXT" "M2")
))
```

这是文字 layer 名到金属 layer 名的映射，不是 GDS 数字映射表，也不更改设计中的 layer-purpose。请使用目标 Virtuoso 技术数据库实际的层名称。

标签锚点偏离金属时，适当增大查询半径可能找到邻近几何，同时也会增加误命中的可能性。标注仍是 Label + metal，不升级为 Physical pin。

## 7. 显示、窗口与较旧版本

UI 使用 report field、layout form 和 dock window。缺失这些接口时，不把“脚本能被解析”等同于功能兼容。先依据该版本手册实现 UI 适配，再验证完整行为。

没有 Qt docking 接口的版本当前不提供简化 UI 自动降级。自定义 palette 初始化失败可退回原有高亮层；源/绑定 API 缺失时会限制源导航，而不是新建后台服务来补齐。

在远程桌面上可先浮动使用；停靠面板太窄时拖动加宽。当前仅支持每个进程一个活动面板，多窗口切换用 Bind current layout 或显式 `lsnStart(window(n))`。

## 8. 必须完成的移植验收

至少检查：一个顶层端口、两个有正式 pin 的器件、一组旋转/镜像实例、一个总线、一个只有标签的导入模块、一个没有标签的已绑定模块、一个尚未放置的源实例。

观察位置和 Status 是否符合实际，再检查前后循环、原理图源是否正确、层次切换和布局编辑后的刷新行为。只通过 API 存在检查不能代替这些验收。详细步骤见 [测试说明](TESTING.md)。

## 9. 物理连接栈和资源上限

这些是单独的 SKILL 全局设置，不通过 `lsnConfigure()` 传入。请在开始检查前按目标环境设置：

```lisp
lsncStackLayers=list("M1" "M6") ; 实际下界、上界，不是逐层列表
lsncStopLevel=64
lsncMaxLocations=256
lsncMaxComponents=64
lsnHintDepth=32
```

默认连接栈是 MET1 到 MET6。上下界之间的实际金属/通孔连接由当前技术数据库和原生追踪行为决定；配置两个名字不能创建缺失的技术定义。先确认本机 physical trace 对已知连接可用，再相信插件的状态结论。许可/API 不可用或达到上限时保留 Unverified。

PAD inventory 另有 `lsnpMaxMasters=20000`、`lsnpMaxEdges=500000`、`lsnpMaxOccurrences=10000`，普通 occurrence 深度上限为 32。资源限制不是跳过未知单元的理由；应先查明完整范围，再决定是否在独立会话提高上限。

## 10. PAD 差异与设计迁移

PAD profile 按准确 library/cell 注册，角色白名单和定位策略在站点配置中维护，具体 Pin 到 occurrence/核心端子的关系在设计配置中维护。示例和限制见 [PAD 移植指南](PAD_PORTING.md)，日常界面见 [PAD 接入说明](PAD_CONNECTION.md)。缺少原适配 PAD 库不会阻止脚本加载，但也不能据此认为另一种 PAD 已被识别。
