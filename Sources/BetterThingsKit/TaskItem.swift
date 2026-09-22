import Foundation
import SwiftData

/// 待办任务持久化实体。
///
/// 契约：specs/002-taskitem-data-model/contracts/taskitem-model.md
/// 不变量：`completedAt == nil` 当且仅当未完成；状态联动只能经 `complete(at:)` / `reopen()`。
@Model
public final class TaskItem {
    /// 标题（必填语义；空标题拦截在录入层，BT-10）
    public var title: String
    /// 备注（可选）
    public var note: String?
    /// 创建时间（排序键，按创建时间倒序读取）
    public var createdAt: Date
    /// 完成状态（新建任务默认未完成）
    public var isCompleted: Bool = false
    /// 完成时间（未完成时为空）
    public var completedAt: Date? = nil
    /// 通用唯一标识（App 侧选中态的可持有标识，非持久化框架类型）
    public var id = UUID()
    /// 所属分区（收件箱/今天/计划/随时/以后再说；默认收件箱）
    public var section: String = TaskSection.inbox.rawValue
    /// 计划视图的日期分组依据（仅计划分区使用；nil 表示未安排）
    public var dueDate: Date? = nil
    /// 删除时间（非空 = 已在废纸篓；nil = 正常集合）
    public var deletedAt: Date? = nil

    public init(
        title: String, note: String? = nil, createdAt: Date = .now,
        section: TaskSection = .inbox, dueDate: Date? = nil
    ) {
        self.title = title
        self.note = note
        self.createdAt = createdAt
        self.section = section.rawValue
        self.dueDate = dueDate
    }

    /// 解析后的分区（section 原始值兜底为收件箱）
    public var taskSection: TaskSection {
        TaskSection(rawValue: section) ?? .inbox
    }

    /// 是否在废纸篓中
    public var isTrashed: Bool { deletedAt != nil }

    /// 移入废纸篓（软删除，保留数据可恢复）
    public func trash(at date: Date = .now) {
        deletedAt = date
    }

    /// 从废纸篓恢复
    public func restore() {
        deletedAt = nil
    }

    /// 标记完成：置完成状态并记录完成时刻
    public func complete(at date: Date = .now) {
        isCompleted = true
        completedAt = date
    }

    /// 取消完成：清除完成状态与完成时刻
    public func reopen() {
        isCompleted = false
        completedAt = nil
    }
}
