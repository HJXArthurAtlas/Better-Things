import SwiftUI
import BetterThingsKit

/// 编辑面板：在本地副本上编辑，保存才回写——取消即无副作用（FR-006）。
struct EditTaskSheet: View {
    let task: TaskItem
    var onDismiss: () -> Void

    @State private var title: String
    @State private var note: String

    init(task: TaskItem, onDismiss: @escaping () -> Void) {
        self.task = task
        self.onDismiss = onDismiss
        _title = State(initialValue: task.title)
        _note = State(initialValue: task.note ?? "")
    }

    var body: some View {
        Form {
            TextField("标题", text: $title)
            TextField("备注", text: $note, axis: .vertical)
                .lineLimit(3...6)
            HStack {
                Button("取消", role: .cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("保存") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 380)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { task.title = trimmed }
        task.note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        onDismiss()
    }
}
