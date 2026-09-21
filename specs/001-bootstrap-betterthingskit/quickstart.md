# Quickstart: 构建与验证

**Feature**: 初始化 BetterThingsKit 共享核心包并接入应用外壳

## 前置条件

- macOS 15+，已安装 Xcode（含命令行工具，`xcode-select -p` 指向 Xcode.app）
- 可选：`brew install xcodegen`（仅修改 `project.yml` / 工程结构时需要；
  仓库已提交生成好的 `Better-Things.xcodeproj`）

## 验证步骤

### 1. 核心库独立测试（→ SC-002，US2）

```bash
swift test
```

**预期**：全部测试通过，测试数 ≥ 1。

### 2. 应用构建（→ SC-001，US1 验收场景 1）

```bash
xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" \
  -configuration Debug build
```

**预期**：`BUILD SUCCEEDED`。

### 3. 应用运行（→ US1 验收场景 2，FR-007）

```bash
open Better-Things.xcodeproj   # Xcode 中 ⌘R 运行
```

**预期**：窗口出现，正文显示 Better Things 版本字符串（该字符串来自 BetterThingsKit，
即"外壳成功调用核心库"的运行时证据）。

### 4. 依赖边界检查（→ SC-003，US3）

```bash
grep -rn "import SwiftData\|ModelContainer" App/ && echo "VIOLATION" || echo "CLEAN"
```

**预期**：`CLEAN`（App 源码零持久化引用）。

## 干净克隆复现（FR-006 / SC-004）

```bash
git clone git@github.com:HJXArthurAtlas/Better-Things.git && cd Better-Things
swift test && xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" build
```

**预期**：两条命令依次成功，全程不需要 xcodegen 或其他本机状态。
