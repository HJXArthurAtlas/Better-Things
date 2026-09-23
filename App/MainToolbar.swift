import SwiftUI
import BetterThingsKit

/// 主窗口底部工具栏（对照设计稿底栏）。
/// 默认态：新建待办 · 跳转 · 搜索；选中任务态：跳转 · 废纸篓 · 更多。
/// 图标水平间距 70pt（设计稿键位中心距 ~86pt）。
struct MainToolbar: View {
    var hasSelection: Bool = false
    var onNew: () -> Void = {}
    /// 跳转：推迟选中任务到明天
    var onPostpone: () -> Void = {}
    var onSearch: () -> Void = {}
    var onTrash: () -> Void = {}
    /// ⋯ 菜单内容（移动到）
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
                tool("plus.circle", "新建待办", action: onNew)
                tool("arrow.right", "先选择任务", disabled: true, action: onPostpone)
                tool("magnifyingglass", "搜索", action: onSearch)
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
