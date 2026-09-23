import SwiftUI
import BetterThingsKit

/// 主窗口外壳：侧边栏 + 内容路由（分区/项目/区域/搜索）+ 底部工具栏 + 键盘导航（FR-009）。
struct ContentView: View {
    var store: TaskStore

    @State private var selection: SidebarItem = .section(.inbox)
    @State private var selectedID: UUID?
    @State private var searchActive = false
    @State private var searchQuery = ""
    /// 内联新建草稿 id（⊕ → 列表顶部直接展开空卡片）
    @State private var draftID: UUID?

    /// 展开卡片是否可见（开放列表 + 有选中）：驱动内容区压暗
    private var cardExpanded: Bool {
        guard selectedTask != nil, !searchActive else { return false }
        switch selection {
        case .section(.logbook), .section(.trash), .section(.upcoming): return false
        default: return true
        }
    }

    /// 当前选中的任务实体（跨视图查找）
    private var selectedTask: TaskItem? {
        guard let selectedID else { return nil }
        return store.tasks.first { $0.id == selectedID }
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(store: store, selection: $selection)
            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(cardExpanded ? BT.contentDim : BT.content)
                    .animation(cardAnimation, value: selectedID)
                    .onTapGesture { collapseCard() }
                MainToolbar(
                    hasSelection: selectedTask != nil,
                    onNew: startInlineCreation,
                    onPostpone: postponeSelected,
                    onSearch: { searchActive = true },
                    onTrash: trashSelected,
                    moreMenu: moreMenu
                )
            }
            .background(BT.content)
        }
        .frame(minWidth: 935, minHeight: 700)
        // hiddenTitleBar 下系统仍保留 ~36pt 顶部安全区，导致内容整体下坠；设计稿坐标从窗口顶起算
        .ignoresSafeArea(.container, edges: .top)
        .background(BT.content)
        .onAppear {
            Self.applyWindowChrome(retries: 8)
        }
        .onChange(of: selection) { _, _ in
            endDraft()
            selectedID = nil
        }
        .onChange(of: selectedID) { _, newID in
            // 选择移出草稿 → 草稿收尾
            if draftID != nil, newID != draftID { endDraft() }
        }
        .onChange(of: searchActive) { _, active in
            if !active { searchQuery = ""; selectedID = nil }
        }
        .onReceive(NotificationCenter.default.publisher(for: .btSelectSection)) { note in
            guard let raw = note.userInfo?["section"] as? String,
                  let target = TaskSection(rawValue: raw) else { return }
            selection = .section(target)
        }
        .onReceive(NotificationCenter.default.publisher(for: .btEmptyTrash)) { _ in
            store.emptyTrash()
        }
    }

    // MARK: 内容路由

    @ViewBuilder private var content: some View {
        if searchActive {
            SearchView(
                store: store, query: $searchQuery, selectedID: $selectedID,
                onClose: { searchActive = false }
            )
        } else {
            switch selection {
            case .section(let section):
                switch section {
                case .inbox, .today, .anytime, .someday:
                    TaskListView(
                        store: store, section: section, selectedID: $selectedID,
                        draftID: draftID, onEndDraft: endDraft
                    )
                case .upcoming:
                    UpcomingView(store: store, selectedID: $selectedID)
                case .logbook:
                    LogbookView(store: store, selectedID: $selectedID)
                case .trash:
                    TrashView(store: store, selectedID: $selectedID)
                }
            case .project(let id):
                if let project = store.projects.first(where: { $0.id == id }) {
                    ProjectPageView(
                        store: store, project: project, selectedID: $selectedID,
                        onRemoveProject: removeProject,
                        draftID: draftID, onEndDraft: endDraft
                    )
                }
            case .area(let id):
                if let area = store.areas.first(where: { $0.id == id }) {
                    AreaPageView(
                        store: store, area: area, selectedID: $selectedID,
                        onRemoveArea: removeArea,
                        draftID: draftID, onEndDraft: endDraft
                    )
                }
            }
        }
    }

    // MARK: 工具栏动作

    private var moreMenu: AnyView {
        AnyView(
            Group {
                Menu("移动到") {
                    ForEach(TaskSection.storedCases, id: \.self) { target in
                        Button(target.displayName) {
                            selectedTask.map { store.move($0, to: target) }
                        }
                    }
                }
            }
        )
    }

    /// 点击内容区空白：草稿先收尾，再收回展开的卡片
    private func collapseCard() {
        endDraft()
        guard selectedID != nil else { return }
        withAnimation(cardAnimation) { selectedID = nil }
    }

    /// 窗口 Chrome 应用（ Things 式圆角 + 红绿灯同心）。
    /// didBecomeKey 可能早于观察者注册而被错过，故从视图侧主动应用并重试直至窗口就绪。
    @MainActor
    static func applyWindowChrome(retries: Int) {
        guard let window = NSApp.windows.first(where: { $0.title == "Better Things" }) else {
            guard retries > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                applyWindowChrome(retries: retries - 1)
            }
            return
        }
        window.applyBetterThingsChrome()
        for delay in [0.05, 0.3, 1.0, 2.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                window.positionTrafficLightsAtCornerArc()
            }
        }
    }

    /// ⊕：当前列表顶部直接展开空卡片（对照 Things 新建待办）
    private func startInlineCreation() {
        endDraft()
        if searchActive { searchActive = false }
        var section = TaskSection.inbox
        var projectID: UUID?
        switch selection {
        case .section(let s) where TaskSection.storedCases.contains(s):
            section = s
        case .project(let id):
            section = .inbox
            projectID = id
        case .area:
            selection = .section(.inbox)
        default:
            break
        }
        let draft = store.add(title: "", section: section, projectID: projectID)
        draftID = draft.id
        selectedID = draft.id
    }

    /// 草稿收尾：空标题丢弃，否则落盘；非草稿任务仅落盘
    private func endDraft(_ task: TaskItem? = nil) {
        defer { draftID = nil }
        guard let id = draftID,
              let draft = store.tasks.first(where: { $0.id == id }) else { return }
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            store.deleteTask(draft)
            if selectedID == id { selectedID = nil }
        } else {
            try? store.save()
        }
    }

    private func postponeSelected() {
        guard let task = selectedTask else { return }
        store.postpone(task)
    }

    private func trashSelected() {
        guard let id = selectedID,
              let task = store.tasks.first(where: { $0.id == id }), !task.isTrashed else { return }
        if id == draftID {
            // 未提交草稿：直接丢弃而非进废纸篓
            endDraft()
            return
        }
        store.trash(task)
        selectedID = nil
    }

    private func removeProject(_ project: Project) {
        store.removeProject(project)
        selection = .section(.inbox)
    }

    private func removeArea(_ area: Area) {
        store.removeArea(area)
        selection = .section(.inbox)
    }
}
