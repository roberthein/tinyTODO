import Foundation
import tinyTCA
import tinyAPI

// MARK: - Todo Feature
struct TodoFeature: Feature {
    struct State: Sendable, Equatable {
        var tasks: RequestState<[TodoTask]> = .idle
        var createTask: RequestState<TodoTask> = .idle
        var updateTask: RequestState<TodoTask> = .idle
        var deleteTask: RequestState<Bool> = .idle
        var showingAddTask = false
        var editingTask: TodoTask?

        var groupedTasks: [TaskGroup: [TodoTask]] {
            guard case .success(let tasks) = tasks else { return [:] }

            let grouped = Dictionary(grouping: tasks) { task in
                TaskGroup.allCases.first { $0.contains(date: task.dueDate) } ?? .upcoming
            }

            return grouped.mapValues { tasks in
                tasks.sorted { $0.order < $1.order }
            }
        }

        var isLoading: Bool {
            tasks.isLoading || createTask.isLoading || updateTask.isLoading || deleteTask.isLoading
        }

        var errorMessage: String? {
            tasks.errorMessage ?? createTask.errorMessage ?? updateTask.errorMessage ?? deleteTask.errorMessage
        }
    }

    enum Action: Sendable {
        case loadTasks
        case tasksResponse(Result<[TodoTask], TinyAPIError>)
        case createTask(CreateTaskRequest)
        case createTaskResponse(Result<TodoTask, TinyAPIError>)
        case updateTask(id: UUID, task: UpdateTaskRequest)
        case updateTaskResponse(Result<TodoTask, TinyAPIError>)
        case deleteTask(id: UUID)
        case deleteTaskResponse(Result<Bool, TinyAPIError>)
        case toggleTask(id: UUID)
        case toggleTaskResponse(Result<TodoTask, TinyAPIError>)
        case reorderTasks([TodoTask], in: TaskGroup)
        case showAddTask
        case hideAddTask
        case editTask(TodoTask)
        case clearEdit
        case clearError
    }

    var initialState: State {
        State()
    }

    func reducer(state: inout State, action: Action) throws {
        switch action {
        case .loadTasks:
            state.tasks = .loading

        case .tasksResponse(.success(let tasks)):
            state.tasks = .success(tasks)

        case .tasksResponse(.failure(let error)):
            state.tasks = .failure(error.localizedDescription)

        case .createTask:
            state.createTask = .loading

        case .createTaskResponse(.success(let task)):
            state.createTask = .success(task)
            state.showingAddTask = false
            // Add new task to existing list
            if case .success(var existingTasks) = state.tasks {
                existingTasks.append(task)
                state.tasks = .success(existingTasks)
            }

        case .createTaskResponse(.failure(let error)):
            state.createTask = .failure(error.localizedDescription)

        case .updateTask:
            state.updateTask = .loading

        case .updateTaskResponse(.success(let updatedTask)):
            state.updateTask = .success(updatedTask)
            state.editingTask = nil
            // Update task in existing list
            if case .success(var existingTasks) = state.tasks {
                if let index = existingTasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    existingTasks[index] = updatedTask
                    state.tasks = .success(existingTasks)
                }
            }

        case .updateTaskResponse(.failure(let error)):
            state.updateTask = .failure(error.localizedDescription)

        case .deleteTask:
            state.deleteTask = .loading

        case .deleteTaskResponse(.success):
            state.deleteTask = .success(true)

        case .deleteTaskResponse(.failure(let error)):
            state.deleteTask = .failure(error.localizedDescription)

        case .toggleTask:
            // Optimistically update UI
            break

        case .toggleTaskResponse(.success(let updatedTask)):
            // Update task in existing list
            if case .success(var existingTasks) = state.tasks {
                if let index = existingTasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    existingTasks[index] = updatedTask
                    state.tasks = .success(existingTasks)
                }
            }

        case .toggleTaskResponse(.failure(let error)):
            state.tasks = .failure(error.localizedDescription)

        case .reorderTasks(let reorderedTasks, in: let group):
            if case .success(var existingTasks) = state.tasks {
                // Update the order of tasks within the group
                for (index, task) in reorderedTasks.enumerated() {
                    if let taskIndex = existingTasks.firstIndex(where: { $0.id == task.id }) {
                        existingTasks[taskIndex].order = index
                    }
                }
                state.tasks = .success(existingTasks)
            }

        case .showAddTask:
            state.showingAddTask = true

        case .hideAddTask:
            state.showingAddTask = false

        case .editTask(let task):
            state.editingTask = task

        case .clearEdit:
            state.editingTask = nil

        case .clearError:
            state.tasks = state.tasks.clearError()
            state.createTask = .idle
            state.updateTask = .idle
            state.deleteTask = .idle
        }
    }

    func effect(for action: Action, state: State) async throws -> Action? {
        let apiClient = APIClientDependency.mock.client

        switch action {
        case .loadTasks:
            do {
                print("Loading tasks...")
                let tasks = try await apiClient.request(TaskEndpoint.list, as: [TodoTask].self)
                print("Successfully loaded \(tasks.count) tasks")
                return .tasksResponse(.success(tasks))
            } catch let error as TinyAPIError {
                print("TinyAPIError: \(error)")
                return .tasksResponse(.failure(error))
            } catch {
                print("General error: \(error)")
                return .tasksResponse(.failure(.networkError(error.localizedDescription)))
            }

        case .createTask(let request):
            do {
                let task = try await apiClient.request(TaskEndpoint.create(request), as: TodoTask.self)
                return .createTaskResponse(.success(task))
            } catch let error as TinyAPIError {
                return .createTaskResponse(.failure(error))
            } catch {
                return .createTaskResponse(.failure(.networkError(error.localizedDescription)))
            }

        case .updateTask(let id, let taskRequest):
            do {
                let task = try await apiClient.request(TaskEndpoint.update(id: id, task: taskRequest), as: TodoTask.self)
                return .updateTaskResponse(.success(task))
            } catch let error as TinyAPIError {
                return .updateTaskResponse(.failure(error))
            } catch {
                return .updateTaskResponse(.failure(.networkError(error.localizedDescription)))
            }

        case .deleteTask(let id):
            do {
                let _ = try await apiClient.request(TaskEndpoint.delete(id: id), as: EmptyResponse.self)
                return .deleteTaskResponse(.success(true))
            } catch let error as TinyAPIError {
                return .deleteTaskResponse(.failure(error))
            } catch {
                return .deleteTaskResponse(.failure(.networkError(error.localizedDescription)))
            }

        case .toggleTask(let id):
            do {
                let task = try await apiClient.request(TaskEndpoint.toggle(id: id), as: TodoTask.self)
                return .toggleTaskResponse(.success(task))
            } catch let error as TinyAPIError {
                return .toggleTaskResponse(.failure(error))
            } catch {
                return .toggleTaskResponse(.failure(.networkError(error.localizedDescription)))
            }

        default:
            return nil
        }
    }
}
