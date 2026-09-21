# Research: 定义任务数据模型（TaskItem）

**Date**: 2026-09-21 | **Status**: 完成（无遗留 NEEDS CLARIFICATION）

## D1: 实体形态——直接 @Model 类 vs 值类型 + 独立持久化实体

**Decision**: `TaskItem` 直接定义为 SwiftData `@Model` final class，置于 BetterThingsKit。

**Rationale**: 单实体待办场景下，值类型 DTO + 持久化实体的双层映射是零收益的重复代码
（宪法 V·轻量）。App 只从 Kit 导入 `TaskItem` 类型本身，**不 import SwiftData**——
边界（原则 II）由 BT-7 回归检查守护。未来 Rust 核心移植（阶段 3）替换的是 Kit 内部
与 TaskStore 接口实现，UI 经接口消费，模型形态变更不外溢。

**Alternatives considered**: `struct TaskItem` 值模型 + 独立 `PersistentTask` 实体 +
映射层（双倍代码，无当前收益，排除）；协议抽象 `TaskItemProtocol`（单实现协议 =
假抽象，排除）。

## D2: 完成状态联动用方法而非散落赋值

**Decision**: 提供 `complete(at:)` / `reopen()` 方法维护 `isCompleted` 与
`completedAt` 的联动；测试用注入时刻保证确定性。

**Rationale**: 不变量集中一处可测（US2），避免"已完成却无完成时间"的非法状态；
`at:` 参数默认 `.now`，调用方（BT-11 勾选）零成本。

## D3: 空标题不在模型层拦截

**Decision**: 模型允许 `title = ""` 构造；空标题拦截在录入层（BT-10，需求文档 §2）。

**Rationale**: 录入校验是交互职责；模型层拦截会让 BT-10 的输入框校验与模型校验
双份维护，且持久化层偶发脏数据时模型拦截反而制造崩溃。

## D4: 持久化注册的验证方式

**Decision**: 测试中以内存模式构造 `ModelContainer(for: TaskItem.self)`，成功即证明
模型与持久化机制兼容（US3 的可执行化）。

**Rationale**: 比仅构造 Schema 更强——容器注册会校验全部属性键路径；不落盘，
符合原则 III（本特性无持久化写入）。
