import SwiftUI
import tinyTCA
import SwiftData

struct TodoListView: View {
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
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        $state.send(.showAddTask)
                    }
                }
            }
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
            .alert("Error", isPresented: .constant(state.errorMessage != nil)) {
                Button("OK") {
                    $state.send(.setError(nil))
                }
            } message: {
                Text(state.errorMessage ?? "")
            }
            .task {
                $state.send(.onAppear)
            }
        }
    }

    @ViewBuilder
    private var taskListContent: some View {
        List {
            ForEach(TaskGroup.allCases.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.self) { group in
                if let tasks = state.taskGroups[group], !tasks.isEmpty {
                    Section(group.rawValue) {
                        ForEach(tasks, id: \.id) { task in
                            TaskRowView(task: task) {
                                $state.send(.toggleTaskCompletion(task))
                            } onEdit: {
                                $state.send(.editTask(task))
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                $state.send(.deleteTask(tasks[index]))
                            }
                        }
                        .onMove { source, destination in
                            $state.send(.reorderTasks(group, source, destination))
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            $state.send(.refresh)
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
