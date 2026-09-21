# Data Model: TaskStore 存取语义

**Date**: 2026-09-21 | **特性**: BT-9 | **实体定义**: 沿用 specs/002/data-model.md（TaskItem，无字段变更）

## 存取器状态

```
TaskStore
├── container: ModelContainer      # 持久化容器（内存 / 默认位置 / 指定位置）
├── context: ModelContext          # main context（自动保存开启）
└── tasks: [TaskItem]              # 只读暴露，按 createdAt 倒序
```

## 操作语义

| 操作 | 行为 | 集合维护 |
|---|---|---|
| 初始化 | 建容器（按构造参数）→ 自动加载倒序集合 | 全量重建 |
| `add(title:note:)` | 建实体入上下文 → 重建集合 | 全量重建（新任务 createdAt 最新，自然置顶） |
| `delete(_:)` | 上下文删除 → 重建集合 | 全量重建 |
| `save()` | `context.save()`，可抛错 | 无影响 |
| `refresh()` | 全量重载 | 全量重建 |

## 不变量

1. `tasks` 任意时刻按 `createdAt` 倒序。
2. 任务实体的完成状态修改经 `complete(at:)`/`reopen()`（BT-8 不变量），store 负责其保存。
3. 内存模式构造不创建任何磁盘文件。
