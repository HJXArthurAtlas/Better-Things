import SwiftUI
import BetterThingsKit

/// 配置好的任务行（SectionViews.makeRow 的开放列表版本，附加卡片展开）。
@MainActor
func openListRow(
    _ task: TaskItem, store: TaskStore, selectedID: Binding<UUID?>,
    dimmed: Bool = false, isDraft: Bool = false,
    onEndDraft: @escaping (TaskItem) -> Void = { _ in }
) -> some View {
    TaskRowView(
        task: task,
        isSelected: selectedID.wrappedValue == task.id,
        expandable: true,
        isDraft: isDraft,
        onToggle: { try? store.save() },
        onSelect: {
            withAnimation(cardAnimation) { selectedID.wrappedValue = task.id }
        },
        onTrash: { store.trash(task) },
        onRestore: { store.restore(task) },
        onMove: { store.move(task, to: $0) },
        onEndDraft: onEndDraft,
        onCommit: { try? store.save() }
    )
    .opacity(dimmed ? 0.5 : 1)
}

/// 项目页标题（设计稿「项目」画板：圈形图标 22 + 标题 24 粗体 + 备注行 13px + "…" 菜单）。
struct ProjectHeader: View {
    let project: Project
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: BT.projectSymbol)
                .font(.system(size: 22))
                .foregroundStyle(BT.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(BT.primary)
                if let note = project.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundStyle(BT.secondary)
                }
            }
            Spacer(minLength: 0)
            Menu {
                Button("删除项目", role: .destructive) { onRemove() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundStyle(BT.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .padding(.horizontal, 24)
        .padding(.top, 69)
        .padding(.bottom, 16)
    }
}

/// 项目页：标题 + 项目任务行（选中展开卡片）。
struct ProjectPageView: View {
    let store: TaskStore
    let project: Project
    @Binding var selectedID: UUID?
    let onRemoveProject: (Project) -> Void
    var draftID: UUID? = nil
    var onEndDraft: (TaskItem) -> Void = { _ in }

    private var tasks: [TaskItem] { store.openTasks(in: project) }

    var body: some View {
        VStack(spacing: 0) {
            ProjectHeader(project: project) { onRemoveProject(project) }
            if tasks.isEmpty {
                WatermarkView(symbol: BT.projectSymbol)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(tasks, id: \.id) { task in
                            openListRow(task, store: store, selectedID: $selectedID,
                                        dimmed: selectedID != nil && task.id != selectedID,
                                        isDraft: task.id == draftID,
                                        onEndDraft: onEndDraft)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .animation(cardAnimation, value: selectedID)
                }
            }
        }
    }
}

/// 区域页：区域标题 + 各项目分组（组头 15px + 1px 下划线，同设计稿分组标题规格）。
struct AreaPageView: View {
    let store: TaskStore
    let area: Area
    @Binding var selectedID: UUID?
    let onRemoveArea: (Area) -> Void
    var draftID: UUID? = nil
    var onEndDraft: (TaskItem) -> Void = { _ in }

    private var projects: [Project] { store.projects(in: area) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: BT.areaSymbol)
                    .font(.system(size: 22))
                    .foregroundStyle(BT.secondary)
                Text(area.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(BT.primary)
                Spacer(minLength: 0)
                Menu {
                    Button("删除区域", role: .destructive) { onRemoveArea(area) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(BT.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }
            .padding(.horizontal, 24)
            .padding(.top, 69)
            .padding(.bottom, 16)
            if projects.isEmpty {
                WatermarkView(symbol: BT.areaSymbol)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(projects, id: \.id) { project in
                            groupHeader(project.name)
                            ForEach(store.openTasks(in: project), id: \.id) { task in
                                openListRow(task, store: store, selectedID: $selectedID,
                                            dimmed: selectedID != nil && task.id != selectedID,
                                            isDraft: task.id == draftID,
                                            onEndDraft: onEndDraft)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .animation(cardAnimation, value: selectedID)
                }
            }
        }
    }

    private func groupHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(BT.primary)
            Rectangle()
                .fill(BT.card)
                .frame(height: 1)
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
