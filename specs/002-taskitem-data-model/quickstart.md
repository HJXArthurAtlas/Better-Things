# Quickstart: 验证任务数据模型

**Feature**: BT-8 定义 TaskItem 数据模型

## 前置条件

同 specs/001（macOS 15+ / Xcode）。

## 验证步骤

### 1. 核心包测试（覆盖 US1/US2/US3 全部场景）

```bash
swift test
```

**预期**：TaskItemTests 全部通过（字段默认值、排序、完成/取消联动、持久化注册），
原有 BetterThingsKitTests 不回归。

### 2. 依赖边界回归（宪法 II / BT-7 门）

```bash
grep -rn "import SwiftData\|ModelContainer" App/ && echo "VIOLATION" || echo "CLEAN"
```

**预期**：`CLEAN`——Kit 引入 SwiftData 不改变 App 层的零引用。

### 3. 应用构建不回归

```bash
xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" -configuration Debug build
```

**预期**：`BUILD SUCCEEDED`（外壳 UI 无任何变化）。
