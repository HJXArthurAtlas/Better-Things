import SwiftUI
import BetterThingsKit

/// 侧边栏选中目标：七个分区或某个项目/区域。
enum SidebarItem: Hashable {
    case section(TaskSection)
    case project(UUID)
    case area(UUID)
}

/// 侧边栏：分区入口 + 独立项目 + 区域（嵌套项目）+ 底部「筛选」。
/// 行几何对照设计稿左栏：文字 x=41、图标 16 @x16、行高 24、选中 219×24 @x10。
struct SidebarView: View {
    let store: TaskStore
    @Binding var selection: SidebarItem

    /// 筛选菜单隐藏的可选智能列表（计划/随时/某天）
    @State private var hiddenLists: Set<TaskSection> = []

    /// 底部工具栏可隐藏的智能列表
    private let hideableLists: [TaskSection] = [.upcoming, .anytime, .someday]

    private var sections: [TaskSection] {
        var result: [TaskSection] = [.inbox, .today]
        result.append(contentsOf: hideableLists.filter { !hiddenLists.contains($0) })
        result.append(contentsOf: [.logbook, .trash])
        return result
    }

    private var standaloneProjects: [Project] {
        store.projects.filter { $0.areaID == nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sections, id: \.self) { section in
                if section == .logbook {
                    Spacer().frame(height: 31)
                }
                sectionRow(section)
            }
            if !standaloneProjects.isEmpty {
                Spacer().frame(height: 16)
                ForEach(standaloneProjects, id: \.id) { project in
                    projectRow(project, indent: false)
                }
            }
            if !store.areas.isEmpty {
                Spacer().frame(height: 16)
                ForEach(store.areas, id: \.id) { area in
                    areaRow(area)
                    ForEach(store.projects(in: area), id: \.id) { project in
                        projectRow(project, indent: true)
                    }
                }
            }
            Spacer(minLength: 0)
            bottomBar
        }
        .frame(width: BT.sidebarWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        // padding 在 background 之前：底色全出血到窗口顶（红绿灯区同为侧栏色，无分切缝）
        .padding(.top, 60)
        .background(BT.sidebar)
    }

    // MARK: 行

    private func sectionRow(_ section: TaskSection) -> some View {
        row(
            icon: BT.sidebarSymbol(section), tint: BT.accentColor(section),
            title: section.displayName, indent: false,
            count: store.openTasks(in: section).count,
            isSelected: selection == .section(section)
        ) {
            selection = .section(section)
        }
    }

    private func projectRow(_ project: Project, indent: Bool) -> some View {
        row(
            icon: BT.projectSymbol, tint: BT.secondary,
            title: project.name, indent: indent,
            count: store.openTasks(in: project).count,
            isSelected: selection == .project(project.id)
        ) {
            selection = .project(project.id)
        }
    }

    private func areaRow(_ area: Area) -> some View {
        row(
            icon: BT.areaSymbol, tint: BT.secondary,
            title: area.name, indent: false,
            count: store.openTaskCount(in: area),
            isSelected: selection == .area(area.id)
        ) {
            selection = .area(area.id)
        }
    }

    private func row(
        icon: String, tint: Color, title: String, indent: Bool,
        count: Int, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tint)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(BT.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
            if count > 0 {
                // 计数文字：白 36%（Things 实测：侧栏底上呈 #797B7B、高亮底上呈 #838385），居中于右弧心 x223
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.36))
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.leading, indent ? 42 : 10)
        .padding(.trailing, 6)
        .frame(height: 24)
        .background {
            // 高亮条：231×24 胶囊 @ x4（r12 = 高/2，两端半圆）
            // 光学同心：图标中心 x18、计数中心 x221 = 弧心 ±2pt 内移（同 Things 灯位 26 vs 弧心 24）
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? BT.selected : .clear)
                .padding(.horizontal, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .padding(.horizontal, 4)
        .padding(.vertical, 0.5)
    }

    // MARK: 底部：筛选（设计稿 筛选14 @199,670）

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            filterMenu
        }
        .padding(.leading, 17)
        .padding(.trailing, 26)
        .padding(.bottom, 14)
    }

    private var filterMenu: some View {
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
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 14))
                .foregroundStyle(BT.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 16)
        .help("筛选侧栏列表")
    }
}
