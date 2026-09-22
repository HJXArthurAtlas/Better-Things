import Foundation

/// 任务所属分区（对应设计稿侧边栏七个入口）。
///
/// 持久化语义：`inbox/today/upcoming/anytime/someday` 为可存储的归属；
/// `logbook` 与 `trash` 是派生视图——logbook = 已完成集合，trash = 已删除集合，
/// 两者不作为 `TaskItem.section` 的存储值。
public enum TaskSection: String, CaseIterable, Codable, Sendable {
    case inbox
    case today
    case upcoming
    case anytime
    case someday
    /// 派生视图：全部已完成待办（按完成时间分组），不作为存储值
    case logbook
    /// 派生视图：全部已删除待办，不作为存储值
    case trash

    /// 侧边栏显示名
    public var displayName: String {
        switch self {
        case .inbox: return "收件箱"
        case .today: return "今天"
        case .upcoming: return "计划"
        case .anytime: return "随时"
        case .someday: return "以后再说"
        case .logbook: return "日志簿"
        case .trash: return "废纸篓"
        }
    }

    /// 对应 SF Symbol（与设计稿图标库标注一致）
    public var symbolName: String {
        switch self {
        case .inbox: return "tray"
        case .today: return "star"
        case .upcoming: return "calendar"
        case .anytime: return "square.stack.3d.up"
        case .someday: return "archivebox"
        case .logbook: return "text.book.closed"
        case .trash: return "trash"
        }
    }

    /// 空态水印符号（实心变体，与设计稿水印一致）
    public var watermarkSymbolName: String {
        switch self {
        case .inbox: return "tray.fill"
        case .today: return "star.fill"
        case .upcoming: return "calendar"
        case .anytime: return "square.stack.3d.up.fill"
        case .someday: return "archivebox.fill"
        case .logbook: return "text.book.closed.fill"
        case .trash: return "trash.fill"
        }
    }

    /// 可作为存储值的分区（logbook/trash 为派生视图）
    public static var storedCases: [TaskSection] { [.inbox, .today, .upcoming, .anytime, .someday] }
}
