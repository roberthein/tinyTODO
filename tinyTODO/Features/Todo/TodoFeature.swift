import Foundation
import tinyTCA

struct TodoFeature: Feature {
    struct State: Sendable {
        var taskGroups: [TaskGroup: [TodoTask]] = [:]
        var isLoading: Bool = false
        var showingAddTask: Bool = false
        var editingTask: TodoTask?
        var errorMessage: String?

        // Repository is injected through the environment
        static let repository = TodoRepository.shared
    }

    enum Action: Sendable {
        case onAppear
        case loadTasks
        case tasksLoaded([TodoTask])
        case addTask(title: String, subtitle: String?, dueDate: Date)
        case updateTask(TodoTask, title: String, subtitle: String?, dueDate: Date)
        case deleteTask(TodoTask)
        case toggleTaskCompletion(TodoTask)
        case reorderTasks(TaskGroup, IndexSet, Int)
        case showAddTask
        case hideAddTask
        case editTask(TodoTask?)
        case setError(String?)
        case setLoading(Bool)
        case refresh
    }

    var initialState: State {
        State()
    }

    func reducer(state: inout State, action: Action) throws {
        switch action {
        case .onAppear, .refresh, .loadTasks:
            state.isLoading = true
            state.errorMessage = nil

        case let .tasksLoaded(tasks):
            state.taskGroups = tasks.groupedByDueDate()
            state.isLoading = false

        case .addTask:
            state.isLoading = true

        case .updateTask:
            state.isLoading = true

        case .deleteTask, .toggleTaskCompletion:
            // Effects will handle the async operations
            break

        case let .reorderTasks(group, source, destination):
            guard var tasks = state.taskGroups[group] else { return }
            tasks.move(fromOffsets: source, toOffset: destination)
            state.taskGroups[group] = tasks

        case .showAddTask:
            state.showingAddTask = true

        case .hideAddTask:
            state.showingAddTask = false

        case let .editTask(task):
            state.editingTask = task

        case let .setError(message):
            state.errorMessage = message
            state.isLoading = false

        case let .setLoading(loading):
            state.isLoading = loading
        }
    }

    func effect(for action: Action, state: State) async throws -> Action? {
        let repository = State.repository

        switch action {
        case .onAppear, .loadTasks, .refresh:
            do {
                let tasks = try await repository.fetchTasks()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .addTask(title, subtitle, dueDate):
            do {
                let newTask = TodoTask(title: title, subtitle: subtitle, dueDate: dueDate)
                try await repository.save(newTask)
                let tasks = try await repository.fetchTasks()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .updateTask(task, title, subtitle, dueDate):
            do {
                try await repository.update(task, title: title, subtitle: subtitle, dueDate: dueDate)
                let tasks = try await repository.fetchTasks()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .deleteTask(task):
            do {
                try await repository.delete(task)
                let tasks = try await repository.fetchTasks()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .toggleTaskCompletion(task):
            do {
                try await repository.toggleCompletion(task)
                let tasks = try await repository.fetchTasks()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .reorderTasks(group, _, _):
            guard let tasks = state.taskGroups[group] else { return nil }
            do {
                try await repository.updateSortOrders(for: tasks)
                return nil
            } catch {
                return .setError(error.localizedDescription)
            }

        default:
            return nil
        }
    }
}
