import SwiftUI
import BetterThingsKit

/// 分区页标题栏：分区彩色图标 22 + 标题 24 粗体。
struct SectionTitleBar: View {
    let section: TaskSection
    var title: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: section.watermarkSymbolName)
                .font(.system(size: 22))
                .foregroundStyle(BT.accentColor(section))
            Text(title ?? section.displayName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(BT.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 69)
        .padding(.bottom, 16)
    }
}

/// 空态水印：分区符号 80pt 白色 6%，居中（设计稿空态规格）。
struct WatermarkView: View {
    let symbol: String

    var body: some View {
        GeometryReader { geo in
            Image(systemName: symbol)
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.06))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

/// 配置好的任务行（统一接线选中/编辑/删除/恢复）。
@MainActor
private func makeRow(
    _ task: TaskItem, store: TaskStore, selectedID: Binding<UUID?>,
    dashed: Bool = false, completedDetail: (date: String, source: String)? = nil,
    expandable: Bool = false, onSchedule: ((TaskItem) -> Void)? = nil,
    dimmed: Bool = false, isDraft: Bool = false,
    onEndDraft: @escaping (TaskItem) -> Void = { _ in },
    onCommit: @escaping () -> Void = {},
    onEdit: @escaping (TaskItem) -> Void
) -> some View {
    TaskRowView(
        task: task,
        dashedCheckbox: dashed,
        completedDetail: completedDetail,
        isSelected: selectedID.wrappedValue == task.id,
        expandable: expandable,
        isDraft: isDraft,
        onToggle: { try? store.save() },
        onSelect: {
            // 单一事务：卡片展开与下方行下移同步（对照 Things 推开动效）
            withAnimation(cardAnimation) { selectedID.wrappedValue = task.id }
        },
        onEdit: { onEdit(task) },
        onTrash: { store.trash(task) },
        onRestore: { store.restore(task) },
        onMove: { store.move(task, to: $0) },
        onSchedule: onSchedule.map { schedule in { schedule(task) } },
        onEndDraft: onEndDraft,
        onCommit: onCommit
    )
    .opacity(dimmed ? 0.5 : 1)
}

/// 展开卡片列表通用动画（对照 Things ≈0.28s spring）
@MainActor
let cardAnimation: Animation = .spring(response: 0.28, dampingFraction: 0.85)

/// 收件箱 / 今天 / 随时 / 以后再说：标题 + 任务行列表 + 空态水印。
struct TaskListView: View {
    let store: TaskStore
    let section: TaskSection
    @Binding var selectedID: UUID?
    let onEdit: (TaskItem) -> Void
    let onSchedule: (TaskItem) -> Void
    /// 新建草稿 id（nil = 无草稿）
    var draftID: UUID? = nil
    var onEndDraft: (TaskItem) -> Void = { _ in }

    private var tasks: [TaskItem] { store.openTasks(in: section) }

    var body: some View {
        VStack(spacing: 0) {
            SectionTitleBar(section: section)
            if tasks.isEmpty {
                WatermarkView(symbol: section.watermarkSymbolName)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(tasks, id: \.id) { task in
                                makeRow(task, store: store, selectedID: $selectedID,
                                        dashed: section == .someday, expandable: true,
                                        onSchedule: onSchedule,
                                        dimmed: selectedID != nil && task.id != selectedID,
                                        isDraft: task.id == draftID,
                                        onEndDraft: onEndDraft,
                                        onCommit: { try? store.save() },
                                        onEdit: onEdit)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                        .animation(cardAnimation, value: selectedID)
                    }
                    .onChange(of: selectedID) { _, newID in
                        guard let newID else { return }
                        withAnimation(cardAnimation) { proxy.scrollTo(newID, anchor: .center) }
                    }
                }
            }
        }
    }
}

/// 计划：按日期分组的未来任务（组头：M月d日 + 相对日 + 下划线）。
struct UpcomingView: View {
    let store: TaskStore
    @Binding var selectedID: UUID?
    let onEdit: (TaskItem) -> Void

    private var tasks: [TaskItem] { store.openTasks(in: .upcoming) }

    private var groups: [(day: Date, label: String, sub: String, items: [TaskItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: tasks) { task -> Date in
            calendar.startOfDay(for: task.dueDate ?? .distantFuture)
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { day, items in
                let label = Self.dayNumber(day)
                let sub = Self.relativeLabel(day)
                return (day, label, sub, items)
            }
    }

    static func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "d日"
        return f.string(from: date)
    }

    static func relativeLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInTomorrow(date) { return "明天" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            SectionTitleBar(section: .upcoming)
            if tasks.isEmpty {
                Text("暂无计划任务")
                    .font(.system(size: 13))
                    .foregroundStyle(BT.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(groups, id: \.day) { group in
                            HStack(spacing: 10) {
                                Text(group.label)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(BT.primary)
                                Text(group.sub)
                                    .font(.system(size: 13))
                                    .foregroundStyle(BT.secondary)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 18)
                            Rectangle()
                                .fill(BT.separator)
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                                .padding(.top, 4)
                            ForEach(group.items, id: \.id) { task in
                                makeRow(task, store: store, selectedID: $selectedID, onEdit: onEdit)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
    }
}

/// 日志簿：已完成任务按完成日期分组（今天/昨天/M月d日），蓝勾白字。
struct LogbookView: View {
    let store: TaskStore
    @Binding var selectedID: UUID?
    let onEdit: (TaskItem) -> Void

    private var groups: [(label: String, items: [TaskItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.completedTasks) { task -> Date in
            calendar.startOfDay(for: task.completedAt ?? .distantPast)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { day, items in
                let label: String
                if calendar.isDateInToday(day) { label = "今天" }
                else if calendar.isDateInYesterday(day) { label = "昨天" }
                else {
                    let f = DateFormatter()
                    f.locale = Locale(identifier: "zh_CN")
                    f.dateFormat = "M月d日"
                    label = f.string(from: day)
                }
                return (label, items)
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            SectionTitleBar(section: .logbook)
            if store.completedTasks.isEmpty {
                WatermarkView(symbol: TaskSection.logbook.watermarkSymbolName)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(groups, id: \.label) { group in
                            Text(group.label)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(BT.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.top, 18)
                            Rectangle()
                                .fill(BT.separator)
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                                .padding(.top, 4)
                            ForEach(group.items, id: \.id) { task in
                                makeRow(task, store: store, selectedID: $selectedID, onEdit: onEdit)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
    }
}

/// 废纸篓：倾倒按钮 + 三种行形态（开放行/带备注/项目归属两行式）。
struct TrashView: View {
    let store: TaskStore
    @Binding var selectedID: UUID?
    let onEdit: (TaskItem) -> Void
    @State private var confirmEmpty = false

    var body: some View {
        VStack(spacing: 0) {
            SectionTitleBar(section: .trash)
            Button {
                confirmEmpty = true
            } label: {
                Text("倾倒废纸篓")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(BT.accent))
            }
            .buttonStyle(.plain)
            .disabled(store.trashedTasks.isEmpty)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .confirmationDialog("倾倒废纸篓", isPresented: $confirmEmpty, titleVisibility: .visible) {
                Button("彻底删除全部废纸篓项目", role: .destructive) { store.emptyTrash() }
            } message: {
                Text("此操作不可撤销。")
            }
            if store.trashedTasks.isEmpty {
                WatermarkView(symbol: TaskSection.trash.watermarkSymbolName)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.trashedTasks, id: \.id) { task in
                            makeRow(
                                task, store: store, selectedID: $selectedID,
                                completedDetail: task.isCompleted
                                    ? (Self.dateLabel(task.deletedAt ?? .now), task.taskSection.displayName)
                                    : nil,
                                onEdit: onEdit
                            )
                        }
                        .padding(.top, 18)
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }

    static func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f.string(from: date)
    }
}
