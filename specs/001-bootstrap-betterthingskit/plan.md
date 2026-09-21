# Implementation Plan: 初始化 BetterThingsKit 共享核心包并接入应用外壳

**Branch**: `001-bootstrap-betterthingskit` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-bootstrap-betterthingskit/spec.md`

## Summary

建立仓库的最小可工作结构：仓库根即 SPM 包（`BetterThingsKit`，独立可测），外加一个
最小 SwiftUI 应用外壳依赖它并展示来自 Kit 的内容；`.xcodeproj` 由 XcodeGen 从提交的
`project.yml` 声明式生成并一并提交，保证干净克隆一次构建通过。

## Technical Context

**Language/Version**: Swift 6.3.3（swift-tools-version 6.0）

**Primary Dependencies**: 零第三方依赖（SwiftUI、Testing 均为系统/工具链自带）

**Storage**: N/A（本特性不涉及持久化；SwiftData 属 BT-8）

**Testing**: Swift Testing（`swift test`，SPM 内建）

**Target Platform**: macOS 15.0+（arm64）

**Project Type**: desktop-app + 本地 library package

**Performance Goals**: 不适用（结构引导特性）

**Constraints**: 干净克隆可复现构建（FR-006）；App 源码零持久化引用（FR-004）

**Scale/Scope**: 2 个构建目标（Kit library + App），约 5 个源文件

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原则 | 状态 | 依据 |
|---|---|---|
| I. 原生体验优先 | ✅ 通过 | App 外壳使用 SwiftUI（原生框架），无 WebView/自绘方案 |
| II. 核心与壳分离 | ✅ 通过 | 本特性即该原则的物理落地；FR-004 固化边界 |
| III. 本地优先 | ✅ 通过 | 无网络依赖；无持久化引入 |
| IV. 测试护核心 | ✅ 通过 | Kit 初始即带测试入口（FR-003） |
| V. 规格驱动 + 轻量敏捷 | ✅ 通过 | 本文档即为 SDD 流程产物 |

## Project Structure

### Documentation (this feature)

```text
specs/001-bootstrap-betterthingskit/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── betterthingskit-api.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
Package.swift                  # 仓库根即 SPM 包（library: BetterThingsKit）
Sources/BetterThingsKit/
└── BetterThingsKit.swift      # 公开接口（初始：版本标识）
Tests/BetterThingsKitTests/
└── BetterThingsKitTests.swift # 健全性测试
App/
└── BetterThingsApp.swift      # SwiftUI 应用外壳（单文件最小实现）
project.yml                    # XcodeGen 声明（App target + 本地包依赖）
Better-Things.xcodeproj/       # xcodegen 生成物，提交入库
README.md                      # 构建/测试入口说明
```

**Structure Decision**: 仓库根即包（root Package.swift），使 `swift test` 无需进入
子目录；App 源码独立于 `App/` 目录，仅经 `project.yml` 声明对本地包的依赖，
物理上阻断外壳私自引用 Kit 内部实现的可能。

## Complexity Tracking

> 无宪法违规，不需要豁免。
