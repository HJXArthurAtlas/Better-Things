import SwiftUI
import AppKit
import BetterThingsKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

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
}

extension NSWindow {
    /// Things 式大圆角：窗口底透明 + 内容层连续曲率裁切（公开 API；红绿灯/交互不受影响）。
    /// 仅作用于主窗口，幂等可重复调用。
    func applyBetterThingsChrome() {
        guard title == "Better Things" else { return }
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
    /// 菜单「前往」切换分区
    static let btSelectSection = Notification.Name("btSelectSection")
    /// 倾倒废纸篓（菜单栏触发）
    static let btEmptyTrash = Notification.Name("btEmptyTrash")
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
            CommandGroup(replacing: .newItem) {
                Button("倾倒废纸篓", role: .destructive) {
                    NotificationCenter.default.post(name: .btEmptyTrash, object: nil)
                }
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
                }
            }
        }
    }
}
