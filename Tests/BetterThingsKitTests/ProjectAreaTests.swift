import Testing
import Foundation
@testable import BetterThingsKit

@MainActor
struct ProjectAreaTests {
    // MARK: 工具

    private func temporaryStoreURL() -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("bt-projects-\(UUID().uuidString).sqlite")
        return url
    }

    private func makeStore() throws -> TaskStore {
        try TaskStore(inMemory: true)
    }

    // MARK: 新建列表菜单 — 项目/区域

    @Test("新建项目与区域按创建时间正序排列")
    func addOrdersAscending() throws {
        let store = try makeStore()
        let area = store.addArea(name: "工作")
        _ = store.addProject(name: "示例项目")
        _ = store.addProject(name: "家庭项目", area: area)

        #expect(store.areas.map(\.name) == ["工作"])
        #expect(store.projects.map(\.name) == ["示例项目", "家庭项目"])
        #expect(store.projects(in: area).map(\.name) == ["家庭项目"])
    }

    @Test("项目任务归属查询只含本项目开放任务")
    func projectTaskQuery() throws {
        let store = try makeStore()
        let project = store.addProject(name: "示例项目")
        let other = store.addProject(name: "别的项目")

        let filed = store.add(title: "项目内任务", projectID: project.id)
        _ = store.add(title: "其他项目任务", projectID: other.id)
        _ = store.add(title: "无归属任务")
        filed.complete()
        let trashed = store.add(title: "项目内已删", projectID: project.id)
        store.trash(trashed)
        let reopened = store.add(title: "项目内重新打开", projectID: project.id)

        #expect(store.openTasks(in: project).map(\.title) == ["项目内重新打开"])
        #expect(store.project(of: filed)?.id == project.id)
        #expect(store.project(of: reopened)?.id == project.id)
    }

    @Test("删除项目后任务回落无归属且保留在原分区")
    func removeProjectDetachesTasks() throws {
        let store = try makeStore()
        let project = store.addProject(name: "示例项目")
        let task = store.add(title: "项目内任务", section: .today, projectID: project.id)

        store.removeProject(project)

        #expect(store.projects.isEmpty)
        #expect(task.projectID == nil)
        #expect(store.openTasks(in: .today).map(\.title) == ["项目内任务"])
    }

    @Test("删除区域后项目回落为独立项目")
    func removeAreaDetachesProjects() throws {
        let store = try makeStore()
        let area = store.addArea(name: "工作")
        let project = store.addProject(name: "家庭项目", area: area)

        store.removeArea(area)

        #expect(store.areas.isEmpty)
        #expect(project.areaID == nil)
        #expect(store.projects.map(\.name) == ["家庭项目"])
    }

    @Test("区域计数等于其项目开放任务数合计")
    func areaCountAggregatesProjects() throws {
        let store = try makeStore()
        let area = store.addArea(name: "工作")
        let p1 = store.addProject(name: "项目一", area: area)
        let p2 = store.addProject(name: "项目二", area: area)
        _ = store.add(title: "a", projectID: p1.id)
        _ = store.add(title: "b", projectID: p1.id)
        let done = store.add(title: "c", projectID: p2.id)
        done.complete()
        _ = store.add(title: "d", projectID: p2.id)

        #expect(store.openTaskCount(in: area) == 3)
    }

    @Test("收件箱排除项目任务而今天聚合它们")
    func inboxExcludesFiledTasks() throws {
        let store = try makeStore()
        let project = store.addProject(name: "示例项目")
        _ = store.add(title: "收件箱任务")
        _ = store.add(title: "项目任务", section: .inbox, projectID: project.id)
        _ = store.add(title: "项目今日任务", section: .today, projectID: project.id)

        #expect(store.openTasks(in: .inbox).map(\.title) == ["收件箱任务"])
        #expect(store.openTasks(in: .today).map(\.title) == ["项目今日任务"])
        #expect(store.openTasks(in: project).map(\.title) == ["项目今日任务", "项目任务"])
    }

    @Test("推迟任务转入计划并顺延到明天")
    func postponeMovesToTomorrow() throws {
        let store = try makeStore()
        let calendar = Calendar.current
        let today = calendar.date(byAdding: .hour, value: 2, to: calendar.startOfDay(for: .now))!
        let scheduled = store.add(title: "有日期", section: .today, dueDate: today)
        let unscheduled = store.add(title: "无日期", section: .today)

        store.postpone(scheduled)
        store.postpone(unscheduled)

        #expect(scheduled.taskSection == .upcoming)
        #expect(unscheduled.taskSection == .upcoming)
        #expect(calendar.isDateInTomorrow(scheduled.dueDate!))
        #expect(calendar.isDateInTomorrow(unscheduled.dueDate!))
    }

    // MARK: 搜索

    @Test("搜索命中标题与备注且大小写不敏感")
    func searchMatchesTitleAndNote() throws {
        let store = try makeStore()
        _ = store.add(title: "修复水印缩放回归", note: "见截图")
        _ = store.add(title: "跑设计校验清单", note: "TODO Checklist")

        #expect(store.search("水印").map(\.title) == ["修复水印缩放回归"])
        #expect(store.search("checklist").count == 1)
        #expect(store.search("TODO").count == 1)
    }

    @Test("搜索排除已完成与废纸篓任务")
    func searchExcludesCompletedAndTrashed() throws {
        let store = try makeStore()
        let done = store.add(title: "已完成的水印任务")
        done.complete()
        let trashed = store.add(title: "水印任务在废纸篓")
        store.trash(trashed)
        _ = store.add(title: "开放的水印任务")

        #expect(store.search("水印").map(\.title) == ["开放的水印任务"])
    }

    @Test("空白搜索词返回空集合")
    func searchBlankReturnsEmpty() throws {
        let store = try makeStore()
        _ = store.add(title: "任务")
        #expect(store.search("").isEmpty)
        #expect(store.search("   ").isEmpty)
    }

    // MARK: 持久化

    @Test("项目与区域跨持久化重建保留")
    func persistenceRebuild() throws {
        let url = temporaryStoreURL()
        let first = try TaskStore(url: url)
        let area = first.addArea(name: "工作")
        let project = first.addProject(name: "示例项目", note: "说明", area: area)
        _ = first.add(title: "项目任务", projectID: project.id)

        let reopened = try TaskStore(url: url)
        #expect(reopened.areas.map(\.name) == [area.name])
        #expect(reopened.projects.map(\.name) == [project.name])
        #expect(reopened.projects.first?.areaID == area.id)
        #expect(reopened.projects.first?.note == "说明")
        #expect(reopened.openTasks(in: reopened.projects[0]).count == 1)
    }
}
