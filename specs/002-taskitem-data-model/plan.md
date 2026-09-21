# Implementation Plan: 定义任务数据模型（TaskItem）

**Branch**: `002-taskitem-data-model` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-taskitem-data-model/spec.md`

## Summary

在 BetterThingsKit 中定义 SwiftData `@Model` 实体 `TaskItem`（标题/备注/创建时间/
完成状态/完成时间），以 `complete(at:)`/`reopen()` 方法集中维护完成不变量，配套
单元测试覆盖字段契约、状态联动与持久化注册；App 外壳零改动。

## Technical Context

**Language/Version**: Swift 6.3.3（swift-tools-version 6.0）

**Primary Dependencies**: SwiftData（系统框架，macOS 14+，SPM 自动链接）、Swift Testing

**Storage**: SwiftData 模型定义（本特性不落盘、不建存取接口）

**Testing**: Swift Testing（`swift test`）；持久化注册用内存 `ModelContainer` 验证

**Target Platform**: macOS 15.0+（arm64）

**Project Type**: 本地 library 包增量（无新目标）

**Performance Goals**: 不适用

**Constraints**: App 外壳零改动、零持久化引用（宪法 II）；模型不拦截空标题（D3）

**Scale/Scope**: 新增 1 个模型文件 + 1 个测试文件，约 120 行

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原则 | 状态 | 依据 |
|---|---|---|
| I. 原生体验优先 | ✅ 不适用 | 纯模型特性，无 UI |
| II. 核心与壳分离 | ✅ 通过 | 模型在 Kit；App 零改动，BT-7 门回归复查 |
| III. 本地优先 | ✅ 通过 | SwiftData 本地机制；测试用内存容器不落盘 |
| IV. 测试护核心 | ✅ 通过 | 字段/联动/注册全覆盖 |
| V. 规格驱动 + 轻量敏捷 | ✅ 通过 | 本文档即流程产物 |

## Project Structure

### Documentation (this feature)

```text
specs/002-taskitem-data-model/
├── plan.md              # This file
├── research.md          # D1-D4 决策
├── data-model.md        # TaskItem 实体定义与不变量
├── quickstart.md        # 验证指南
├── contracts/
│   └── taskitem-model.md
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
Sources/BetterThingsKit/
└── TaskItem.swift            # 新增：@Model 实体 + 状态联动方法
Tests/BetterThingsKitTests/
└── TaskItemTests.swift       # 新增：字段契约/排序/联动/注册测试
```

**Structure Decision**: 复用 001 特性建立的根包结构，仅增文件、零结构变更。

## Complexity Tracking

> 无宪法违规，不需要豁免。
