import SwiftUI
import AppKit
import BetterThingsKit

// 键盘路由（FR-009）：⌫ 删除选中、↑↓ 移动选中。
// 用本地 NSEvent 监视器而非隐藏按钮——隐藏按钮对特殊键不可靠（research D6）。
// 输入框/编辑面板聚焦时（firstResponder 为 NSTextView），事件原样放行给文本编辑。
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let editing = NSApp.keyWindow?.firstResponder is NSTextView
            guard !editing else { return event }
            switch event.keyCode {
            case 51:  // ⌫ 删除选中
                NotificationCenter.default.post(name: .btDeleteSelected, object: nil)
                return nil
            case 6 where event.modifierFlags.contains(.command):  // ⌘Z 撤销删除
                NotificationCenter.default.post(name: .btUndoDelete, object: nil)
                return nil
            case 125: // ↓
                NotificationCenter.default.post(
                    name: .btMoveSelection, object: nil, userInfo: ["delta": 1])
                return nil
            case 126: // ↑
                NotificationCenter.default.post(
                    name: .btMoveSelection, object: nil, userInfo: ["delta": -1])
                return nil
            default:
                return event
            }
        }
    }
}

@main
struct BetterThingsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store: TaskStore

    init() {
        let created: TaskStore
        do {
            created = try TaskStore()
        } catch {
            // 磁盘容器创建失败时以内存模式兜底，应用仍可用（数据不落盘属降级运行）
            created = try! TaskStore(inMemory: true)
        }
        _store = State(initialValue: created)
    }

    var body: some Scene {
        WindowGroup("Better Things") {
            ContentView(store: store)
        }
    }
}

extension Notification.Name {
    static let btDeleteSelected = Notification.Name("bt.deleteSelected")
    static let btUndoDelete = Notification.Name("bt.undoDelete")
    static let btMoveSelection = Notification.Name("bt.moveSelection")
}
