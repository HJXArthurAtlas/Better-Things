# Research: 主窗口任务管理

**Date**: 2026-09-21 | **Status**: 完成（无遗留 NEEDS CLARIFICATION）

## D1: 任务标识——为 TaskItem 增加通用唯一 id 字段

**Decision**: TaskItem 增加 `public var id = UUID()` 持久化字段；App 侧以 `UUID?`
持有列表选中项。

**Rationale**: 持久化框架的原生标识类型属于持久化框架——在 App 中引用它必须
import 该框架，违反宪法 II。通用唯一标识是 App 侧唯一"合法可见"的标识。0.x 阶段
schema 变更允许（契约规则），开发库数据作废可接受。

**Alternatives considered**: 用标题当标识（不唯一，排除）；App 侧引用持久化框架
标识类型（违宪，排除）。

## D2: 列表选中与键盘——用系统列表原生能力

**Decision**: 采用系统列表的选择模型（点击/↑↓ 原生支持），挂删除命令（⌫）响应；
⌘N 用视图内隐藏快捷键按钮把焦点送回输入框。

**Rationale**: 系统列表的选择与方向键导航是免费的原生行为；自绘键盘监听是重复造轮子。

## D3: 撤销删除——快照式重放

**Decision**: 删除前快照全部字段，向系统撤销管理器注册"重建任务"的撤销闭包；
⌘Z（系统编辑菜单）触发重放。

**Rationale**: 持久化删除不可逆，重放是标准做法；恢复经存取器 add 走同一数据入口，
不引入第二条创建路径。

## D4: 完成分组的过滤位置

**Decision**: 未完成/已完成两个分组由 store 集合过滤派生（`!isCompleted` /
`isCompleted`），不在 store 增加第二份状态。

**Rationale**: 派生视图无双份状态漂移问题；store 的倒序集合已保证组内顺序。

## D5（实现期修正）: 列表选中改手动实现

**Decision**: 放弃 `List(selection:)` 原生选择，改用 ScrollView + 手动选中高亮 +
隐藏快捷键按钮实现 ↑↓/⌫；行内双击经 `simultaneousGesture(TapGesture(count: 2))`。

**Rationale**: 实测 `List(selection:)` 的选择手势会吞掉行内双击（`TapGesture(count: 2)`
与 `onTapGesture(count: 2)` 在真机语义双击下均不触发）。ScrollView 方案下双击、单击
选中、↑↓/⌫ 全部可控可测；输入框聚焦时方向键/⌫ 归还给文本编辑（守卫判断）。
