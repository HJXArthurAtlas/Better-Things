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

    /// 应用默认存储位置（应用专属命名，BT-21）
    public static func defaultStoreURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        let directory = base.appendingPathComponent("Better Things", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("store.sqlite")
    }

    /// 应用默认位置；首次使用时自动迁移旧版 default.store 数据（旧文件保留不动）
    public convenience init() throws {
        let url = try Self.defaultStoreURL()
        Self.migrateLegacyStoreIfAvailable(into: url)
        try self.init(configuration: ModelConfiguration(url: url))
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
        persist()
        return task
    }

    /// 删除任务（快照入撤销栈，可 undoLastDelete 恢复）
    public func delete(_ task: TaskItem) {
        let snapshot = DeleteSnapshot(
            id: task.id, title: task.title, note: task.note, createdAt: task.createdAt,
            isCompleted: task.isCompleted, completedAt: task.completedAt
        )
        context.delete(task)
        deletedStack.append(snapshot)
        refresh()
        persist()
    }

    /// 撤销最近一次删除：按快照原样重建（含 id 与完成状态）。返回是否发生了恢复。
    @discardableResult
    public func undoLastDelete() -> Bool {
        guard let snapshot = deletedStack.popLast() else { return false }
        let restored = TaskItem(title: snapshot.title, note: snapshot.note, createdAt: snapshot.createdAt)
        restored.id = snapshot.id
        if snapshot.isCompleted {
            restored.complete(at: snapshot.completedAt ?? .now)
        }
        context.insert(restored)
        refresh()
        persist()
        return true
    }

    /// 立即落盘（属性级修改如勾选完成、编辑标题后由 UI 层调用）
    public func save() throws {
        try context.save()
    }

    private func persist() {
        try? context.save()
    }

    struct DeleteSnapshot {
        let id: UUID
        let title: String
        let note: String?
        let createdAt: Date
        let isCompleted: Bool
        let completedAt: Date?
    }

    private var deletedStack: [DeleteSnapshot] = []

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

    /// 旧版共享库名（SwiftData 默认位置，BT-21 之前的存储）
    static func legacyStoreURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("default.store")
    }

    /// 若旧存储存在且新位置尚无数据，将其内容复制到新库。
    /// 旧文件原样保留（防回滚）；任何一步失败都静默跳过，应用以空库继续。
    /// - Parameters:
    ///   - legacyURL: 旧存储位置，默认为 SwiftData 共享库名（BT-21 之前的存储）
    ///   - newURL: 应用专属新存储位置
    static func migrateLegacyStoreIfAvailable(
        from legacyURL: URL = legacyStoreURL(),
        into newURL: URL
    ) {
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }
        // 新库文件已存在即视为已迁移，避免重复插入
        guard !FileManager.default.fileExists(atPath: newURL.path) else { return }
        guard let legacyContainer = try? ModelContainer(
            for: TaskItem.self,
            configurations: ModelConfiguration(url: legacyURL)
        ) else { return }
        let legacyContext = ModelContext(legacyContainer)
        guard let legacyTasks = try? legacyContext.fetch(FetchDescriptor<TaskItem>()),
              !legacyTasks.isEmpty else { return }
        guard let newContainer = try? ModelContainer(
            for: TaskItem.self,
            configurations: ModelConfiguration(url: newURL)
        ) else { return }
        let newContext = ModelContext(newContainer)
        for task in legacyTasks {
            let copy = TaskItem(title: task.title, note: task.note, createdAt: task.createdAt)
            copy.id = task.id
            if task.isCompleted {
                copy.complete(at: task.completedAt ?? .now)
            }
            newContext.insert(copy)
        }
        try? newContext.save()
    }
}
