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

    public init(title: String, note: String? = nil, createdAt: Date = .now) {
        self.title = title
        self.note = note
        self.createdAt = createdAt
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
