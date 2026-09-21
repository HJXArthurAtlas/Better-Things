import Foundation
import SwiftData
import Observation

/// 任务存取器：增删改查与持久化的唯一入口。
///
/// 契约：specs/003-taskstore-crud/contracts/taskstore-api.md
/// 不变量：`tasks` 任意时刻按 `createdAt` 倒序；完成状态修改经 `TaskItem` 自身方法。
@MainActor
@Observable
public final class TaskStore {
    /// 任务集合，按创建时间倒序（只读；实体就地修改经 TaskItem 自身）
    public private(set) var tasks: [TaskItem] = []

    private let container: ModelContainer

    private var context: ModelContext { container.mainContext }

    /// 应用默认存储位置
    public convenience init() throws {
        try self.init(configuration: ModelConfiguration())
    }

    /// 内存模式（测试/预览，不触碰磁盘）；传 false 等价默认位置
    public convenience init(inMemory: Bool) throws {
        try self.init(configuration: ModelConfiguration(isStoredInMemoryOnly: inMemory))
    }

    /// 指定存储位置模式
    public convenience init(url: URL) throws {
        try self.init(configuration: ModelConfiguration(url: url))
    }

    private init(configuration: ModelConfiguration) throws {
        container = try ModelContainer(for: TaskItem.self, configurations: configuration)
        load()
    }

    /// 添加任务（新任务创建时间最新，重建集合后自然置顶）
    @discardableResult
    public func add(title: String, note: String? = nil) -> TaskItem {
        let task = TaskItem(title: title, note: note)
        context.insert(task)
        refresh()
        return task
    }

    /// 删除任务
    public func delete(_ task: TaskItem) {
        context.delete(task)
        refresh()
    }

    /// 显式保存（应用运行时另有自动保存兜底）
    public func save() throws {
        try context.save()
    }

    /// 全量重载：按创建时间倒序
    public func refresh() {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        tasks = (try? context.fetch(descriptor)) ?? []
    }

    private func load() {
        refresh()
    }
}
