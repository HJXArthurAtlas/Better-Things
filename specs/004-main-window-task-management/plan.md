# Implementation Plan: 主窗口任务管理

**Branch**: `004-main-window-task-management` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)

## Summary

主窗口从占位页变为完整任务管理界面：顶部输入框（回车添加、空白忽略、⌘N 聚焦）、
未完成列表（系统选择模型 + ↑↓）、「已完成 (n)」折叠分组（默认折叠）、双击编辑面板
（标题/备注，取消可回退）、右键/⌫ 删除 + ⌘Z 快照重放撤销、空状态引导。
数据全部经 TaskStore，App 零持久化引用。

## Technical Context

**Language/Version**: Swift 6.3.3 | **Dependencies**: SwiftUI + BetterThingsKit（零第三方）
**Storage**: 经 TaskStore（本特性不改存储） | **Testing**: swift test + 运行时 UI 取证
**Target Platform**: macOS 15.0+ | **Project Type**: 应用外壳增量

## Constitution Check

| 原则 | 状态 | 依据 |
|---|---|---|
| I. 原生体验优先 | ✅ | 全部使用系统控件（List/Form/ContentUnavailableView/原生选择模型） |
| II. 核心与壳分离 | ✅ | 选中标识用 UUID（research D1），App 零持久化引用；BT-7 门回归 |
| III. 本地优先 | ✅ | 数据经 TaskStore 落盘 |
| IV. 测试护核心 | ✅ | 模型/存取层已有测试；UI 以运行时取证验收 |
| V. 规格驱动 | ✅ | 本文档即产物 |

## Project Structure

```text
App/
├── BetterThingsApp.swift   # 重写：store 创建与注入
├── ContentView.swift       # 新增：布局 + 输入 + 列表 + 分组 + 空状态 + 键盘
├── TaskRow.swift           # 新增：任务行（勾选/双击编辑/右键删除）
└── EditTaskSheet.swift     # 新增：编辑面板（副本编辑，取消可回退）
Sources/BetterThingsKit/TaskItem.swift  # 增量：id: UUID 字段（research D1）
```

## Constitution Check 后置（Phase 1 复查）

id 字段为通用唯一标识（非持久化框架类型）✅；完成状态修改仍只经 complete/reopen ✅。

## Complexity Tracking

> 无违规。唯一权衡：为选中标识增加 UUID 字段（research D1，宪法 II 的直接推论）。
