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
        // 窗口聚焦时应用 Things 式大圆角（SwiftUI 窗口惰性创建，需在回调里补；幂等）。
        // 内容首次布局晚于 didBecomeKey，系统随后会把红绿灯排回默认位，需延迟数档重贴。
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { note in
            guard let window = note.object as? NSWindow else { return }
            window.applyBetterThingsChrome()
            for delay in [0.05, 0.3, 1.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    window.positionTrafficLightsAtCornerArc()
                }
            }
        }
        // 窗口 resize 后系统会重排红绿灯，重新对齐弧心
        NotificationCenter.default.addObserver(
            forName: NSWindow.didEndLiveResizeNotification, object: nil, queue: .main
        ) { note in
            (note.object as? NSWindow)?.positionTrafficLightsAtCornerArc()
        }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let editing = NSApp.keyWindow?.firstResponder is NSTextView
            guard !editing else { return event }
            switch event.keyCode {
            case 51:  // ⌫ 删除选中
                NotificationCenter.default.post(name: .btDeleteSelected, object: nil)
                return nil
            case 45 where event.modifierFlags.contains(.command):  // ⌘N 列表内新建待办（展开卡片）
                NotificationCenter.default.post(name: .btCreateInline, object: nil)
                return nil
            case 6 where event.modifierFlags.contains(.command):  // ⌘Z 撤销删除
                NotificationCenter.default.post(name: .btUndoDelete, object: nil)
                return nil
            case 3 where event.modifierFlags.contains(.command):  // ⌘F 搜索
                NotificationCenter.default.post(name: .btToggleSearch, object: nil)
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

extension NSWindow {
    /// Things 式大圆角：窗口底透明 + 内容层连续曲率裁切（公开 API；红绿灯/交互不受影响）。
    /// 仅作用于本应用的两个窗口，幂等可重复调用。
    func applyBetterThingsChrome() {
        guard title == "Better Things" || title == QuickCaptureView.windowTitle else { return }
        backgroundColor = .clear
        isOpaque = false
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 24
        // 实测 Things 的圆角曲线拟合纯圆弧（非超椭圆），用 .circular 精确复刻
        contentView?.layer?.cornerCurve = .circular
        contentView?.layer?.masksToBounds = true
        positionTrafficLightsAtCornerArc()
        invalidateShadow()
    }

    /// 红绿灯同心定位（Apple 设计语言）：元素中心与圆角弧心 (R,R) 重合，
    /// 到上/左边缘距离因此必然相等（= R − 圆半径）；中心距 20pt（12pt 圆 + 8 间隙）。
    /// 窗口 resize 后系统会重排按钮，需重贴。
    func positionTrafficLightsAtCornerArc() {
        let buttons = [
            standardWindowButton(.closeButton),
            standardWindowButton(.miniaturizeButton),
            standardWindowButton(.zoomButton)
        ].compactMap { $0 }
        guard let container = buttons.first?.superview, container.frame.height > 0 else { return }
        let arcCenter = contentView?.layer?.cornerRadius ?? 16   // 与窗口圆角同心
        let centerSpacing: CGFloat = 23                          // Things 实测中心距
        for (index, button) in buttons.enumerated() {
            let origin = arcCenter - button.frame.width / 2      // 两轴同一公式 → 对称
            let x = origin + CGFloat(index) * centerSpacing
            let y = container.frame.height - origin - button.frame.height
            button.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

extension Notification.Name {
    /// 侧边栏切换分区（⌘1~7）
    static let btSelectSection = Notification.Name("btSelectSection")
    /// 倾倒废纸篓（菜单栏触发）
    static let btEmptyTrash = Notification.Name("btEmptyTrash")
    static let btDeleteSelected = Notification.Name("bt.deleteSelected")
    static let btUndoDelete = Notification.Name("bt.undoDelete")
    static let btMoveSelection = Notification.Name("bt.moveSelection")
    static let btHotKeyPressed = Notification.Name("bt.hotKeyPressed")
    static let btToggleSearch = Notification.Name("bt.toggleSearch")
    static let btCreateInline = Notification.Name("bt.createInline")
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
        // 内嵌标题栏（对照设计稿/Things）：红绿灯嵌侧栏、内容直通顶部；背景可拖拽移动窗口
        .windowStyle(.hiddenTitleBar)
        .windowBackgroundDragBehavior(.enabled)
        .commands {
            // 从 Dock/菜单栏也能唤起快速录入（⌘N 与真实 Things 一致）
            CommandGroup(replacing: .newItem) {
                Button("快速录入") {
                    NotificationCenter.default.post(name: .btHotKeyPressed, object: nil)
                }
                Button("倾倒废纸篓", role: .destructive) {
                    NotificationCenter.default.post(name: .btEmptyTrash, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(store.trashedTasks.isEmpty)
            }
            CommandMenu("前往") {
                ForEach(TaskSection.allCases, id: \.self) { section in
                    Button(section.displayName) {
                        NotificationCenter.default.post(
                            name: .btSelectSection, object: nil,
                            userInfo: ["section": section.rawValue]
                        )
                    }
                    .keyboardShortcut(KeyEquivalent(Character(String(TaskSection.allCases.firstIndex(of: section)! + 1))), modifiers: .command)
                }
            }
        }

        Window(QuickCaptureView.windowTitle, id: "quick-capture") {
            QuickCaptureView(store: store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
