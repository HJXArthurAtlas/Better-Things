import Testing
import Foundation
@testable import BetterThingsKit

@MainActor
struct TaskStoreTests {
    // MARK: 工具

    /// 添加任务并赋予受控创建时间，保证排序断言确定（research D4）
    private func seed(_ store: TaskStore, _ title: String, _ ts: TimeInterval) -> TaskItem {
        let task = store.add(title: title)
        task.createdAt = Date(timeIntervalSince1970: ts)
        store.refresh()
        return task
    }

    private func temporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("store.sqlite")
    }

    // MARK: US1 — 增删改查

    @Test("添加任务按创建时间倒序（US1/AC1）")
    func addSortedDesc() throws {
        let store = try TaskStore(inMemory: true)
        seed(store, "a", 100)
        seed(store, "b", 300)
        seed(store, "c", 200)
        #expect(store.tasks.map(\.title) == ["b", "c", "a"])
    }

    @Test("删除任务其余保持原序（US1/AC2）")
    func deleteRemovesOnlyTarget() throws {
        let store = try TaskStore(inMemory: true)
        let a = seed(store, "a", 100)
        seed(store, "b", 300)
        seed(store, "c", 200)
        store.delete(a)
        #expect(store.tasks.map(\.title) == ["b", "c"])
    }

    @Test("就地修改在集合中反映（US1/AC3）")
    func updatesReflected() throws {
        let store = try TaskStore(inMemory: true)
        let task = seed(store, "旧标题", 100)
        task.title = "新标题"
        task.note = "备注"
        task.complete(at: Date(timeIntervalSince1970: 999))
        #expect(store.tasks.first?.title == "新标题")
        #expect(store.tasks.first?.note == "备注")
        #expect(store.tasks.first?.isCompleted == true)
    }

    // MARK: US2 — 落盘重建

    @Test("写入保存后重建一致（US2/AC1）")
    func persistenceRebuild() throws {
        let url = temporaryStoreURL()
        let store = try TaskStore(url: url)
        let done = seed(store, "done", 100)
        done.complete(at: Date(timeIntervalSince1970: 500))
        seed(store, "open", 200)
        try store.save()

        let reopened = try TaskStore(url: url)
        #expect(reopened.tasks.map(\.title) == ["open", "done"])
        let reopenedDone = reopened.tasks.first { $0.title == "done" }
        #expect(reopenedDone?.isCompleted == true)
        #expect(reopenedDone?.completedAt == Date(timeIntervalSince1970: 500))
    }

    @Test("删除保存后重建已删（US2/AC2）")
    func deletePersistsAcrossRebuild() throws {
        let url = temporaryStoreURL()
        let store = try TaskStore(url: url)
        let a = seed(store, "a", 100)
        seed(store, "b", 200)
        try store.save()
        store.delete(a)
        try store.save()

        let reopened = try TaskStore(url: url)
        #expect(reopened.tasks.map(\.title) == ["b"])
    }

    @Test("取消完成的不变量跨持久化成立（Edge）")
    func reopenAcrossPersistence() throws {
        let url = temporaryStoreURL()
        let store = try TaskStore(url: url)
        let task = seed(store, "t", 100)
        task.complete()
        task.reopen()
        try store.save()

        let reopened = try TaskStore(url: url)
        #expect(reopened.tasks.first?.isCompleted == false)
        #expect(reopened.tasks.first?.completedAt == nil)
    }

    // MARK: 撤销删除（BT-13/FR-007）

    @Test("删除后撤销恢复原字段")
    func undoRestoresDeletedFields() throws {
        let store = try TaskStore(inMemory: true)
        let done = seed(store, "done", 100)
        done.complete(at: Date(timeIntervalSince1970: 700))
        let originalID = done.id
        seed(store, "open", 200)
        store.delete(done)
        #expect(store.tasks.map(\.title) == ["open"])

        #expect(store.undoLastDelete())
        #expect(store.tasks.first?.title == "open")  // 倒序不变
        let back = store.tasks.first { $0.title == "done" }
        #expect(back?.id == originalID)
        #expect(back?.isCompleted == true)
        #expect(back?.completedAt == Date(timeIntervalSince1970: 700))
    }

    @Test("空撤销栈返回 false")
    func undoOnEmptyStack() throws {
        let store = try TaskStore(inMemory: true)
        #expect(store.undoLastDelete() == false)
    }

    // MARK: 旧库迁移（BT-21）

    @Test("旧 default.store 数据自动迁移到新位置且旧文件保留")
    func legacyMigration() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let legacyURL = dir.appendingPathComponent("default.store")
        let newURL = dir.appendingPathComponent("store.sqlite")

        // 造旧库：两条任务，其一完成
        let old = try TaskStore(url: legacyURL)
        let done = old.add(title: "迁移-已完成")
        done.complete(at: Date(timeIntervalSince1970: 800))
        seed(old, "迁移-未完成", 100)
        try old.save()
        let legacyMtimeBefore = try FileManager.default.attributesOfItem(atPath: legacyURL.path)[.modificationDate] as? Date

        // 迁移函数：旧库 → 新库
        TaskStore.migrateLegacyStoreIfAvailable(from: legacyURL, into: newURL)

        let migrated = try TaskStore(url: newURL)
        // 倒序：迁移-已完成 创建时间晚于受控的 100
        #expect(migrated.tasks.map(\.title) == ["迁移-已完成", "迁移-未完成"])
        let migratedDone = migrated.tasks.first { $0.title == "迁移-已完成" }
        #expect(migratedDone?.isCompleted == true)
        #expect(migratedDone?.completedAt == Date(timeIntervalSince1970: 800))
        // 旧文件原样保留（防回滚）
        #expect(FileManager.default.fileExists(atPath: legacyURL.path))
        let legacyMtimeAfter = try FileManager.default.attributesOfItem(atPath: legacyURL.path)[.modificationDate] as? Date
        #expect(legacyMtimeBefore == legacyMtimeAfter)
        // 幂等：再次迁移不重复插入
        TaskStore.migrateLegacyStoreIfAvailable(from: legacyURL, into: newURL)
        let afterSecondCall = try TaskStore(url: newURL)
        #expect(afterSecondCall.tasks.count == 2)
    }

    @Test("无旧库时迁移为空操作（BT-21 边界）")
    func migrationWithoutLegacy() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let legacyURL = dir.appendingPathComponent("default.store")  // 不存在的旧库
        let newURL = dir.appendingPathComponent("store.sqlite")
        TaskStore.migrateLegacyStoreIfAvailable(from: legacyURL, into: newURL)
        let store = try TaskStore(url: newURL)
        #expect(store.tasks.isEmpty)
    }

    // MARK: US3 — 打开即加载 / 内存模式

    @Test("初始化即自动加载，无需显式调用（US3/AC1）")
    func autoLoadOnInit() throws {
        let url = temporaryStoreURL()
        let first = try TaskStore(url: url)
        seed(first, "a", 100)
        seed(first, "b", 200)
        try first.save()

        let reopened = try TaskStore(url: url)
        #expect(reopened.tasks.map(\.title) == ["b", "a"])
    }

    @Test("内存模式空集合且与磁盘隔离（US3/AC2）")
    func inMemoryIsolated() throws {
        let store = try TaskStore(inMemory: true)
        store.add(title: "只在内存")
        #expect(store.tasks.count == 1)

        let fresh = try TaskStore(inMemory: true)
        #expect(fresh.tasks.isEmpty)
    }
}
