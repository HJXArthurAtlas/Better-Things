# AGENTS.md — Better Things

## UI 设计源：Penpot（最高优先级）

本项目的 UI 设计稿托管在 **Penpot**。所有涉及设计的问题——配色、间距、字号、圆角、布局、组件结构、视觉规范——都**必须优先结合 Penpot 进行分析和调整**，再落到代码：

1. **先看设计稿**：改动任何 UI 之前，先用 Penpot MCP 工具（`penpot_high_level_overview` → `penpot_execute_code` / `penpot_export_shape`）读取对应页面/组件，确认设计稿中的实际值。
2. **以设计稿为准**：代码中的颜色、尺寸等视觉值若与 Penpot 设计稿不一致，以 Penpot 为基准修正代码；确需偏离设计稿时必须先在设计稿中同步更新，再改代码。
3. **不要凭记忆猜值**：禁止用经验值或系统默认值替代设计稿中的具体值（如配色 hex）。

初次使用 Penpot 工具前，先调用 `penpot_high_level_overview` 了解操作方式。

## 项目结构

- `App/` — macOS SwiftUI 应用（`BetterThingsApp.swift` 入口，`ContentView.swift` 主界面）
- `Sources/BetterThingsKit/` — 核心逻辑（TaskStore / TaskItem）
- `Tests/BetterThingsKitTests/` — 单元测试
- `specs/`、`.specify/` — 规格与工作流文档
