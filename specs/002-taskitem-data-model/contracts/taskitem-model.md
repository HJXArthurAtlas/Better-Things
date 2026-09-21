# Contract: BetterThingsKit 公开 API 增量——TaskItem

**Date**: 2026-09-21 | **基于**: specs/001 契约的演进（0.x 阶段，允许破坏性变更）

## 新增公开表面

```swift
/// 待办任务实体（持久化模型）
@Model public final class TaskItem {
    public var title: String          // 必填语义
    public var note: String?          // 可空
    public var createdAt: Date        // 排序键
    public var isCompleted: Bool      // 默认 false
    public var completedAt: Date?     // 未完成时为 nil

    public init(title: String, note: String? = nil, createdAt: Date = .now)
    public func complete(at date: Date = .now)
    public func reopen()
}
```

## 契约规则

1. `complete(at:)` / `reopen()` 是维护完成不变量的**唯一**合法途径（见 data-model 不变量）。
2. 应用外壳导入 `TaskItem` 类型本身合法；**import SwiftData 不合法**（宪法 II，BT-7 回归门）。
3. 后续挂靠：`TaskStore`（BT-9）将以创建时间倒序暴露任务读取接口。
