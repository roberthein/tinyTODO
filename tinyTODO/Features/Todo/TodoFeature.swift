import Foundation
import tinyTCA

// The main feature for managing todo tasks, using The Composable Architecture (TCA) pattern.
struct TodoFeature: Feature {
    // State holds all data needed for the feature's UI and logic.
    struct State: Sendable {
        var taskGroups: [TaskGroup: [TodoTaskData]] = [:]
        var isLoading: Bool = false
        var showingAddTask: Bool = false
        var editingTask: TodoTaskData?
        var errorMessage: String?

//        static let repository = TodoRepository.shared // Data layer dependency
    }

    // Actions represent all possible user and system events for this feature.
    enum Action: Sendable {
        case onAppear
        case loadTasks
        case tasksLoaded([TodoTaskData])
        case addTask(title: String, subtitle: String?, dueDate: Date)
        case updateTask(TodoTaskData, title: String, subtitle: String?, dueDate: Date)
        case deleteTask(TodoTaskData)
        case toggleTaskCompletion(TodoTaskData)
        case reorderTasks(TaskGroup, IndexSet, Int)
        case showAddTask
        case hideAddTask
        case editTask(TodoTaskData?)
        case setError(String?)
        case setLoading(Bool)
        case refresh
    }

    var initialState: State {
        State()
    }

    // Reducer: Synchronously updates state in response to actions.
    func reducer(state: inout State, action: Action) throws {
        switch action {
        case .onAppear, .refresh, .loadTasks:
            state.isLoading = true
            state.errorMessage = nil

        case let .tasksLoaded(tasks):
            state.taskGroups = tasks.groupedByDueDate()
            state.isLoading = false

        case .addTask, .updateTask:
            state.isLoading = true

        case .deleteTask, .toggleTaskCompletion:
            // Async effects will handle these actions
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

    // Effect: Handles async work (side effects) and can return a new action.
    func effect(for action: Action, state: State) async throws -> Action? {
//        let repository = try await TodoRepository.shared
        let repository = try await TodoRepository.createShared()

        switch action {
        case .onAppear, .loadTasks, .refresh:
            do {
                let tasks = try await repository.fetchTaskData()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .addTask(title, subtitle, dueDate):
            do {
                let newTask = TodoTask(title: title, subtitle: subtitle, dueDate: dueDate)
                try await repository.save(newTask)
                let tasks = try await repository.fetchTaskData()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .updateTask(task, title, subtitle, dueDate):
            do {
                try await repository.update(taskID: task.id, title: title, subtitle: subtitle, dueDate: dueDate)
                let tasks = try await repository.fetchTaskData()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .deleteTask(task):
            do {
                try await repository.delete(taskID: task.id)
                let tasks = try await repository.fetchTaskData()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .toggleTaskCompletion(task):
            do {
                try await repository.toggleCompletion(taskID: task.id)
                let tasks = try await repository.fetchTaskData()
                return .tasksLoaded(tasks)
            } catch {
                return .setError(error.localizedDescription)
            }

        case let .reorderTasks(group, _, _):
            guard let tasks = state.taskGroups[group] else { return nil }
            do {
                try await repository.updateSortOrders(for: tasks.map { (id: $0.id, order: $0.sortOrder) })
                return nil
            } catch {
                return .setError(error.localizedDescription)
            }

        default:
            return nil
        }
    }
}
