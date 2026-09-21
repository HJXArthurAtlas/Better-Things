# Quickstart: 验证 TaskStore 存取与持久化

**Feature**: BT-9 实现 TaskStore 任务存取与持久化

## 验证步骤

### 1. 全量测试（覆盖 US1/US2/US3 全部场景 + 001/002 回归）

```bash
swift test
```

**预期**：TaskStoreTests（CRUD 倒序、删除、更新反映、重建一致、删除重建、自动加载、
内存模式）+ TaskItemTests + 既有测试全部通过。

### 2. 依赖边界回归（宪法 II / BT-7 门）

```bash
grep -rn "import SwiftData\|ModelContainer" App/ && echo "VIOLATION" || echo "CLEAN"
```

**预期**：`CLEAN`——Kit 已有 ModelContainer 但 App 层仍然零引用。

### 3. 应用构建零回归

```bash
xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" -configuration Debug build
```

**预期**：`BUILD SUCCEEDED`。
