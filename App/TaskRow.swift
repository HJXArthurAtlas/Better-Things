import SwiftUI
import BetterThingsKit

/// 任务行：勾选框 13pt + 标题 16pt + 备注图标；行高 27，选中态 #3A3D3F 圆角 6。
/// 形态对照设计稿：普通（空心圆）/ 某天（虚线圆）/ 废纸篓项目归属（两行式：蓝勾 + 日期，次行来源）。
/// 选中且 expandable 时展开为卡片（画板「今天（卡片展开）」）：#3B3B3D 圆角 10 + 投影悬浮，
/// 标题/备注内联可编辑、★今天调度行、右侧旗标；展开/收起 ≈0.28s spring（对照 Things 动效）。
/// 新建草稿（isDraft）：标题占位「新的待办」、自动聚焦、空标题结束即丢弃。
struct TaskRowView: View {
    let task: TaskItem
    /// 虚线勾选框（某天分区未确认语义）
    var dashedCheckbox: Bool = false
    /// 废纸篓已完成行：蓝色日期 + 次行来源分区
    var completedDetail: (date: String, source: String)? = nil
    var isSelected: Bool = false
    /// 选中时展开为卡片（开放列表专用；日志簿/废纸篓/计划保持单行）
    var expandable: Bool = false
    /// 新建草稿（顶部直接展开的空卡片）
    var isDraft: Bool = false
    var onToggle: () -> Void = {}
    var onSelect: () -> Void = {}
    var onEdit: () -> Void = {}
    var onTrash: () -> Void = {}
    var onRestore: () -> Void = {}
    var onMove: (TaskSection) -> Void = { _ in }
    /// 旗标/★今天 点击 → 打开日历调度弹窗（nil = 不支持调度）
    var onSchedule: (() -> Void)? = nil
    /// 草稿/内联编辑结束（Esc、备注 Enter、点击空白）：空标题草稿丢弃，其余落盘
    var onEndDraft: (TaskItem) -> Void = { _ in }
    /// 卡片编辑落盘（标题/备注修改后由行内提交）
    var onCommit: () -> Void = {}

    private enum CardField: Hashable { case title, note }

    @FocusState private var focused: CardField?
    /// 展开前标题（空标题提交时回退）
    @State private var revertTitle: String?
    @State private var revertNote: String?

    private var hasNote: Bool {
        guard let note = task.note else { return false }
        return !note.isEmpty
    }

    private var isExpanded: Bool { expandable && isSelected && !task.isTrashed }

    var body: some View {
        if isExpanded {
            expandedCard
        } else {
            compactRow
        }
    }

    // MARK: 单行形态

    private var compactRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                checkbox
                Text(task.title)
                    .font(.system(size: 16))
                    .foregroundStyle(BT.primary)
                if hasNote, completedDetail == nil {
                    Image(systemName: "note.text")
                        .font(.system(size: 11))
                        .foregroundStyle(BT.secondary)
                }
                Spacer(minLength: 0)
                if let detail = completedDetail {
                    Text(detail.date)
                        .font(.system(size: 13))
                        .foregroundStyle(BT.accent)
                }
            }
            if let detail = completedDetail {
                Text("来源：\(detail.source)")
                    .font(.system(size: 13))
                    .foregroundStyle(BT.secondary)
                    .padding(.leading, 23)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, completedDetail == nil ? 0 : 4)
        .frame(maxWidth: .infinity, minHeight: completedDetail == nil ? 27 : 44, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? BT.selected : .clear)
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .simultaneousGesture(TapGesture(count: 2).onEnded { onEdit() })
        .contextMenu { contextMenu }
    }

    // MARK: 展开卡片（设计稿：卡片 586×112 圆角10 #3B3B3D + 投影；标题/备注/调度行/旗标）

    private var isDueToday: Bool {
        task.dueDate.map(Calendar.current.isDateInToday) ?? false
    }

    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                checkbox
                TextField("新的待办", text: titleBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundStyle(BT.primary)
                    .focused($focused, equals: .title)
                    .onSubmit { focused = .note }
            }
            TextField("备注", text: noteBinding, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(BT.secondary)
                .lineLimit(1...4)
                .padding(.leading, 23)
                .padding(.top, 6)
                .focused($focused, equals: .note)
                .onSubmit { endDraft() }
            HStack(spacing: 10) {
                if isDueToday {
                    Button {
                        onSchedule?()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(BT.star)
                            Text("今天")
                                .font(.system(size: 14))
                                .foregroundStyle(BT.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                if !task.isCompleted {
                    Button {
                        onSchedule?()
                    } label: {
                        Image(systemName: "flag")
                            .font(.system(size: 14))
                            .foregroundStyle(task.dueDate == nil ? BT.secondary : BT.star)
                    }
                    .buttonStyle(.plain)
                    .help("截止日期")
                }
            }
            .padding(.leading, 23)
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(BT.card)
                .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 3)
        }
        // 呼吸留白在卡片背景之外：卡缘→相邻行 ≈28pt（Things 实测 32-34 含行内空隙）
        .padding(.vertical, 28)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .simultaneousGesture(TapGesture(count: 2).onEnded { onEdit() })
        .contextMenu { contextMenu }
        .onExitCommand { endDraft() }
        .onAppear {
            revertTitle = task.title
            revertNote = task.note
            if isDraft { focused = .title }
        }
        .onChange(of: focused) { _, _ in commitEdits() }
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { task.title },
            set: { task.title = $0 }
        )
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { task.note ?? "" },
            set: { task.note = $0.isEmpty ? nil : $0 }
        )
    }

    /// 焦点变化即提交：空标题回退既有值 / 丢弃空白草稿由外层 endDraft 处理
    private func commitEdits() {
        guard focused == nil else { return }
        if task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isDraft,
           let revertTitle {
            task.title = revertTitle
            task.note = revertNote
        }
        onCommit()
    }

    private func endDraft() {
        commitEdits()
        onEndDraft(task)
        focused = nil
    }

    // MARK: 公共部件

    @ViewBuilder private var checkbox: some View {
        let symbol: String = {
            if task.isCompleted { return "checkmark.circle.fill" }
            return dashedCheckbox ? "circle.dashed" : "circle"
        }()
        let tint = task.isCompleted ? BT.accent : BT.secondary
        if isDraft {
            // 未提交草稿：静态占位圈
            Image(systemName: "circle")
                .font(.system(size: 13))
                .foregroundStyle(BT.secondary)
                .opacity(0.6)
        } else {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(tint)
                .onTapGesture {
                    task.isCompleted ? task.reopen() : task.complete()
                    onToggle()
                }
        }
    }

    @ViewBuilder private var contextMenu: some View {
        if task.isTrashed {
            Button("恢复") { onRestore() }
        } else {
            Menu("移动到") {
                ForEach(TaskSection.storedCases.filter { $0 != task.taskSection }, id: \.self) { target in
                    Button(target.displayName) { onMove(target) }
                }
            }
            Button("删除", role: .destructive) { onTrash() }
        }
    }
}
