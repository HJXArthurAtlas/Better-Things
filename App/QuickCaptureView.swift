import SwiftUI
import AppKit
import BetterThingsKit

/// 快速录入浮窗：常驻隐藏，⌥Space 唤起；回车创建任务并保留浮窗连续录入；
/// Esc 或失焦自动隐藏（FR：BT-16）。
struct QuickCaptureView: View {
    var store: TaskStore

    @State private var title = ""
    @FocusState private var focused: Bool

    static let windowTitle = "快速录入"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
            TextField("快速输入任务，回车继续，Esc 关闭", text: $title)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($focused)
                .onSubmit(add)
        }
        .padding(14)
        .frame(width: 460)
        .background(.bar)
        .onAppear { focused = true }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { note in
            // orderOut 后再唤起不会触发 onAppear——窗口重新成为 key 时必须重新聚焦，
            // 否则 ⌘N/⌥Space 唤起后键盘输入无处落地
            guard let window = note.object as? NSWindow,
                  window.title == Self.windowTitle else { return }
            focused = true
        }
        .onExitCommand { hide() }  // Esc
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { note in
            guard let window = note.object as? NSWindow,
                  window.title == Self.windowTitle else { return }
            hide()  // 失焦自动隐藏
        }
    }

    private func add() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.add(title: trimmed)
        title = ""
        focused = true
    }

    private func hide() {
        title = ""
        focused = false
        // 显式定位浮窗自身——失焦回调触发时 keyWindow 可能已是别的窗口
        if let window = NSApp.windows.first(where: { $0.title == Self.windowTitle }) {
            window.orderOut(nil)
        }
    }
}
