# Data Model: 任务实体 TaskItem

**Date**: 2026-09-21 | **特性**: BT-8

## 实体：TaskItem（待办任务）

| 字段 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `title` | 文本 | ✅ 必填语义 | — | 任务标题；空值拦截在录入层（BT-10） |
| `note` | 文本 | 可空 | 空 | 备注 |
| `createdAt` | 时刻 | ✅ | 创建时刻 | 排序键（FR-007），按创建时间倒序读取 |
| `isCompleted` | 布尔 | ✅ | 未完成 | 完成状态 |
| `completedAt` | 时刻 | 可空 | 空 | 完成时刻；未完成时必须为空 |

## 不变量

1. `completedAt == nil` ⟺ 语义上未完成（`isCompleted == false`）。
2. 状态联动只能经 `complete(at:)` / `reopen()` 发生（D2）。

## 状态转移

```
            complete(at:)                reopen()
  [未完成] ───────────────► [已完成] ───────────────► [未完成]
  completedAt = nil          completedAt = at          completedAt = nil
```

## 关系

无关联实体（单实体特性）。
