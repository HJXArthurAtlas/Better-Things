# Research: 初始化 BetterThingsKit 共享核心包并接入应用外壳

**Date**: 2026-09-21 | **Status**: 完成（无遗留 NEEDS CLARIFICATION）

## D1: App 工程如何创建与维护

**Decision**: 使用 XcodeGen（2.46.0）从提交的 `project.yml` 生成 `Better-Things.xcodeproj`，生成物一并提交入库。

**Rationale**: `.pbxproj` 手写不可维护、GUI 创建不可复现（违反 FR-006）；XcodeGen 把工程结构变成
可评审的声明文件。提交生成物使贡献者**无需安装 xcodegen** 即可构建（SC-001/SC-004），
只有修改工程结构时才需要重新生成。

**Alternatives considered**:
- 手写 `.pbxproj`：UUID 格式脆弱、不可评审，排除。
- Tuist：功能更强但引入额外工具链复杂度，单人项目过重，排除。
- 仅用 `swift run` 跑可执行目标模拟 App：无法形成真正的 .app（托盘/通知/分发都需要），
  与后续特性（BT-14/15/19）冲突，排除。

## D2: 包布局

**Decision**: 仓库根即 SPM 包（根 `Package.swift`），App 源码放 `App/`，由 project.yml 声明对本地包的依赖。

**Rationale**: `swift test` 在仓库根直接可用（US2 独立可测）；本地包依赖由 XcodeGen 以
`package: BetterThingsKit` 方式接入，App target 物理上只能见到 Kit 的公开 API。

**Alternatives considered**: Kit 放子目录 `BetterThingsKit/`（需 cd 才能测试，体验差），排除。

## D3: 部署目标与语言模式

**Decision**: macOS 部署目标 15.0；swift-tools-version 6.0。

**Rationale**: 本特性外壳不依赖任何新 API；15.0 在 Xcode 26 工具链下兼顾兼容性，
后续 SwiftData（BT-8，需 14+）无压力。语言模式保持默认，Kit 代码无并发复杂度。

**Alternatives considered**: 26.0（锁死老机器用户，无收益），排除。

## D4: 测试框架

**Decision**: Swift Testing（Swift 6 工具链 `swift package init` 默认生成），入口 `swift test`。

**Rationale**: 工具链自带、零配置；`swift test` 同时跑 Testing 与 XCTest。宪法原则 IV 只要求
"测试存在且可独立运行"，不强制框架。

## D5: 外壳占位界面如何证明"核心库可达"

**Decision**: 窗口正文渲染 `BetterThingsKit.version` 字符串。

**Rationale**: 把"import 成功且编译通过"（BT-6 验收）升级为运行时可见证据（US1 验收场景 2、
FR-007），验证成本为零，删除时也不影响后续特性。
