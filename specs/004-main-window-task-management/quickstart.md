# Quickstart: 验证主窗口任务管理

**Feature**: 004（BT-14/10/11/12/13/17）

## 自动化

```bash
swift test   # 全量回归（含 TaskItem.id 唯一性）
grep -rn "import SwiftData\|ModelContainer" App/ && echo VIOLATION || echo CLEAN
xcodebuild -project Better-Things.xcodeproj -scheme "Better Things" -configuration Debug build
```

## 运行时取证清单（验收主路径）

1. 启动应用 → 空状态引导文案可见（BT-14）
2. ⌘N → 输入框聚焦；输入「买牛奶」回车 → 列表顶部出现；输入空白回车 → 无变化（BT-10）
3. 再添加「写周报」；勾选「买牛奶」→ 移入「已完成 (1)」分组（BT-11）
4. 点击分组标题 → 折叠/展开切换（BT-14）
5. 双击「写周报」→ 面板改标题与备注 → 保存 → 列表更新（BT-12）
6. 右键删除「写周报」→ ⌘Z → 恢复（BT-13）
7. ↑↓ 移动选中、⌫ 删除选中（BT-17）
8. 退出重开 → 剩余任务与完成状态原样（持久化）

## 预期

每步截图/录屏取证；全部满足即验收通过。
