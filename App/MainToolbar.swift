import SwiftUI
import BetterThingsKit

/// 主窗口底部工具栏（设计稿 NEW-主框架「底部快捷按钮」）。
/// 默认态四键：添加 · 计划 · 向右箭头 · 搜索，图标 14、间距 90、整体居中、距底 18。
/// 选中任务态三键：跳转（推迟到明天）· 废纸篓 · 更多（移动到）。
struct MainToolbar: View {
    var hasSelection: Bool = false
    var onNew: () -> Void = {}
    /// 计划：跳转计划视图
    var onUpcoming: () -> Void = {}
    /// 跳转（默认态）：跳到今天
    var onToday: () -> Void = {}
    /// 跳转（选中态）：推迟到明天
    var onPostpone: () -> Void = {}
    var onSearch: () -> Void = {}
    var onTrash: () -> Void = {}
    /// ⋯ 菜单内容（移动到）
    var moreMenu: AnyView = AnyView(EmptyView())

    var body: some View {
        HStack(spacing: 90) {
            if hasSelection {
                tool("arrow.right", "推迟到明天", action: onPostpone)
                tool("trash", "删除", action: onTrash)
                Menu {
                    moreMenu
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(BT.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("更多")
            } else {
                tool("plus", "新建待办", action: onNew)
                tool("calendar", "前往计划", action: onUpcoming)
                tool("arrow.right", "跳转到今天", action: onToday)
                tool("magnifyingglass", "搜索", action: onSearch)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 18)
    }

    private func tool(_ symbol: String, _ help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(BT.secondary)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
