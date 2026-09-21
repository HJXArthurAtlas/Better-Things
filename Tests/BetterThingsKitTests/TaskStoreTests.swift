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
