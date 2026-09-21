# Tasks: 定义任务数据模型（TaskItem）

**Input**: Design documents from `/specs/002-taskitem-data-model/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**Tests**: 已包含——US1/US2/US3 的独立测试即本特性主体。

**Organization**: 三个用户故事按优先级排列，全部在核心包内，可单迭代交付。

## Phase 1: Setup

- [x] T001 确认 Package.swift 无需变更（SwiftData 为系统框架自动链接，平台 macOS 15 已满足）

## Phase 2: User Story 1 — 任务实体具备完整字段与默认值 (Priority: P1) 🎯 MVP

**Goal**: TaskItem 实体字段契约成立（FR-001~005、FR-007）。

**Independent Test**: quickstart 第 1 步中 defaults/ordering 测试通过。

- [x] T002 [P] [US1] 创建 `Sources/BetterThingsKit/TaskItem.swift`：`@Model final class TaskItem`，字段 `title: String`、`note: String?`、`createdAt: Date = .now`、`isCompleted = false`、`completedAt: Date? = nil`，init 注入标题/备注/创建时间（FR-001~005、FR-007、FR-008）
- [x] T003 [P] [US1] 创建 `Tests/BetterThingsKitTests/TaskItemTests.swift`：默认值断言（US1/AC1、AC2）+ 创建时间可排序断言（FR-007）

## Phase 3: User Story 2 — 完成状态变更保持时间不变量 (Priority: P2)

**Goal**: complete/reopen 联动行为成立（FR-006）。

**Independent Test**: quickstart 第 1 步中 complete/reopen 测试通过。

- [x] T004 [US2] 在 `Sources/BetterThingsKit/TaskItem.swift` 追加 `complete(at: Date = .now)` 与 `reopen()` 方法（data-model 不变量 1/2）
- [x] T005 [US2] 在 `TaskItemTests.swift` 追加联动测试：完成记录注入时刻、取消完成清空时刻（US2/AC1、AC2）

## Phase 4: User Story 3 — 模型可被持久化机制注册 (Priority: P3)

**Goal**: 注册冒烟通过（FR-009）。

**Independent Test**: quickstart 第 1 步中 schema/container 测试通过。

- [x] T006 [US3] 在 `TaskItemTests.swift` 追加内存 `ModelContainer(for: TaskItem.self)` 注册测试（US3/AC1，D4）

## Phase 5: Polish & Cross-Cutting

- [x] T007 执行 `swift test` 全量回归（含 001 特性既有测试）
- [x] T008 [US3] 边界回归：`grep -rn "import SwiftData\|ModelContainer" App/` 输出 CLEAN（SC-002，BT-7 门预检）
- [x] T009 执行应用构建 `xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" -configuration Debug build`，确认零回归（quickstart 第 3 步）

## Dependencies

- T002 → T003/T004/T005/T006（模型先于一切测试）
- T004 → T005（先方法后测试？否：测试与实现同文件增量，T005 依赖 T004）
- T007 依赖 T003/T005/T006；T008/T009 依赖 T002（源码就位后检查才有意义）

## Parallel Execution Examples

- T002 完成后：T003 与 T005/T006 的编写可并行（同文件追加时注意顺序执行）
- T008 与 T009 可并行

## Implementation Strategy

- **MVP = Phase 2（US1）**：字段契约成立即满足 BT-8 卡面验收「模型可构建」
- US2/US3 是宪法 IV 的落实项，随同迭代交付
- 全程不触碰 `App/` 目录
