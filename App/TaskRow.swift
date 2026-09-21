import SwiftUI
import BetterThingsKit

struct TaskRow: View {
    let task: TaskItem
    var onToggle: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            // 勾选经 complete/reopen，维护完成时间不变量（FR-004）
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)
                .font(.title3)
                .onTapGesture {
                    task.isCompleted ? task.reopen() : task.complete()
                    onToggle()
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                if let note = task.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
