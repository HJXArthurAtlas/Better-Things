import Foundation
import SwiftData

/// 区域持久化实体：按责任分组项目与待办（侧栏「新建列表 → 新建区域」产物）。
///
/// 不变量：删除区域时其项目不删除，`areaID` 置空回落为独立项目（由 TaskStore 负责）。
@Model
public final class Area {
    /// 区域名（必填语义；空名拦截在录入层，同 BT-10）
    public var name: String
    /// 创建时间（侧栏排序键，按创建时间正序读取）
    public var createdAt: Date
    /// 通用唯一标识（Project.areaID 与侧栏选中态的可持有标识）
    public var id = UUID()

    public init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}
