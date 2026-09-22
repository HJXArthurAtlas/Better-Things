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
    /// 项目集合，按创建时间正序（侧栏顺序稳定）
    public private(set) var projects: [Project] = []
    /// 区域集合，按创建时间正序（侧栏顺序稳定）
    public private(set) var areas: [Area] = []

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
        container = try ModelContainer(
            for: TaskItem.self, Project.self, Area.self, configurations: configuration
        )
        load()
    }

    /// 添加任务（新任务创建时间最新，重建集合后自然置顶；projectID 归属可选）
    @discardableResult
    public func add(
        title: String, note: String? = nil,
        section: TaskSection = .inbox, dueDate: Date? = nil, projectID: UUID? = nil
    ) -> TaskItem {
        let task = TaskItem(title: title, note: note, section: section, dueDate: dueDate, projectID: projectID)
        context.insert(task)
        refresh()
        persist()
        return task
    }

    // MARK: 分区查询

    /// 指定分区的未完成任务（排除废纸篓；按创建时间倒序）。
    /// 收件箱只收无项目归属的任务；今天/计划/随时/某天聚合含项目任务。
    public func openTasks(in section: TaskSection) -> [TaskItem] {
        tasks.filter {
            $0.taskSection == section && !$0.isCompleted && !$0.isTrashed
                && (section != .inbox || $0.projectID == nil)
        }
    }

    /// 日志簿：全部已完成且未删除的任务（完成时间倒序）
    public var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted && !$0.isTrashed }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// 废纸篓：全部已删除任务（删除时间倒序）
    public var trashedTasks: [TaskItem] {
        tasks.filter { $0.isTrashed }
            .sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    /// 移动任务到指定分区（logbook/trash 为派生视图，不可作为目标）
    public func move(_ task: TaskItem, to section: TaskSection) {
        guard section != .logbook, section != .trash else { return }
        task.section = section.rawValue
        refresh()
        persist()
    }

    // MARK: 项目与区域（新建列表菜单）

    /// 新建项目（可挂区域；空名拦截在录入层）
    @discardableResult
    public func addProject(name: String, note: String? = nil, area: Area? = nil) -> Project {
        let project = Project(name: name, note: note, areaID: area?.id)
        context.insert(project)
        refresh()
        persist()
        return project
    }

    /// 新建区域（空名拦截在录入层）
    @discardableResult
    public func addArea(name: String) -> Area {
        let area = Area(name: name)
        context.insert(area)
        refresh()
        persist()
        return area
    }

    /// 删除项目：其任务保留，归属置空回落（不进废纸篓）
    public func removeProject(_ project: Project) {
        for task in tasks where task.projectID == project.id {
            task.projectID = nil
        }
        context.delete(project)
        refresh()
        persist()
    }

    /// 删除区域：其项目保留，回落为独立项目
    public func removeArea(_ area: Area) {
        for project in projects where project.areaID == area.id {
            project.areaID = nil
        }
        context.delete(area)
        refresh()
        persist()
    }

    /// 项目的未完成任务（排除废纸篓；按创建时间倒序）
    public func openTasks(in project: Project) -> [TaskItem] {
        tasks.filter { $0.projectID == project.id && !$0.isCompleted && !$0.isTrashed }
    }

    /// 区域下全部项目的未完成任务数（侧栏计数徽标）
    public func openTaskCount(in area: Area) -> Int {
        projects.filter { $0.areaID == area.id }
            .reduce(0) { $0 + openTasks(in: $1).count }
    }

    /// 区域下的独立项目（侧栏嵌套展示顺序）
    public func projects(in area: Area) -> [Project] {
        projects.filter { $0.areaID == area.id }
    }

    /// 任务的项目归属（无归属返回 nil）
    public func project(of task: TaskItem) -> Project? {
        guard let id = task.projectID else { return nil }
        return projects.first { $0.id == id }
    }

    // MARK: 搜索（底部工具栏 🔍）

    /// 全库开放任务搜索：标题或备注包含关键字（大小写/变音不敏感），排除已完成与废纸篓
    public func search(_ query: String) -> [TaskItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return tasks.filter { task in
            guard !task.isCompleted, !task.isTrashed else { return false }
            if task.title.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                return true
            }
            return task.note?.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    /// 彻底删除单个任务（仅用于未提交的空白新建草稿；正常删除走废纸篓）
    public func deleteTask(_ task: TaskItem) {
        context.delete(task)
        trashedStack.removeAll { $0 == task.id }
        refresh()
        persist()
    }

    /// 推迟任务到明天：转入计划分区并设日期（已有日期则顺延一天；未安排则设为明天）
    public func postpone(_ task: TaskItem) {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: task.dueDate ?? .now)
        task.dueDate = calendar.date(byAdding: .day, value: 1, to: base)
        task.section = TaskSection.upcoming.rawValue
        refresh()
        persist()
    }

    // MARK: 废纸篓（软删除）

    /// 移入废纸篓（软删除；⌫ 与删除菜单走此路径，⌘Z 可恢复）
    public func trash(_ task: TaskItem) {
        task.trash()
        trashedStack.append(task.id)
        refresh()
        persist()
    }

    /// 恢复指定任务（从废纸篓回到原分区）
    public func restore(_ task: TaskItem) {
        task.restore()
        trashedStack.removeAll { $0 == task.id }
        refresh()
        persist()
    }

    /// 恢复最近一次移入废纸篓的任务。返回是否发生了恢复。
    @discardableResult
    public func restoreLastTrashed() -> Bool {
        guard let id = trashedStack.popLast(),
              let task = tasks.first(where: { $0.id == id }) else { return false }
        task.restore()
        refresh()
        persist()
        return true
    }

    /// 倾倒废纸篓：彻底删除全部废纸篓任务（不可恢复）
    public func emptyTrash() {
        for task in trashedTasks {
            context.delete(task)
            trashedStack.removeAll { $0 == task.id }
        }
        refresh()
        persist()
    }

    /// 立即落盘（属性级修改如勾选完成、编辑标题后由 UI 层调用）
    public func save() throws {
        try context.save()
    }

    private func persist() {
        try? context.save()
    }

    /// 软删除栈（最近移入废纸篓的任务 id，供 ⌘Z 恢复）
    private var trashedStack: [UUID] = []

    /// 全量重载：任务按创建时间倒序，项目/区域按创建时间正序
    public func refresh() {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        tasks = (try? context.fetch(descriptor)) ?? []
        let projectDescriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        projects = (try? context.fetch(projectDescriptor)) ?? []
        let areaDescriptor = FetchDescriptor<Area>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        areas = (try? context.fetch(areaDescriptor)) ?? []
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
            for: TaskItem.self, Project.self, Area.self,
            configurations: ModelConfiguration(url: legacyURL)
        ) else { return }
        let legacyContext = ModelContext(legacyContainer)
        guard let legacyTasks = try? legacyContext.fetch(FetchDescriptor<TaskItem>()),
              !legacyTasks.isEmpty else { return }
        guard let newContainer = try? ModelContainer(
            for: TaskItem.self, Project.self, Area.self,
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
