# Research: 实现 TaskStore 任务存取与持久化

**Date**: 2026-09-21 | **Status**: 完成（无遗留 NEEDS CLARIFICATION）

## D1: 上下文策略——mainContext + @MainActor

**Decision**: `TaskStore` 标注 `@MainActor`，持有容器的 main context。

**Rationale**: 单窗口应用的全部界面交互在主线程；main context 的自动保存在主循环
上天然生效。测试以 `@MainActor` 标注即可确定性运行。跨线程上下文合并是当前不存在的
问题，不为其设计。

**Alternatives considered**: 自建后台 context（引入并发合并复杂度，无当前需求，排除）。

## D2: 集合暴露——store 数组而非 UI 端 @Query

**Decision**: store 以 `@Observable` 持有 `public private(set) var tasks: [TaskItem]`，
增删时重建集合；UI 只读该数组。

**Rationale**: SwiftUI 的 `@Query` 要求视图层 import SwiftData，直接违反宪法 II
（App 零持久化引用）。集合只能由 Kit 的 store 暴露——这是架构约束推导出的必然形态，
不只是偏好。任务标题/备注/完成状态的就地修改由 `TaskItem` 自身的 Observable 性质
通知视图，无需 store 参与。

**Alternatives considered**: UI 端 @Query（违宪，排除）；AsyncSequence 流式查询
（单窗口无此并发需求，排除）。

## D3: 保存策略——自动保存兜底 + 显式保存保证确定性

**Decision**: main context 保留自动保存（应用运行时兜底）；store 另提供
`save() throws` 显式保存，持久化重建测试使用显式保存保证确定性。

**Rationale**: 自动保存依赖主循环时机，测试环境不可靠；显式入口让"写入后重建仍在"
成为确定性断言。两者不冲突：save 是幂等的。

## D4: 测试排序的确定性

**Decision**: 添加测试数据后显式为实体赋受控 `createdAt` 再 `refresh()`，
避免同毫秒创建导致的顺序不稳定。

**Rationale**: 排序契约（FR-003）需要可复现的顺序断言；真实时钟不为测试服务。
