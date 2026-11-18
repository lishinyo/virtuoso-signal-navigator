# 安装、升级与卸载

## 1. 准备环境

需要已经能打开自己设计的 Virtuoso 图形会话。脚本不负责安装 EDA 软件、申请许可证、注册 PDK 或修复项目库定义。

已验证环境与 API 清单见 [兼容性说明](COMPATIBILITY.md)。没有原理图关联时，可使用版图已有连接信息；读取原理图端点还需要正确的源引用。标签回退需要通过版图 instTerm 或源到版图绑定确认所属实例，详见 [移植说明](PORTING.md)。

## 2. 单文件临时加载

把 `src/signal_navigator.il` 复制到运行 Virtuoso 的 Linux 主机，例如自己的工具目录。可以重命名文件，但保留代码中的 MIT 许可声明。文件编码为 UTF-8，换行建议 LF。

在 CIW 输入，替换示例路径：

```lisp
load("/path/to/signal_navigator.il")
lsnCheckEnvironment()
```

`missingRequired` 应为 `nil`。Optional 部分为 `nil` 不一定阻塞运行，具体降级行为见兼容性文档。

激活目标版图窗口，再在 CIW 输入：

```lisp
lsnStart()
```

CIW 中运行命令时，`hiGetCurrentWindow()` 通常保留当前图形窗口；如果不能明确识别，指定窗口编号：

```lisp
lsnStart(window(n))
```

这里的 `n` 是待替换的编号，不是可原样执行的变量。可在 CIW 运行 `hiGetWindowList()` 查看窗口标识，结合窗口对应的设计选择目标。

默认显示浮动面板。用 **Dock / Float** 切换停靠。首次运行建议在只读方式打开的代表性设计上确认源、坐标、标签依据与显示比例。

## 3. 多主机、远程桌面与 WSL

路径由 **Virtuoso 所在的 Linux 文件系统**解释，不由本地浏览器或 Windows 文件选择器解释。

- 远程 Linux：文件放在远端可读目录，在远端 Virtuoso 的 CIW 加载。
- WSL：文件放在该发行版可见的 Linux 路径。脚本本身不需要知道 WSL 的名称。
- SSH 图形转发或远程桌面：照常在对应 Virtuoso CIW 加载，不另外启动 Python 服务。

只传输源文件即可运行。无需传输本项目的开发日志、测试结果或任何真实芯片设计。

## 4. 配置与自动加载

先加载源文件，再加载自己的配置，最后打开面板。配置示例见 [examples/config.il](../examples/config.il)。

```lisp
load("/path/to/signal_navigator.il")
lsnConfigure('localViewWidth 40.0)
lsnConfigure('unitLabel "um")
```

确认临时加载正常后，可以自行把源文件和个人配置的 `load(...)` 行追加到自己的 `.cdsinit`。项目提供 [启动片段](../examples/cdsinit.snippet.il)，不替用户修改该文件。

推荐启动时只加载定义；打开版图后手动运行 `lsnStart()`。这样不会在 CIW 刚启动、尚未有版图时尝试创建导航面板。

### 其他工艺和 PAD

新环境先按 [PAD 移植指南](PAD_PORTING.md) 准备工艺配置。仅复制运行文件可以打开导航器，但默认 MET1–MET6 与内建 PAD profile 不代表已适配新工艺。

```lisp
load("/path/to/project/src/signal_navigator.il")
load("/path/to/private/site.local.il")
lsnCheckEnvironment()
; 激活目标核心版图并核对面板中的原理图来源
lsnStart()
; 在绑定目标核心之后，才加载这个设计的 PAD 对应
load("/path/to/private/design.local.il")
```

两个文件分别由 [工艺模板](../examples/site_config.template.il) 和 [设计模板](../examples/design_targets.template.il) 修改而来；模板原样加载会停止，需完成替换并移除保护行。也可以在绑定后直接使用 PAD setup 建立对应，无需编写设计脚本。站点配置可在启动时加载，具体设计对应应在绑定正确核心后加载。

更换 PDK 或相互独立的设计时建议新开会话，避免沿用上一项目的 profile、scope 和绑定。配置文件留在公开工程之外；公开 ZIP 不包含个人配置、cds.lib 或 PDK。

## 5. 升级

1. 保留旧版源文件，以便回退。
2. 用 `lsnClose()` 关闭旧面板和显示标记。
3. 将新文件复制到选定位置，重新 `load(...)`。
4. 重新加载个人配置，再运行 `lsnStart()`。
5. 按 [验收步骤](TESTING.md) 核对代表性信号。

运行定义使用 `lsn` 前缀。一个进程内只支持一份活动面板；不要把不同版本当成彼此独立的插件同时使用。版本切换会重建本插件面板，搜索和当前导航状态会重置。

## 6. 配色与临时目录

主脚本内置自己的配色定义。初始化时在 `tempDir`、环境变量 `TMPDIR` 或 `/tmp` 中创建唯一文件，加载后删除这一个文件。它不覆盖用户的 `display.drf`，也不改 foundry layer 的显示 packet。

默认目录不可写时，指定已有的可写目录：

```lisp
lsnConfigure('tempDir "/path/to/writable/temp")
lsnStart()
```

也可用 `lsnConfigure('useCustomPalette nil)` 禁用自定义配色。此时使用已有 y0/y1/y2 高亮层，颜色与虚线效果不保证与截图相同，Status 仍显示定位依据。

## 7. 关闭与移除

```lisp
lsnClose()
```

这会关闭本插件的面板并清除其显示标记，不清除其他工具的探针。SKILL 函数定义仍在本会话内；重新启动 Virtuoso 才会自然清空。

如曾添加自动加载行，自行从个人 `.cdsinit` 中移除相应行，再移除自己安装的脚本文件即可。没有后台服务器、Python 环境或系统服务需要卸载。临时配色定义在本进程中保留到退出，不写回工艺库。
