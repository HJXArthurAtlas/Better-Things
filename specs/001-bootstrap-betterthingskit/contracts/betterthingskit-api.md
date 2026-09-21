# Contract: BetterThingsKit 公开 API（初始表面）

**Date**: 2026-09-21 | **模块名**: `BetterThingsKit`（FR-005，三端共享契约起点）

## 初始公开接口

```swift
/// Better Things 共享核心包的标识信息
public enum BetterThingsKit {
    /// 包语义化版本，与 Package.swift 及应用版本号保持独立演进
    public static let version: String
}
```

## 契约规则

1. **稳定性**：`0.x` 阶段允许任意破坏性变更，但 MUST 在 YouTrack 对应卡与提交信息中注明；
   `1.0.0` 起遵循语义化版本。
2. **演进方向**（后续特性挂靠点，本特性不实现）：
   - `TaskItem` 数据模型 → BT-8
   - `TaskStore` 增删改查 → BT-9
3. **边界**：持久化框架类型（SwiftData 等）MUST NOT 出现在公开 API 签名中；
   公开接口只暴露值类型与协议（原则 II）。
4. **平台通用性**：公开 API MUST 不依赖 AppKit/UIKit 独有类型，保证未来 iOS target
   与 Rust 核心移植可复用同一契约。
