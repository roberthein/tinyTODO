import Foundation
import SwiftData
import tinyCLOUD

@ModelActor
actor TodoRepository: Sendable {
    // Fetch all tasks, sorted by due date and custom order
    func fetchTasks() async throws -> [TodoTask] {
        let descriptor = FetchDescriptor<TodoTask>(
            sortBy: [SortDescriptor(\TodoTask.dueDate), SortDescriptor(\TodoTask.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    // Fetch a specific task by its persistent identifier
    func fetchTask(withID id: PersistentIdentifier) async throws -> TodoTask? {
        return modelContext.model(for: id) as? TodoTask
    }

    // Save a new task
    func save(_ task: TodoTask) async throws {
        modelContext.insert(task)
        task.markAsModified()
        try modelContext.save()
        await syncWithCloud()
    }

    // Create and save a new task
    func createTask(title: String, subtitle: String?, dueDate: Date, sortOrder: Int) async throws -> PersistentIdentifier {
        let task = TodoTask(
            title: title,
            subtitle: subtitle,
            dueDate: dueDate,
            isCompleted: false,
            sortOrder: sortOrder
        )
        modelContext.insert(task)
        task.markAsModified()
        try modelContext.save()
        await syncWithCloud()
        return task.persistentModelID
    }

    // Update an existing task's details using its ID
    func update(taskID: PersistentIdentifier, title: String, subtitle: String?, dueDate: Date) async throws {
        guard let task = modelContext.model(for: taskID) as? TodoTask else {
            throw TodoRepositoryError.taskNotFound
        }
        task.title = title
        task.subtitle = subtitle
        task.dueDate = dueDate
        task.markAsModified()
        try modelContext.save()
        await syncWithCloud()
    }

    // Delete a task using its ID
    func delete(taskID: PersistentIdentifier) async throws {
        guard let task = modelContext.model(for: taskID) as? TodoTask else {
            throw TodoRepositoryError.taskNotFound
        }
        task.isDeleted = true
        task.markAsModified()
        modelContext.delete(task)
        try modelContext.save()
        await syncWithCloud()
    }

    // Toggle a task's completion status using its ID
    func toggleCompletion(taskID: PersistentIdentifier) async throws {
        guard let task = modelContext.model(for: taskID) as? TodoTask else {
            throw TodoRepositoryError.taskNotFound
        }
        task.isCompleted.toggle()
        task.markAsModified()
        try modelContext.save()
        await syncWithCloud()
    }

    // Update the sort order for a group of tasks
    func updateSortOrders(for taskIDs: [(id: PersistentIdentifier, order: Int)]) async throws {
        for (taskID, order) in taskIDs {
            if let task = modelContext.model(for: taskID) as? TodoTask {
                task.sortOrder = order
                task.markAsModified()
            }
        }
        try modelContext.save()
        await syncWithCloud()
    }

    // Trigger a manual sync with CloudKit
    func syncWithCloud() async {
        await CloudManager.shared.startSync()
    }
}

// Error types for repository operations
enum TodoRepositoryError: Error {
    case containerNotInitialized
    case taskNotFound
}

// View-safe task data that won't become invalid
struct TodoTaskData: Hashable, Identifiable, Sendable {
    let id: PersistentIdentifier
    let title: String
    let subtitle: String?
    let dueDate: Date
    let isCompleted: Bool
    let sortOrder: Int

    init(from task: TodoTask) {
        self.id = task.persistentModelID
        self.title = task.title
        self.subtitle = task.subtitle
        self.dueDate = task.dueDate
        self.isCompleted = task.isCompleted
        self.sortOrder = task.sortOrder
    }
}

extension TodoRepository {
    // Fetch tasks as view-safe data
    func fetchTaskData() async throws -> [TodoTaskData] {
        let tasks = try await fetchTasks()
        return tasks.map { TodoTaskData(from: $0) }
    }
}

extension TodoRepository {
    // Create a shared instance after CloudManager is configured
    @MainActor
    static func createShared() async throws -> TodoRepository {
        guard let container = CloudManager.shared.modelContainer else {
            throw TodoRepositoryError.containerNotInitialized
        }
        return TodoRepository(modelContainer: container)
    }
}
