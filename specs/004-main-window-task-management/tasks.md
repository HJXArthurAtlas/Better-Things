# Tasks: 主窗口任务管理

**Prerequisites**: spec ✅ | research ✅ | plan ✅ | contracts ✅ | quickstart ✅

## Phase 1: 核心（Kit 增量 + 外壳重构）

- [x] T001 [US1] `Sources/BetterThingsKit/TaskItem.swift` 增加 `public var id = UUID()`（research D1）+ 唯一性测试
- [x] T002 [US1] 重写 `App/BetterThingsApp.swift`：TaskStore 创建（失败内存兜底）与注入
- [x] T003 [US1] 创建 `App/ContentView.swift`：输入栏（回车添加、空白忽略、⌘N 聚焦）+ 未完成列表 + 已完成折叠分组（计数、默认折叠）+ 空状态（FR-001~005/008/009）
- [x] T004 [P] [US2] 创建 `App/TaskRow.swift`：勾选经 complete/reopen、双击回调编辑、右键删除入口（FR-004/006/007）
- [x] T005 [P] [US2] 创建 `App/EditTaskSheet.swift`：副本编辑，保存回写、取消不变（FR-006）
- [x] T006 [US3] `App/ContentView.swift` 追加：右键/⌫ 删除 + ⌘Z 快照重放撤销（FR-007）
- [x] T007 `xcodegen generate` + `swift test` + 构建

## Phase 2: 运行时取证验收

- [x] T008 按 quickstart 取证清单逐项验证（含重启持久化）
- [x] T009 边界检查 CLEAN + 提交推送
