# Better Things

一款为 macOS 打造的本地优先待办管理工具。菜单栏一键呼出、全局快捷键快速录入，
数据全部保存在你自己的电脑上。

## 功能特性

- **任务管理**：添加、编辑、删除、勾选完成，重启后数据原样恢复
- **快速录入浮窗**：任意应用中按 `⌥Space` 唤起，回车连续录入，`Esc` 或失焦自动隐藏
- **菜单栏托盘**：一键显示 / 隐藏主窗口，关窗不退出
- **已完成分组**：勾选完成自动归组，分组可折叠并显示计数
- **键盘优先**：`⌘N`、`↑↓`、`⌫`、`⌘Z` 全流程无需鼠标
- **本地优先**：无需账号，无网络请求，数据不出设备

## 系统要求

macOS 15.0 或更高版本。

## 下载安装

从 [Releases](../../releases) 页面下载 `Better-Things-x.x.x.dmg`，打开后将
Better Things 拖入 Applications 即可。

> 当前版本为 ad-hoc 签名：首次打开若提示无法验证，请右键点击应用选择「打开」。
> 配置开发者证书公证后此提示将消失。

## 使用说明

### 添加任务

在主窗口顶部输入框输入标题，按 `回车` 即可创建；新任务置顶显示。
空白输入会被忽略。

### 快速录入（推荐）

在任何应用中按 `⌥Space` 唤起浮窗：

- 输入标题按 `回车` 创建任务，浮窗保留可连续录入
- `Esc` 或点击浮窗外区域自动隐藏
- 再次按 `⌥Space` 随时唤起

### 完成 / 编辑 / 删除

- **完成**：点击任务左侧圆圈，任务移入「已完成」分组（分组可点击折叠）
- **编辑**：双击任务，修改标题与备注后保存
- **删除**：右键菜单选「删除」，或选中任务后按 `⌫`

### 快捷键

| 快捷键 | 作用 |
|---|---|
| `⌥Space` | 全局唤起 / 隐藏快速录入浮窗 |
| `⌘N` | 聚焦新建输入框 |
| `↑` `↓` | 选择上 / 下一个任务 |
| `⌫` | 删除选中任务 |
| `⌘Z` | 撤销最近一次删除 |
| `Esc` | 关闭浮窗 / 取消编辑 |

### 菜单栏托盘

菜单栏的清单图标：左键点击在「显示 / 隐藏主窗口」间切换。关闭主窗口后应用
仍在菜单栏驻留，随时找回。

### 数据存储

所有任务保存在本机 `~/Library/Application Support/default.store`（SwiftData 数据库），
不联网、不上传。删除该目录即彻底重置数据。

## 开发

```bash
# 核心库测试
swift test

# 构建应用
xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" build

# 打包 dmg（未配置公证证书时产出本机可用版本）
scripts/build-dmg.sh
```

- 技术栈：SwiftUI + SwiftData + TaskStore（本地 SPM 包），零第三方依赖
- 架构与决策记录：`specs/` 目录（Spec-Driven Development）
- 修改工程结构后需 `xcodegen generate` 重新生成工程（需 `brew install xcodegen`）
- 修改应用图标：编辑 `scripts/make-icon.swift` 后运行并重新打包

完整验证步骤见 `specs/001-bootstrap-betterthingskit/quickstart.md`。

## License

[MIT](LICENSE)
