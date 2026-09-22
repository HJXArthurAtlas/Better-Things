import SwiftUI
import BetterThingsKit

/// 设计令牌：与设计稿（specs/design-standard.md）逐项对齐。
/// 数值来源为 Penpot 实测，改动前先改设计稿。
enum BT {
    // MARK: 配色

    static let sidebar = Color(red: 0x2D / 255, green: 0x30 / 255, blue: 0x31 / 255)
    static let content = Color(red: 0x2B / 255, green: 0x2D / 255, blue: 0x2D / 255)
    static let primary = Color(red: 0xE9 / 255, green: 0xE9 / 255, blue: 0xEA / 255)
    static let secondary = Color(red: 0x98 / 255, green: 0x98 / 255, blue: 0x9D / 255)
    static let selected = Color(red: 0x3A / 255, green: 0x3D / 255, blue: 0x3F / 255)
    static let separator = Color(red: 0x3B / 255, green: 0x3B / 255, blue: 0x3D / 255)
    static let accent = Color(red: 0x4C / 255, green: 0x9E / 255, blue: 0xEA / 255)
    /// 卡片/悬浮层（展开任务卡片、新建列表菜单，Penpot #3B3B3D）
    static let card = Color(red: 0x3B / 255, green: 0x3B / 255, blue: 0x3D / 255)
    /// 展开卡片时的内容区底色（Things 实测 #2A2D30；行透明 50% 叠于其上）
    static let contentDim = Color(red: 0x2A / 255, green: 0x2D / 255, blue: 0x30 / 255)
    /// 今天的调度星标（Penpot 今天图标 #F7CE45）
    static let star = Color(red: 0xF7 / 255, green: 0xCE / 255, blue: 0x45 / 255)
    /// 新建区域菜单图标（复用标准青 #38B9AC）
    static let teal = Color(red: 0x38 / 255, green: 0xB9 / 255, blue: 0xAC / 255)

    // MARK: 尺寸

    static let sidebarWidth: CGFloat = 239
    static let rowHeight: CGFloat = 27
    static let checkboxSize: CGFloat = 13

    /// 侧栏/页面图标（项目=圆圈、区域=盒形，对应 Penpot SF/项目、SF/区域）
    static let projectSymbol = "circle"
    static let areaSymbol = "shippingbox"

    /// 分区元数据：侧边栏图标（实心）、强调色（与设计稿图标库一致）
    static func sidebarSymbol(_ section: TaskSection) -> String {
        switch section {
        case .inbox: return "tray.fill"
        case .today: return "star.fill"
        case .upcoming: return "calendar"
        case .anytime: return "square.stack.3d.up.fill"
        case .someday: return "archivebox.fill"
        case .logbook: return "text.book.closed.fill"
        case .trash: return "trash.fill"
        }
    }

    static func accentColor(_ section: TaskSection) -> Color {
        switch section {
        case .inbox: return Color(red: 0x4C / 255, green: 0x9E / 255, blue: 0xEA / 255)
        case .today: return Color(red: 0xF7 / 255, green: 0xCE / 255, blue: 0x45 / 255)
        case .upcoming: return Color(red: 0xE0 / 255, green: 0x48 / 255, blue: 0x3E / 255)
        case .anytime: return Color(red: 0x38 / 255, green: 0xB9 / 255, blue: 0xAC / 255)
        case .someday: return Color(red: 0xC9 / 255, green: 0xA9 / 255, blue: 0x6A / 255)
        case .logbook: return Color(red: 0x4C / 255, green: 0xAF / 255, blue: 0x50 / 255)
        case .trash: return Color(red: 0x8E / 255, green: 0x8E / 255, blue: 0x93 / 255)
        }
    }
}
