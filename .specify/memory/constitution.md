# Better Things Constitution

## Core Principles

### I. 原生体验优先（Native-First Experience）

每个目标平台 MUST 使用该平台的原生 UI 框架（macOS/iOS: SwiftUI；Windows: WinUI 3）。
WebView 或自绘控件的跨平台 UI 方案（Electron、Tauri、Flutter、Compose Multiplatform）
MUST NOT 使用。理由：产品的第一决策优先级是"每平台最优体验"，WidgetKit、App Intents、
Spotlight、系统级启动速度均为原生专属能力。

### II. 核心与壳分离（Core–Shell Separation）

数据模型与业务逻辑 MUST 位于独立包 `BetterThingsKit`；App target 只做 UI 壳。
App 源码 MUST NOT 直接 import SwiftData 或创建 ModelContainer，数据访问 MUST 经
Kit 暴露的接口。理由：这是阶段 2（iOS 复用）与阶段 3（Rust 核心移植）的结构前提。

### III. 本地优先（Local-First Data）

用户数据 MUST 完整保存在本机（SwiftData/SQLite），应用离线 MUST 完全可用。
网络同步属于后续阶段，MUST NOT 出现在当前版本的依赖或数据路径中。

### IV. 测试护核心（Tests Guard the Core）

Kit 内的全部业务逻辑 MUST 有单元测试；任何重构或跨语言移植（如未来 Swift 核心 →
Rust 核心）的验收标准 = 既有测试翻译后全部通过。UI 层以可运行验收代替单测覆盖。

### V. 规格驱动 + 轻量敏捷（Spec-Driven, Lightweight Agility）

功能开发 MUST 走 Spec Kit SDD 流程（specify → plan → tasks → implement → converge），
先定义 what 与边界，再决定 how。流程保持单人可负担：看板流、WIP=1、
状态只有 待开始/新提交/进行中/已完成。

## 技术约束

- 阶段 1（macOS）：Xcode + SwiftUI + SwiftData，分发为 notarized dmg，暂不上架 App Store。
- 阶段 3（Windows）立项前 MUST NOT 引入 Rust；届时核心移植验收见原则 IV。
- 开发环境绑定 Apple 工具链（macOS + Xcode）。

## 开发工作流

- 文档三层分工，互不重复：决策记录（YouTrack 知识库 BT-A-1）记"为什么"；
  需求文档（BT-A-2）记"做什么/不做什么"；Backlog 卡片记"做到哪"。
- 每张卡开工前置 State=进行中，完成以卡面验收标准全部满足为准。
- 本仓库内 SDD 产物（specs/、 Constitution、任务清单）随代码提交，可评审。

## Governance

- 本宪法是项目内所有开发实践的最高约束，与 YouTrack 决策文档（BT-A-1）冲突时以
  两者中较新者为准，且 MUST 同步修订另一方。
- 修订流程：修改宪法 MUST 记录版本号变更（语义化版本：原则增删或重定义为 MAJOR，
  新增原则或实质扩展为 MINOR，措辞澄清为 PATCH）、修订理由与影响范围。
- 合规检查：/speckit.plan 与 /speckit.implement MUST 对照本宪法；发现冲突时
  停下报告，不得静默绕过。

**Version**: 1.0.0 | **Ratified**: 2026-09-21 | **Last Amended**: 2026-09-21
