import Foundation
import SwiftData

@ModelActor
actor TodoRepository: Sendable {
    func fetchTasks() async throws -> [TodoTask] {
        let descriptor = FetchDescriptor<TodoTask>(
            sortBy: [SortDescriptor(\TodoTask.dueDate), SortDescriptor(\TodoTask.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ task: TodoTask) async throws {
        modelContext.insert(task)
        try modelContext.save()
    }

    func update(_ task: TodoTask, title: String, subtitle: String?, dueDate: Date) async throws {
        task.title = title
        task.subtitle = subtitle
        task.dueDate = dueDate
        try modelContext.save()
    }

    func delete(_ task: TodoTask) async throws {
        modelContext.delete(task)
        try modelContext.save()
    }

    func toggleCompletion(_ task: TodoTask) async throws {
        task.isCompleted.toggle()
        try modelContext.save()
    }

    func updateSortOrders(for tasks: [TodoTask]) async throws {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
        try modelContext.save()
    }
}

extension TodoRepository {
    static let shared = TodoRepository(modelContainer: ModelContainer.shared)
}
