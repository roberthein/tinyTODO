import Foundation
import SwiftData

// Repository actor responsible for all data operations on TodoTask.
@ModelActor
actor TodoRepository: Sendable {
    // Fetch all tasks, sorted by due date and custom order
    func fetchTasks() async throws -> [TodoTask] {
        let descriptor = FetchDescriptor<TodoTask>(
            sortBy: [SortDescriptor(\TodoTask.dueDate), SortDescriptor(\TodoTask.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    // Save a new task
    func save(_ task: TodoTask) async throws {
        modelContext.insert(task)
        try modelContext.save()
    }

    // Update an existing task's details
    func update(_ task: TodoTask, title: String, subtitle: String?, dueDate: Date) async throws {
        task.title = title
        task.subtitle = subtitle
        task.dueDate = dueDate
        try modelContext.save()
    }

    // Delete a task
    func delete(_ task: TodoTask) async throws {
        modelContext.delete(task)
        try modelContext.save()
    }

    // Toggle a task's completion status
    func toggleCompletion(_ task: TodoTask) async throws {
        task.isCompleted.toggle()
        try modelContext.save()
    }

    // Update the sort order for a group of tasks
    func updateSortOrders(for tasks: [TodoTask]) async throws {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
        try modelContext.save()
    }
}

extension TodoRepository {
    // Shared singleton instance for use in the app
    static let shared = TodoRepository(modelContainer: ModelContainer.shared)
}
