# Implementation Plan: 实现 TaskStore 任务存取与持久化

**Branch**: `003-taskstore-crud` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-taskstore-crud/spec.md`

## Summary

在 BetterThingsKit 新增 `@MainActor @Observable` 的 `TaskStore`：持有 SwiftData
容器与上下文，初始化即按创建时间倒序加载，提供添加/删除/显式保存，以只读数组暴露
任务集合；支持内存模式（测试/预览）与指定位置模式（持久化重建测试）。

## Technical Context

**Language/Version**: Swift 6.3.3（swift-tools-version 6.0）

**Primary Dependencies**: SwiftData（系统框架）、Observation（@Observable 宏）

**Storage**: SwiftData `ModelContainer`/`ModelContext`（本特性建立存取，落盘位置由构造参数决定）

**Testing**: Swift Testing + 内存容器与临时目录位置

**Target Platform**: macOS 15.0+（arm64）

**Project Type**: 本地 library 包增量

**Performance Goals**: 不适用（单用户本地数据量）

**Constraints**: App 外壳零改动（宪法 II）；不引入界面绑定职责（BT-10+）

**Scale/Scope**: 新增 1 个 store 文件 + 1 个测试文件

## Constitution Check

*GATE: Must pass before Phase 0. Re-check after Phase 1.*

| 原则 | 状态 | 依据 |
|---|---|---|
| I. 原生体验优先 | ✅ 不适用 | 纯数据层特性 |
| II. 核心与壳分离 | ✅ 通过 | App 禁用 @Query 的原因正是它需要 import SwiftData——集合只能由 Kit 的 store 暴露（research D2） |
| III. 本地优先 | ✅ 通过 | 落盘为本地文件；内存模式仅测试/预览 |
| IV. 测试护核心 | ✅ 通过 | CRUD + 重建 + 自动加载全覆盖 |
| V. 规格驱动 + 轻量敏捷 | ✅ 通过 | 本文档即流程产物 |

## Project Structure

### Documentation (this feature)

```text
specs/003-taskstore-crud/
├── plan.md              # This file
├── research.md          # D1-D3 决策
├── data-model.md        # 存取语义与不变量
├── quickstart.md        # 验证指南
├── contracts/
│   └── taskstore-api.md
└── tasks.md             # /speckit.tasks output
```

### Source Code (repository root)

```text
Sources/BetterThingsKit/
└── TaskStore.swift           # 新增：@MainActor @Observable 存取器
Tests/BetterThingsKitTests/
└── TaskStoreTests.swift      # 新增：CRUD/重建/自动加载测试
```

**Structure Decision**: 复用既有根包结构，仅增文件、零结构变更；App 目录不触碰。

## Complexity Tracking

> 无宪法违规，不需要豁免。
