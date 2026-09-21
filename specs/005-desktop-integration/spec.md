# Feature Specification: 桌面集成（托盘 + 快速录入浮窗）

**Feature Branch**: `005-desktop-integration` | **Created**: 2026-09-21 | **Status**: Implemented
**Input**: YouTrack 卡 BT-15（菜单栏托盘）、BT-16（⌥Space 快速录入浮窗）——两卡共享桌面集成层，一体实现。

## User Scenarios & Testing

### User Story 1 - 菜单栏托盘（BT-15，P1）

应用运行时菜单栏出现托盘图标；左键点击在「显示 / 隐藏主窗口」间切换；关闭主窗口
（红点）后应用保持运行，托盘点击可找回主窗口。

**Acceptance Scenarios**:
1. Given 应用运行，When 观察菜单栏，Then 托盘图标常驻。
2. Given 主窗口可见，When 左键点击托盘图标，Then 主窗口隐藏；再点，Then 恢复显示。
3. Given 点击主窗口红点关闭，When 检查进程，Then 应用仍运行；When 点击托盘图标，Then 主窗口恢复。

### User Story 2 - ⌥Space 快速录入浮窗（BT-16，P1）

任意应用前台时按 ⌥Space 唤起独立浮窗；输入标题回车即创建任务，浮窗保留可连续输入；
Esc 或浮窗失焦时自动隐藏；再次 ⌥Space 可重新唤起。

**Acceptance Scenarios**:
1. Given 任意应用前台，When 按 ⌥Space，Then 浮窗出现且输入框聚焦。
2. Given 浮窗中输入标题，When 回车，Then 任务创建且浮窗保留、输入框清空。
3. Given 浮窗打开，When 按 Esc 或点击浮窗外区域，Then 浮窗隐藏。
4. Given 浮窗隐藏，When 再按 ⌥Space，Then 浮窗再次出现。

## Requirements

- **FR-001**: 系统 MUST 提供菜单栏托盘图标，左键切换主窗口显示/隐藏。
- **FR-002**: 主窗口关闭后应用 MUST 保持运行。
- **FR-003**: 系统 MUST 注册全局快捷键 ⌥Space 用于唤起/隐藏快速录入浮窗（toggle 语义）。
- **FR-004**: 浮窗回车创建任务后 MUST 保留浮窗并清空输入框；Esc 与失焦 MUST 隐藏浮窗。
- **FR-005**: 浮窗录入的任务 MUST 进入与主窗口相同的数据存储（TaskStore）。

## Success Criteria

- **SC-001**: 上述全部验收场景运行时取证通过（含跨应用前台时的全局热键）。
- **SC-002**: 既有测试与构建零回归。

## Notes

- 实现记录：Carbon `RegisterEventHotKey` 全局热键（注册失败仅记日志——⌥Space 被其他
  注册者占用时静默降级为菜单项触发，见「快速录入」菜单项 ⌘⇧K）；SwiftUI Window scene
  惰性创建，经 `QuickWindowRouter` 桥接 AppDelegate 的 openWindow 调用；
  浮窗隐藏使用显式窗口定位（失焦时 keyWindow 已易主，不能依赖 keyWindow）。
