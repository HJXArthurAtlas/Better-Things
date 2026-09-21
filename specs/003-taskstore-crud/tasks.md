# Tasks: 实现 TaskStore 任务存取与持久化

**Input**: Design documents from `/specs/003-taskstore-crud/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**Tests**: 已包含——三个用户故事的独立测试即验收主体。

**Organization**: 按用户故事分阶段；US1 是数据入口的地基。

## Phase 1: User Story 1 — 任务集合的增删改查 (Priority: P1) 🎯 MVP

**Goal**: TaskStore 提供添加/删除/倒序集合（FR-001/002/003/006/007/008）。

**Independent Test**: 内存存取器上验证三场景（添加倒序、删除、更新反映）。

- [x] T001 [US1] 创建 `Sources/BetterThingsKit/TaskStore.swift`：`@MainActor @Observable public final class TaskStore`，`init(inMemory:)/init(url:)/init()` 三构造，初始化即按 `createdAt` 倒序加载（FR-003/006/007/008，research D1/D2）
- [x] T002 [US1] 在 `TaskStore.swift` 追加 `add(title:note:) -> TaskItem` 与 `delete(_:)`，增删后重建集合（FR-001/002）
- [x] T003 [US1] 创建 `Tests/BetterThingsKitTests/TaskStoreTests.swift`（`@MainActor`）：三任务倒序（受控 createdAt，D4）、删除其余保持、就地修改反映（US1/AC1~3）

## Phase 2: User Story 2 — 数据落盘后可完整重建 (Priority: P2)

**Goal**: 写入→重建→一致；删除→重建→已删（FR-004/005）。

**Independent Test**: 临时目录位置模式写入保存后重建断言一致。

- [x] T004 [US2] 在 `TaskStore.swift` 追加 `save() throws`（FR-005，research D3）
- [x] T005 [US2] 追加持久化测试：临时目录写入两任务（其一完成）保存→重建断言一致；删除→保存→重建断言已删（US2/AC1、AC2，含"先完成再取消"不变量跨持久化）

## Phase 3: User Story 3 — 打开即加载 (Priority: P3)

**Goal**: 初始化即就绪；内存模式不触盘（FR-006/007）。

**Independent Test**: 含数据位置初始化后不调用加载直接断言；内存模式集合为空。

- [x] T006 [US3] 追加自动加载测试（重建即读，无显式加载调用）与内存模式空集合测试（US3/AC1、AC2）

## Phase 4: Polish & Cross-Cutting

- [x] T007 执行 `swift test` 全量回归（001/002/003 全部套件）
- [x] T008 [US3] 边界回归 `grep -rn "import SwiftData\|ModelContainer" App/` 输出 CLEAN（SC-004，BT-7 门正式通过条件）
- [x] T009 `xcodebuild` 应用构建零回归（SC-004）
- [x] T010 tasks.md 勾选（本任务清单自检）

## Dependencies

- T001 → T002 → T003 → T004/T005/T006 → T007/T008/T009
- T008 与 T009 可并行

## Implementation Strategy

- **MVP = Phase 1（US1）**：store 可增删查即满足 BT-9 卡面主体验收
- US2/US3 是卡面验收的明确条款（重建、自动加载），随同迭代交付
- 全程不触碰 `App/` 目录
