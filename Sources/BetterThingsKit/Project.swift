import Foundation
import SwiftData

/// 项目持久化实体：一组为同一目标组织的待办（侧栏「新建列表 → 新建项目」产物）。
///
/// 不变量：删除项目时其任务不删除，`projectID` 置空回落为无项目归属（由 TaskStore 负责）。
@Model
public final class Project {
    /// 项目名（必填语义；空名拦截在录入层，同 BT-10）
    public var name: String
    /// 项目备注（可选，项目页备注行）
    public var note: String?
    /// 创建时间（侧栏排序键，按创建时间正序读取）
    public var createdAt: Date
    /// 通用唯一标识（TaskItem.projectID 与侧栏选中态的可持有标识）
    public var id = UUID()
    /// 所属区域（nil = 独立项目，直接挂侧栏根部）
    public var areaID: UUID? = nil

    public init(name: String, note: String? = nil, createdAt: Date = .now, areaID: UUID? = nil) {
        self.name = name
        self.note = note
        self.createdAt = createdAt
        self.areaID = areaID
    }
}
