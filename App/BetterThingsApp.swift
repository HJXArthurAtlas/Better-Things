import SwiftUI
import AppKit
import Carbon.HIToolbox
import BetterThingsKit

// 键盘路由（FR-009）：⌫ 删除选中、↑↓ 移动选中。
// 用本地 NSEvent 监视器而非隐藏按钮——隐藏按钮对特殊键不可靠（research D6）。
// 输入框/编辑面板聚焦时（firstResponder 为 NSTextView），事件原样放行给文本编辑。
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: Any?
    private var statusItem: NSStatusItem?
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?

    static func log(_ line: String) {
        let url = URL(fileURLWithPath: "/tmp/bt-keys.log")
        let text = "\(Int(Date().timeIntervalSince1970)) \(line)\n"
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(text.data(using: .utf8)!)
        } else {
            try? text.write(to: url, atomically: false, encoding: .utf8)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupTray()          // BT-15 菜单栏托盘
        setupQuickHotKey()   // BT-16 全局 ⌥Space
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
        NotificationCenter.default.addObserver(
            forName: .btHotKeyPressed, object: nil, queue: .main
        ) { [weak self] _ in
            self?.toggleQuickCapture()
        }
    }

    // MARK: BT-15 托盘：左键在显示/隐藏主窗口间切换

    private func setupTray() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Better Things")
        item.button?.action = #selector(toggleMainWindow)
        item.button?.target = self
        statusItem = item
    }

    @objc private func toggleMainWindow() {
        guard let window = mainWindow else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private var mainWindow: NSWindow? {
        NSApp.windows.first { $0.title == "Better Things" }
    }

    private var quickCaptureWindow: NSWindow? {
        NSApp.windows.first { $0.title == QuickCaptureView.windowTitle }
    }

    // MARK: BT-16 全局 ⌥Space 快速录入

    private func setupQuickHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        var hotKeyID = EventHotKeyID(signature: OSType(0x42_54_48_4B), id: 1)
        let status = RegisterEventHotKey(
            UInt32(kVK_Space), UInt32(optionKey), hotKeyID,
            GetEventDispatcherTarget(), 0, &hotKeyRef
        )
        if status != noErr {
            AppDelegate.log("RegisterEventHotKey ⌥Space failed status=\(status)")
        }
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, _ -> OSStatus in
                NotificationCenter.default.post(name: .btHotKeyPressed, object: nil)
                return noErr
            },
            1, &eventType, nil, &hotKeyHandler
        )
    }

    /// 浮窗可见且为按键窗口时隐藏，否则唤起并聚焦
    private func toggleQuickCapture() {
        guard let window = quickCaptureWindow else {
            QuickWindowRouter.open?()  // 首次唤起：窗口尚未创建
            return
        }
        if window.isVisible && window.isKeyWindow {
            window.orderOut(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }
}

extension Notification.Name {
    static let btDeleteSelected = Notification.Name("bt.deleteSelected")
    static let btUndoDelete = Notification.Name("bt.undoDelete")
    static let btMoveSelection = Notification.Name("bt.moveSelection")
    static let btHotKeyPressed = Notification.Name("bt.hotKeyPressed")
}

/// 浮窗首次创建的桥接：SwiftUI Window scene 惰性创建，
/// AppDelegate（热键路径）在窗口不存在时经此回调触发 openWindow。
enum QuickWindowRouter {
    static var open: (() -> Void)?
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
        .commands {
            // 从 Dock/菜单栏也能唤起快速录入
            CommandGroup(after: .newItem) {
                Button("快速录入") {
                    NotificationCenter.default.post(name: .btHotKeyPressed, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }

        Window(QuickCaptureView.windowTitle, id: "quick-capture") {
            QuickCaptureView(store: store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
