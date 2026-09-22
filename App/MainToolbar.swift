import SwiftUI
import BetterThingsKit

/// 主窗口底部工具栏（对照设计稿底栏）。
/// 默认态：新建待办 · 日历 · 跳转 · 搜索；选中任务态：跳转 · 废纸篓 · 更多。
/// 图标水平间距 70pt（设计稿键位中心距 ~86pt）。
struct MainToolbar: View {
    var hasSelection: Bool = false
    var onNew: () -> Void = {}
    /// 日历：为选中任务调度截止日期（未选中时禁用）
    var onCalendar: () -> Void = {}
    /// 跳转：推迟选中任务到明天
    var onPostpone: () -> Void = {}
    var onSearch: () -> Void = {}
    var onTrash: () -> Void = {}
    /// ⋯ 菜单内容（移动到/编辑）
    var moreMenu: AnyView = AnyView(EmptyView())

    var body: some View {
        HStack(spacing: 54) {
            if hasSelection {
                tool("arrow.right", "推迟到明天", action: onPostpone)
                tool("trash", "删除", action: onTrash)
                Menu {
                    moreMenu
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(BT.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 16)
                .help("更多")
            } else {
                tool("plus.circle", "新建待办（⌘N）", action: onNew)
                tool("calendar", "先选择任务", disabled: true, action: onCalendar)
                tool("arrow.right", "先选择任务", disabled: true, action: onPostpone)
                tool("magnifyingglass", "搜索（⌘F）", action: onSearch)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 12)
    }

    private func tool(_ symbol: String, _ help: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(BT.secondary)
                .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(help)
    }
}

/// 日历调度弹窗：设定/清除选中任务的截止日期（旗标与 ★今天、底栏日历共用）。
/// 用自定义 Binding 直写：仅用户真实点选日期时落库（onAppear 同步会误触发 onChange）。
struct SchedulePopover: View {
    let store: TaskStore
    let task: TaskItem
    let onDismiss: () -> Void

    private var dateBinding: Binding<Date> {
        Binding(
            get: { task.dueDate ?? Calendar.current.startOfDay(for: .now) },
            set: { task.dueDate = Calendar.current.startOfDay(for: $0); try? store.save() }
        )
    }

    var body: some View {
        VStack(spacing: 10) {
            DatePicker(
                "截止日期",
                selection: dateBinding,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            Button("清除日期") {
                task.dueDate = nil
                try? store.save()
                onDismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(BT.secondary)
        }
        .padding(12)
    }
}
