import SwiftUI
import BetterThingsKit

/// 搜索模式：🔍 进入，跨全库（标题/备注）搜索开放任务；Esc 退出。
struct SearchView: View {
    let store: TaskStore
    @Binding var query: String
    @Binding var selectedID: UUID?
    let onEdit: (TaskItem) -> Void
    let onSchedule: (TaskItem) -> Void
    let onClose: () -> Void

    @FocusState private var fieldFocused: Bool

    private var results: [TaskItem] { store.search(query) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22))
                    .foregroundStyle(BT.secondary)
                TextField("搜索", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(BT.primary)
                    .focused($fieldFocused)
                    .onSubmit { selectedID = results.first?.id }
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(BT.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 69)
            .padding(.bottom, 16)
            content
        }
        .onAppear { fieldFocused = true }
        .onExitCommand { onClose() }
    }

    @ViewBuilder private var content: some View {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hint("输入关键字，搜索全部待办（标题与备注）")
        } else if results.isEmpty {
            hint("无结果")
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(results, id: \.id) { task in
                        openListRow(task, store: store, selectedID: $selectedID,
                                    onEdit: onEdit, onSchedule: onSchedule)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(BT.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 120)
    }
}
