# Contract: BetterThingsKit 公开 API 增量——TaskStore

**Date**: 2026-09-21 | **基于**: specs/001、002 契约的演进（0.x 阶段）

## 新增公开表面

```swift
/// 任务存取器：增删改查与持久化的唯一入口
@MainActor @Observable
public final class TaskStore {
    /// 任务集合，按创建时间倒序（只读；实体就地修改经 TaskItem 自身）
    public private(set) var tasks: [TaskItem]

    /// 内存模式（测试/预览，不触盘）
    public init(inMemory: Bool) throws
    /// 指定存储位置模式（持久化与测试用）
    public init(url: URL) throws
    /// 应用默认位置模式
    public init() throws

    @discardableResult
    public func add(title: String, note: String? = nil) -> TaskItem
    public func delete(_ task: TaskItem)
    public func save() throws
    public func refresh()
}
```

## 契约规则

1. `tasks` 任意时刻按 `createdAt` 倒序（FR-003）；调用方 MUST NOT 依赖引用相等做 diff。
2. 完成/取消完成 MUST 经 `TaskItem.complete(at:)`/`reopen()`，保存经 `save()` 或运行时自动保存。
3. 空标题拦截在录入层（BT-10），store 不校验。
4. 消费方 MUST NOT import SwiftData；容器/上下文细节不出现在本契约之外（宪法 II）。
