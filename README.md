# Better Things

桌面 + 移动端待办管理工具。macOS 优先，随后 iOS，再 Windows。

**架构**：每平台原生 UI + 共享核心逻辑（详见 YouTrack 知识库 BT-A-1）。
当前阶段：macOS（SwiftUI + SwiftData），核心逻辑在独立包 `BetterThingsKit`，
App 只做 UI 壳——App 源码禁止直接引用持久化框架（宪法原则 II）。

## 前置条件

- macOS 15+
- Xcode（`xcode-select -p` 指向 Xcode.app）

## 构建与测试

```bash
# 核心库测试（独立于应用）
swift test

# 应用构建
xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" build
```

完整验证步骤见 `specs/001-bootstrap-betterthingskit/quickstart.md`。

## 工程结构

```
Package.swift          # 仓库根即 SPM 包（BetterThingsKit）
Sources/BetterThingsKit/   # 核心库：数据模型与业务逻辑（仅值类型/协议对外）
Tests/BetterThingsKitTests/ # 核心库测试
App/                   # 应用外壳（SwiftUI，禁止 import SwiftData）
project.yml            # XcodeGen 工程声明
Better-Things.xcodeproj/  # 生成物（已提交；修改 project.yml 后需重跑 xcodegen generate）
specs/                 # Spec Kit SDD 产物（spec/plan/tasks/quickstart）
```

> 修改 `project.yml` 后运行 `xcodegen generate` 重新生成工程（需 `brew install xcodegen`）；
> 日常构建与测试不需要它。

## 开发流程

Spec-Driven Development（Spec Kit）：`/speckit.constitution → /speckit.specify →
/speckit.plan → /speckit.tasks → /speckit.implement → /speckit.converge`。
任务管理在 YouTrack（项目 BT）。

## License

MIT（待提交 LICENSE 文件）
