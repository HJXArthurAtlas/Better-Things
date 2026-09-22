import SwiftUI
import BetterThingsKit

/// 主窗口外壳：侧边栏 + 分区内容路由 + 键盘导航（FR-009）。
struct ContentView: View {
    var store: TaskStore

    @State private var section: TaskSection = .inbox
    @State private var selectedID: UUID?
    @State private var editingTask: TaskItem?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(store: store, selection: $section)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BT.content)
        }
        .frame(minWidth: 935, minHeight: 700)
        .background(BT.content)
        .onAppear {
            QuickWindowRouter.open = { openWindow(id: "quick-capture") }
        }
        .sheet(item: $editingTask) { task in
            EditTaskSheet(task: task) {
                try? store.save()
                editingTask = nil
            }
        }
        .onChange(of: section) { _, _ in selectedID = nil }
        .onReceive(NotificationCenter.default.publisher(for: .btDeleteSelected)) { _ in
            trashSelected()
        }
        .onReceive(NotificationCenter.default.publisher(for: .btUndoDelete)) { _ in
            _ = store.restoreLastTrashed()
        }
        .onReceive(NotificationCenter.default.publisher(for: .btMoveSelection)) { note in
            guard let delta = note.userInfo?["delta"] as? Int else { return }
            moveSelection(delta)
        }
        .onReceive(NotificationCenter.default.publisher(for: .btSelectSection)) { note in
            guard let raw = note.userInfo?["section"] as? String,
                  let target = TaskSection(rawValue: raw) else { return }
            section = target
        }
        .onReceive(NotificationCenter.default.publisher(for: .btEmptyTrash)) { _ in
            store.emptyTrash()
        }
    }

    @ViewBuilder private var content: some View {
        switch section {
        case .inbox, .today, .anytime, .someday:
            TaskListView(store: store, section: section, selectedID: $selectedID, onEdit: { editingTask = $0 })
        case .upcoming:
            UpcomingView(store: store, selectedID: $selectedID, onEdit: { editingTask = $0 })
        case .logbook:
            LogbookView(store: store, selectedID: $selectedID, onEdit: { editingTask = $0 })
        case .trash:
            TrashView(store: store, selectedID: $selectedID, onEdit: { editingTask = $0 })
        }
    }

    /// 当前分区下可见行的顺序（键盘 ↑↓ 的移动范围）
    private var visibleIDs: [UUID] {
        switch section {
        case .logbook: return store.completedTasks.map(\.id)
        case .trash: return store.trashedTasks.map(\.id)
        default: return store.openTasks(in: section).map(\.id)
        }
    }

    private func trashSelected() {
        guard let id = selectedID,
              let task = store.tasks.first(where: { $0.id == id }), !task.isTrashed else { return }
        store.trash(task)
        selectedID = nil
    }

    private func moveSelection(_ delta: Int) {
        let ids = visibleIDs
        guard !ids.isEmpty else { return }
        guard let current = selectedID, let index = ids.firstIndex(of: current) else {
            selectedID = ids.first
            return
        }
        selectedID = ids[max(0, min(ids.count - 1, index + delta))]
    }
}
