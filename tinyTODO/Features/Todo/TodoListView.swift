import SwiftUI
import tinyTCA
import SwiftData

struct TodoListView: View {
    // Connects this view to the TCA store for TodoFeature
    @StoreState<TodoFeature> private var state: TodoFeature.State

    init(store: Store<TodoFeature>) {
        self._state = StoreState(store)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if state.isLoading && state.taskGroups.isEmpty {
                    ProgressView("Loading tasks...")
                } else {
                    taskListContent
                }
            }
            .navigationTitle("tinyTODO")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        $state.send(.showAddTask) // TCA: Dispatch action to show add task sheet
                    }
                }
            }
            // Sheet for adding a new task
            .sheet(
                isPresented: .constant(state.showingAddTask),
                onDismiss: {
                    $state.send(.hideAddTask)
                },
                content: {
                    AddTaskView { title, subtitle, dueDate in
                        $state.send(.addTask(title: title, subtitle: subtitle, dueDate: dueDate))
                        $state.send(.hideAddTask)
                    } onCancel: {
                        $state.send(.hideAddTask)
                    }
                    .modalConfiguration()
                }
            )
            // Sheet for editing an existing task
            .sheet(
                item: .constant(state.editingTask),
                onDismiss: {
                    $state.send(.editTask(nil))
                },
                content: { task in
                    EditTaskView(task: task) { title, subtitle, dueDate in
                        $state.send(.updateTask(task, title: title, subtitle: subtitle, dueDate: dueDate))
                        $state.send(.editTask(nil))
                    } onCancel: {
                        $state.send(.editTask(nil))
                    }
                    .modalConfiguration()
                }
            )
            // Error alert
            .alert("Error", isPresented: .constant(state.errorMessage != nil)) {
                Button("OK") {
                    $state.send(.setError(nil))
                }
            } message: {
                Text(state.errorMessage ?? "")
            }
            // TCA: Triggers .onAppear action when view appears
            .task {
                $state.send(.onAppear)
            }
        }
    }

    // Main list content, grouped by TaskGroup
    @ViewBuilder
    private var taskListContent: some View {
        List {
            ForEach(TaskGroup.allCases.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.self) { group in
                if let tasks = state.taskGroups[group], !tasks.isEmpty {
                    Section(group.rawValue) {
                        ForEach(tasks, id: \.id) { task in
                            TaskRowView(task: task) {
                                $state.send(.toggleTaskCompletion(task)) // TCA: Toggle completion
                            } onEdit: {
                                $state.send(.editTask(task)) // TCA: Start editing
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                $state.send(.deleteTask(tasks[index])) // TCA: Delete task
                            }
                        }
                        .onMove { source, destination in
                            $state.send(.reorderTasks(group, source, destination)) // TCA: Reorder tasks
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            $state.send(.refresh) // TCA: Refresh tasks
        }
    }
}

#Preview {
    TodoListView(store: .preview(.init(), state: TodoFeature.State(
        taskGroups: [
            .today: [
                TodoTask(title: "Sample Task", subtitle: "This is a sample task", dueDate: Date())
            ]
        ]
    )))
    .modelContainer(ModelContainer.shared)
}
