import Testing
import Foundation
import SwiftData
@testable import BetterThingsKit

struct TaskItemTests {
    // MARK: US1 — 字段契约与默认值

    @Test("新建任务默认值符合契约（US1/AC1）")
    func defaults() {
        let task = TaskItem(title: "买牛奶")
        #expect(task.title == "买牛奶")
        #expect(task.note == nil)
        #expect(!task.isCompleted)
        #expect(task.completedAt == nil)
    }

    @Test("备注可指定（US1/AC2）")
    func withNote() {
        let task = TaskItem(title: "买牛奶", note: "两盒")
        #expect(task.note == "两盒")
    }

    @Test("创建时间可排序（FR-007）")
    func createdAtOrdering() {
        let earlier = TaskItem(title: "a", createdAt: Date(timeIntervalSince1970: 100))
        let later = TaskItem(title: "b", createdAt: Date(timeIntervalSince1970: 200))
        #expect(earlier.createdAt < later.createdAt)
    }

    // MARK: US2 — 完成不变量

    @Test("标记完成记录完成时刻（US2/AC1）")
    func completeSetsTimestamp() {
        let task = TaskItem(title: "t")
        let at = Date(timeIntervalSince1970: 1_234)
        task.complete(at: at)
        #expect(task.isCompleted)
        #expect(task.completedAt == at)
    }

    @Test("取消完成清空完成时刻（US2/AC2）")
    func reopenClearsTimestamp() {
        let task = TaskItem(title: "t")
        task.complete()
        task.reopen()
        #expect(!task.isCompleted)
        #expect(task.completedAt == nil)
    }

    // MARK: US3 — 持久化注册

    @Test("模型可注册到持久化机制（US3/AC1）")
    func registersInContainer() throws {
        let container = try ModelContainer(
            for: TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        #expect(container.schema.entities.contains { $0.name == "TaskItem" })
    }
}
