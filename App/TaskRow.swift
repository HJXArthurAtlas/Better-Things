import SwiftUI
import BetterThingsKit

/// 任务行：勾选框 13pt + 标题 16pt + 备注图标；行高 27，选中态 #3A3D3F 圆角 6。
/// 形态对照设计稿：普通（空心圆）/ 某天（虚线圆）/ 废纸篓项目归属（两行式：蓝勾 + 日期，次行来源）。
struct TaskRowView: View {
    let task: TaskItem
    /// 虚线勾选框（某天分区未确认语义）
    var dashedCheckbox: Bool = false
    /// 废纸篓已完成行：蓝色日期 + 次行来源分区
    var completedDetail: (date: String, source: String)? = nil
    var isSelected: Bool = false
    var onToggle: () -> Void = {}
    var onSelect: () -> Void = {}
    var onEdit: () -> Void = {}
    var onTrash: () -> Void = {}
    var onRestore: () -> Void = {}
    var onMove: (TaskSection) -> Void = { _ in }

    private var hasNote: Bool {
        guard let note = task.note else { return false }
        return !note.isEmpty
    }

    var body: some View {
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

    @ViewBuilder private var checkbox: some View {
        let symbol: String = {
            if task.isCompleted { return "checkmark.circle.fill" }
            return dashedCheckbox ? "circle.dashed" : "circle"
        }()
        let tint = task.isCompleted ? BT.accent : BT.secondary
        Image(systemName: symbol)
            .font(.system(size: 13))
            .foregroundStyle(tint)
            .onTapGesture {
                task.isCompleted ? task.reopen() : task.complete()
                onToggle()
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
