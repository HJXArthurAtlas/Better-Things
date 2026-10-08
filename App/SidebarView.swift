import SwiftUI
import BetterThingsKit

/// 侧边栏选中目标：七个分区或某个项目/区域。
enum SidebarItem: Hashable {
    case section(TaskSection)
    case project(UUID)
    case area(UUID)
}

/// 侧边栏（设计稿 NEW-主框架 · 收件箱(空态)）：210 宽、#222222、行 24。
/// 结构：收件箱 → 26 → 今天/计划/随时/以后再说（间距 24）→ 30 → 日志簿/废纸篓
/// → 30 → 独立项目 → 30 → 区域（正方体图标，可折叠展开子项目）。
/// 底部：新建列表（新建项目/区域）@左17 · 设置（列表可见性）@右26，距底 18。
struct SidebarView: View {
    let store: TaskStore
    @Binding var selection: SidebarItem

    /// 设置菜单中隐藏的可选智能列表（计划/随时/以后再说）
    @State private var hiddenLists: Set<TaskSection> = []
    /// 展开显示子项目的区域
    @State private var expandedAreas: Set<UUID> = []
    /// 新建列表弹窗种类（nil = 关闭）
    @State private var creationKind: CreationKind?
    @State private var newName = ""

    enum CreationKind: Identifiable {
        case project, area
        var id: Int { self == .project ? 0 : 1 }
        var title: String { self == .project ? "新建项目" : "新建区域" }
    }

    private let hideableLists: [TaskSection] = [.upcoming, .anytime, .someday]

    /// 收件箱之下的状态分区（受设置菜单可见性控制）
    private var middleSections: [TaskSection] {
        hideableLists.filter { !hiddenLists.contains($0) }
    }

    private var standaloneProjects: [Project] {
        store.projects.filter { $0.areaID == nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionRow(.inbox)
            Spacer().frame(height: 26)
            sectionRow(.today)
            ForEach(middleSections, id: \.self) { section in
                sectionRow(section)
            }
            Spacer().frame(height: 30)
            sectionRow(.logbook)
            sectionRow(.trash)
            if !standaloneProjects.isEmpty {
                Spacer().frame(height: 30)
                ForEach(standaloneProjects, id: \.id) { project in
                    projectRow(project)
                }
            }
            if !store.areas.isEmpty {
                Spacer().frame(height: 30)
                ForEach(store.areas, id: \.id) { area in
                    areaRow(area)
                    if expandedAreas.contains(area.id) {
                        ForEach(store.projects(in: area), id: \.id) { project in
                            projectRow(project)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            bottomBar
        }
        .frame(width: BT.sidebarWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        // padding 在 background 之前：底色全出血到窗口顶（红绿灯区同为侧栏色，无分切缝）
        .padding(.top, 59)
        .background(BT.sidebar)
        .onAppear {
            // 默认展开全部区域（子项目可见，同旧版行为）
            if expandedAreas.isEmpty {
                expandedAreas = Set(store.areas.map(\.id))
            }
        }
        .alert(
            creationKind?.title ?? "",
            isPresented: Binding(
                get: { creationKind != nil },
                set: { if !$0 { creationKind = nil; newName = "" } }
            )
        ) {
            TextField("名称", text: $newName)
            Button("创建") { commitCreation() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("名称留空则不创建")
        }
    }

    // MARK: 行

    private func sectionRow(_ section: TaskSection) -> some View {
        row(
            icon: BT.sidebarSymbol(section), tint: BT.accentColor(section),
            title: section.displayName,
            isSelected: selection == .section(section)
        ) {
            selection = .section(section)
        }
    }

    private func projectRow(_ project: Project) -> some View {
        row(
            icon: BT.projectSymbol, tint: BT.secondary,
            title: project.name,
            isSelected: selection == .project(project.id)
        ) {
            selection = .project(project.id)
        }
    }

    /// 区域行：整行点击导航，正方体图标点击折叠/展开子项目（设计稿 开/闭盖正方体）。
    private func areaRow(_ area: Area) -> some View {
        let expanded = expandedAreas.contains(area.id)
        return HStack(spacing: BT.sidebarIconGap) {
            Image(systemName: expanded ? BT.areaOpenSymbol : BT.areaSymbol)
                .font(.system(size: 14))
                .foregroundStyle(BT.secondary)
                .frame(width: BT.sidebarIconSize, height: BT.sidebarIconSize)
                .contentShape(Rectangle())
                .onTapGesture { toggleArea(area) }
            Text(area.name)
                .font(.system(size: 13))
                .foregroundStyle(BT.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.leading, BT.sidebarLeading)
        .frame(height: BT.sidebarRowHeight)
        .background {
            // 高亮胶囊：194×24 @ x8（r12 = 高/2，两端半圆）
            RoundedRectangle(cornerRadius: BT.sidebarRowHeight / 2)
                .fill(selection == .area(area.id) ? BT.selected : .clear)
                .padding(.horizontal, BT.sidebarPillInset)
        }
        .contentShape(Rectangle())
        .onTapGesture { selection = .area(area.id) }
    }

    private func toggleArea(_ area: Area) {
        if expandedAreas.contains(area.id) {
            expandedAreas.remove(area.id)
        } else {
            expandedAreas.insert(area.id)
        }
    }

    private func row(
        icon: String, tint: Color, title: String,
        isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: BT.sidebarIconGap) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tint)
                .frame(width: BT.sidebarIconSize, height: BT.sidebarIconSize)
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(BT.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.leading, BT.sidebarLeading)
        .frame(height: BT.sidebarRowHeight)
        .background {
            RoundedRectangle(cornerRadius: BT.sidebarRowHeight / 2)
                .fill(isSelected ? BT.selected : .clear)
                .padding(.horizontal, BT.sidebarPillInset)
        }
        .contentShape(Rectangle())
        .onTapGesture { action() }
    }

    // MARK: 底部：新建列表 @左17 · 设置 @右26（设计稿 y668，距底 18）

    private var bottomBar: some View {
        HStack(spacing: 0) {
            newListMenu
            Spacer(minLength: 0)
            settingsMenu
        }
        .padding(.leading, 17)
        .padding(.trailing, 26)
        .padding(.bottom, 18)
    }

    /// 新建列表：添加图标 14 + 文字 12 #98989D（设计稿间距 7）
    private var newListMenu: some View {
        Menu {
            Button("新建项目") { newName = ""; creationKind = .project }
            Button("新建区域") { newName = ""; creationKind = .area }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "plus")
                    .font(.system(size: 13))
                Text("新建列表")
                    .font(.system(size: 12))
            }
            .foregroundStyle(BT.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("新建项目或区域")
    }

    /// 设置：列表可见性（原侧栏筛选功能的去处）
    private var settingsMenu: some View {
        Menu {
            ForEach(hideableLists, id: \.self) { section in
                Button {
                    if hiddenLists.contains(section) {
                        hiddenLists.remove(section)
                    } else {
                        hiddenLists.insert(section)
                    }
                } label: {
                    HStack {
                        Image(systemName: hiddenLists.contains(section) ? "checkmark" : "circle")
                        Text(section.displayName)
                    }
                }
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 13))
                .foregroundStyle(BT.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: BT.sidebarIconSize)
        .help("侧栏列表可见性")
    }

    // MARK: 新建列表落地

    private func commitCreation() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { creationKind = nil; newName = "" }
        guard let kind = creationKind, !trimmed.isEmpty else { return }
        switch kind {
        case .project:
            let project = store.addProject(name: trimmed)
            try? store.save()
            selection = .project(project.id)
        case .area:
            let area = store.addArea(name: trimmed)
            try? store.save()
            expandedAreas.insert(area.id)
            selection = .area(area.id)
        }
    }
}
