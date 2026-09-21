# Contract: BetterThingsKit 增量——TaskItem.id

**Date**: 2026-09-21

## 变更

```swift
public var id: UUID   // 通用唯一标识，创建时自动生成；App 侧选中态的可持有标识
```

## 规则

1. 该字段是通用唯一标识（Foundation.UUID），**非持久化框架类型**——App 可合法引用（宪法 II）。
2. 持久化标识仍由框架内部管理，不出现在任何公开签名中。
3. 0.x 阶段 schema 变更允许；开发期本地数据库作废重建可接受。
