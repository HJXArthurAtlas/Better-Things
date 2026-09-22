import SwiftUI
import BetterThingsKit

/// 侧边栏：七个分区入口 + 计数徽标 + 新建列表（对照设计稿主框架左栏）。
struct SidebarView: View {
    let store: TaskStore
    @Binding var selection: TaskSection

    private let order: [TaskSection] = [.inbox, .today, .upcoming, .anytime, .someday, .logbook, .trash]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(order, id: \.self) { section in
                if section == .logbook {
                    Spacer().frame(height: 31)
                }
                row(section)
            }
            Spacer(minLength: 0)
            Button {
                NotificationCenter.default.post(name: .btHotKeyPressed, object: nil)
            } label: {
                Label("新建列表", systemImage: "plus")
                    .font(.system(size: 13))
                    .foregroundStyle(BT.secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 40)
            .padding(.bottom, 14)
        }
        .frame(width: BT.sidebarWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(BT.sidebar)
        .padding(.top, 40)
    }

    private func count(for section: TaskSection) -> Int? {
        let n = store.openTasks(in: section).count
        return n > 0 ? n : nil
    }

    private func row(_ section: TaskSection) -> some View {
        let isSelected = selection == section
        return HStack(spacing: 10) {
            Image(systemName: BT.sidebarSymbol(section))
                .font(.system(size: 14))
                .foregroundStyle(BT.accentColor(section))
                .frame(width: 16)
            Text(section.displayName)
                .font(.system(size: 13))
                .foregroundStyle(BT.primary)
            Spacer(minLength: 0)
            if let count = count(for: section) {
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundStyle(BT.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(BT.accent.opacity(0.25)))
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .padding(.horizontal, 0)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? BT.selected : .clear)
                .padding(.horizontal, 10)
        }
        .contentShape(Rectangle())
        .onTapGesture { selection = section }
        .padding(.horizontal, 10)
        .padding(.vertical, 0.5)
    }
}
