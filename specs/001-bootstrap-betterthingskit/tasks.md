# Tasks: 初始化 BetterThingsKit 共享核心包并接入应用外壳

**Input**: Design documents from `/specs/001-bootstrap-betterthingskit/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md（无实体） | contracts/betterthingskit-api.md ✅ | quickstart.md ✅

**Tests**: 已包含——FR-003 明确要求核心库初始即带健全性测试。

**Organization**: 按用户故事分阶段（US1 P1 → US2 P2 → US3 P3），每阶段独立可验证。

## Phase 1: Setup（项目脚手架）

- [x] T001 创建根 `Package.swift`：swift-tools-version 6.0，platforms macOS 15，library 目标 `BetterThingsKit`（路径 Sources/BetterThingsKit），testTarget `BetterThingsKitTests`
- [x] T002 创建 `project.yml`：App target「Better Things」（macOS 15.0，SwiftUI 生命周期），依赖本地包 BetterThingsKit（path: .），产物 Info.plist 由 xcodegen 生成

## Phase 2: Foundational（核心库骨架，阻塞全部用户故事）

- [x] T003 创建 `Sources/BetterThingsKit/BetterThingsKit.swift`：`public enum BetterThingsKit { public static let version = "0.1.0" }`（契约见 contracts/betterthingskit-api.md，不引入任何持久化类型）

## Phase 3: User Story 1 — 应用外壳调用共享核心库 (Priority: P1) 🎯 MVP

**Goal**: App target 导入 Kit 并在界面渲染 `BetterThingsKit.version`，构建通过、可运行。

**Independent Test**: quickstart.md 第 2、3 步（xcodebuild BUILD SUCCEEDED；窗口显示版本字符串）。

- [x] T004 [US1] 创建 `App/BetterThingsApp.swift`：SwiftUI @main 应用，单窗口正文渲染 `"Better Things \(BetterThingsKit.version)"`；不得 import SwiftData（FR-004）
- [x] T005 [US1] 运行 `xcodegen generate` 生成 `Better-Things.xcodeproj` 并入库（生成物提交，贡献者免装 xcodegen）
- [x] T006 [US1] 执行 `xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" -configuration Debug build`，确认 BUILD SUCCEEDED

## Phase 4: User Story 2 — 核心库可独立构建与测试 (Priority: P2)

**Goal**: `swift test` 在仓库根独立通过，不依赖 App 工程。

**Independent Test**: quickstart.md 第 1 步。

- [x] T007 [US2] 创建 `Tests/BetterThingsKitTests/BetterThingsKitTests.swift`：Swift Testing 健全性测试——`BetterThingsKit.version` 等于 `"0.1.0"` 且非空（FR-003）
- [x] T008 [US2] 执行 `swift test`，确认全部通过

## Phase 5: User Story 3 — 依赖边界可机械验证 (Priority: P3)

**Goal**: 外壳源码零持久化引用，可用一条命令验证。

**Independent Test**: quickstart.md 第 4 步输出 CLEAN。

- [x] T009 [US3] 执行边界检查 `grep -rn "import SwiftData\|ModelContainer" App/`，确认无命中（SC-003）

## Phase 6: Polish & Cross-Cutting

- [x] T010 创建 `README.md`：项目一句话介绍、前置条件（macOS 15+ / Xcode）、构建与测试命令（引用 quickstart.md）、工程结构变更需重跑 `xcodegen generate` 的说明（SC-004 ≤10 分钟目标）

## Dependencies

- T001、T002 可并行（不同文件）
- T003 依赖 T001；T004 依赖 T002 + T003；T005 依赖 T002 + T003 + T004；T006 依赖 T005
- T007 依赖 T001 + T003；T008 依赖 T007
- T009 依赖 T004（App 源码存在后检查才有意义）
- T010 依赖 T006、T008（写真实可用的命令）

## Parallel Execution Examples

- Phase 1 内：T001 与 T002 并行
- US1 的 T004 与 US2 的 T007 并行（不同目录，互不依赖）
- US3（T009）可在 T004 完成后随时插入

## Implementation Strategy

- **MVP 范围 = Phase 1–3（US1）**：完成即满足 BT-6 卡面验收「App 可 import BetterThingsKit 并编译通过」
- US2/US3 是同批次内的加固项，体量极小，随 MVP 一起交付
- 每完成一个 Phase 跑一次对应 quickstart 步骤，失败即停、修复后继续
