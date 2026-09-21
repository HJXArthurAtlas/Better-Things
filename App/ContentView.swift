import SwiftUI
import BetterThingsKit

struct ContentView: View {
    var store: TaskStore

    @State private var newTitle = ""
    @FocusState private var inputFocused: Bool
    @State private var selectedID: UUID?
    @State private var completedExpanded = false
    @State private var editingTask: TaskItem?

    private var incomplete: [TaskItem] { store.tasks.filter { !$0.isCompleted } }
    private var completed: [TaskItem] { store.tasks.filter { $0.isCompleted } }

    var body: some View {
        VStack(spacing: 0) {
            inputBar
            Divider()
            if store.tasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .frame(minWidth: 480, minHeight: 360)
        .sheet(item: $editingTask) { task in
            EditTaskSheet(task: task) {
                try? store.save()
                editingTask = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .btDeleteSelected)) { _ in
            guard !inputFocused else { return }
            deleteSelected()
        }
        .onReceive(NotificationCenter.default.publisher(for: .btUndoDelete)) { _ in
            guard !inputFocused else { return }
            store.undoLastDelete()
        }
        .onReceive(NotificationCenter.default.publisher(for: .btMoveSelection)) { note in
            guard !inputFocused else { return }
            if let delta = note.userInfo?["delta"] as? Int {
                moveSelection(delta)
            }
        }
    }

    // MARK: 输入栏

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("新任务，回车添加", text: $newTitle)
                .focused($inputFocused)
                .onSubmit(addTask)
                .textFieldStyle(.plain)
                .padding(.vertical, 10)
            Button {
                addTask()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.trailing, 10)
        }
        .padding(.horizontal, 12)
    }

    // MARK: 列表

    private var taskList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    sectionHeader("未完成")
                    ForEach(incomplete) { task in
                        row(for: task)
                    }
                    completedHeader
                    if completedExpanded {
                        ForEach(completed) { task in
                            row(for: task)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .onChange(of: selectedID) { _, newID in
                if let newID {
                    withAnimation { proxy.scrollTo(newID, anchor: .center) }
                }
            }
            .overlay { keyboardShortcuts }
        }
    }

    private func row(for task: TaskItem) -> some View {
        TaskRow(task: task, onToggle: { try? store.save() })
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedID == task.id ? Color.accentColor.opacity(0.20) : Color.clear)
            }
            .contentShape(Rectangle())
            .onTapGesture { selectedID = task.id }
            // 双击编辑（FR-006）：ScrollView 行内 TapGesture(count:2) 可正常识别
            .simultaneousGesture(TapGesture(count: 2).onEnded { editingTask = task })
            .contextMenu {
                Button("删除", role: .destructive) { delete(task) }
            }
            .id(task.id)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private var completedHeader: some View {
        HStack(spacing: 4) {
            Image(systemName: completedExpanded ? "chevron.down" : "chevron.right")
                .font(.caption.weight(.semibold))
            Text("已完成 (\(completed.count))")
        }
        .font(.callout.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .contentShape(Rectangle())
        .onTapGesture { completedExpanded.toggle() }
    }

    // MARK: 空状态

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有任务", systemImage: "tray")
        } description: {
            Text("在上方输入框输入标题，回车添加第一个任务")
        }
    }

    // MARK: 键盘（FR-009）：⌘N 聚焦输入框；↑↓ 与 ⌫ 由键盘监视器路由（见 BetterThingsApp）

    private var keyboardShortcuts: some View {
        Group {
            Button("新建任务") { inputFocused = true }
                .keyboardShortcut("n", modifiers: .command)
        }
        .frame(width: 0, height: 0)
        .opacity(0)
    }

    // MARK: 动作

    private func addTask() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.add(title: trimmed)
        newTitle = ""
        inputFocused = true
    }

    private func moveSelection(_ delta: Int) {
        guard !inputFocused else { return }  // 输入框聚焦时方向键属于文本编辑
        let ids = store.tasks.map(\.id)
        guard !ids.isEmpty else { return }
        guard let current = selectedID, let index = ids.firstIndex(of: current) else {
            selectedID = ids.first
            return
        }
        selectedID = ids[max(0, min(ids.count - 1, index + delta))]
    }

    private func deleteSelected() {
        guard !inputFocused else { return }  // 输入框聚焦时 ⌫ 属于文本编辑
        guard let id = selectedID,
              let task = store.tasks.first(where: { $0.id == id }) else { return }
        delete(task)
    }

    private func delete(_ task: TaskItem) {
        if selectedID == task.id { selectedID = nil }
        store.delete(task)  // 快照入撤销栈；⌘Z 经 .btUndoDelete → undoLastDelete
    }
}
