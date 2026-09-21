# Feature Specification: 初始化 BetterThingsKit 共享核心包并接入应用外壳

**Feature Branch**: `001-bootstrap-betterthingskit`

**Created**: 2026-09-21

**Status**: Draft

**Input**: User description: "YouTrack 卡 BT-6：初始化 BetterThingsKit SPM 包并接入 App target。验收：App 可 import BetterThingsKit 并编译通过。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 应用外壳调用共享核心库 (Priority: P1)

开发者（或贡献者）克隆仓库后，在应用外壳代码中导入共享核心库 `BetterThingsKit`，
调用其公开接口，项目整体构建并运行成功。这确立了"App 只做 UI 壳、逻辑在核心包"
的最小可工作结构。

**Why this priority**: 这是整个项目架构原则 II（核心与壳分离）的物理载体；没有它，
后续所有数据层与功能开发没有落点。

**Independent Test**: 在外壳代码中添加一行对核心库接口的调用，执行标准构建，
构建成功且行为符合接口约定。

**Acceptance Scenarios**:

1. **Given** 干净克隆的仓库与本机已装工具链，**When** 执行标准构建命令，**Then** 构建一次通过，无警告级错误。
2. **Given** 应用外壳已导入核心库，**When** 外壳调用核心库公开的示例接口，**Then** 返回结果符合接口约定并在界面上可见。

### User Story 2 - 核心库可独立构建与测试 (Priority: P2)

贡献者不打开应用工程、不运行应用，仅针对核心库执行测试命令，即可验证核心库自身
的正确性。核心库的开发迭代不依赖应用外壳。

**Why this priority**: 原则 IV（测试护核心）要求核心逻辑可独立验证；这是未来
iOS 复用与 Rust 移植的验收机制基础。

**Independent Test**: 进入核心库目录执行测试命令，测试全部通过且不依赖应用工程。

**Acceptance Scenarios**:

1. **Given** 干净克隆的仓库，**When** 仅对核心库执行测试命令，**Then** 至少 1 个健全性测试通过。
2. **Given** 核心库代码被修改，**When** 重新执行测试命令，**Then** 测试反映最新代码（非缓存假象）。

### User Story 3 - 依赖边界可机械验证 (Priority: P3)

任何人通过检视应用外壳源码，即可确认外壳没有绕过核心库直接访问持久化机制。
违反边界的代码会立即在检视或构建中暴露。

**Why this priority**: 边界是长期约定，越早可验证越不容易被无意破坏；但它依赖
前两个故事先成立。

**Independent Test**: 在应用外壳源码中检索对持久化机制的直接引用，命中数为 0。

**Acceptance Scenarios**:

1. **Given** 全部应用外壳源码，**When** 检索对持久化机制的直接引用（导入持久化框架、构造持久化容器），**Then** 命中数为 0。

### Edge Cases

- 外壳与核心库出现循环依赖时：构建 MUST 失败并明确报错（依赖工具的天然行为，不需额外代码）。
- 干净机器缺少工具链时：构建失败信息 MUST 能指向缺失的前置条件；README 记录前置要求。
- 核心库尚未提供任何业务接口时：外壳 MUST 提供占位内容展示，不出现空白窗口或崩溃。

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 系统 MUST 提供名为 `BetterThingsKit` 的独立共享核心库，支持独立构建。
- **FR-002**: 应用外壳 MUST 依赖该核心库，并能调用其公开接口。
- **FR-003**: 核心库 MUST 提供自动化测试入口，初始包含至少一个健全性测试。
- **FR-004**: 应用外壳源码 MUST NOT 直接引用持久化机制（含导入持久化框架、构造持久化容器）；数据访问 MUST 经核心库接口。
- **FR-005**: 核心库 MUST 以 `BetterThingsKit` 作为稳定模块名对外暴露，作为三端（macOS/iOS/Windows 壳）共享的接口契约起点。
- **FR-006**: 仓库在干净克隆状态下 MUST 可复现构建，不依赖任何本机特殊状态或未提交文件。
- **FR-007**: 应用外壳 MUST 提供最小可运行的占位界面，证明进程可启动且核心库可达。

### Key Entities *(include if feature involves data)*

本特性不引入业务数据实体（任务模型属于后续特性"定义 TaskItem 数据模型"，BT-8）。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 干净克隆后执行标准构建命令，一次通过。
- **SC-002**: 核心库测试命令全部通过，测试数量 ≥ 1。
- **SC-003**: 应用外壳源码中对持久化机制的直接引用文件数为 0。
- **SC-004**: 新贡献者从克隆到本机运行应用成功，全程 ≤ 10 分钟（不含工具链下载时间）。

## Assumptions

- 开发环境为安装了 Apple 官方工具链的 macOS 机器（见宪法·技术约束）。
- 本特性交付的应用外壳是最小占位窗口；完整 UI 由后续特性（BT-14 主窗口布局）实现。
- 仓库 git 已初始化并绑定远程（已完成）。
- 「标准构建命令」以仓库根目录提供的构建入口为准，在 plan 阶段确定为唯一写法并写入 README。
