import SwiftUI
import tinyTCA

struct TodoListView: View {
    @StoreState<TodoFeature> private var state: TodoFeature.State

    init(store: Store<TodoFeature>) {
        self._state = StoreState(store)
    }

    var body: some View {
        NavigationView {
            Group {
                switch state.tasks {
                case .idle:
                    VStack {
                        Text("Tap to load tasks")
                            .foregroundColor(.secondary)
                        Button("Load Tasks") {
                            $state.send(.loadTasks)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                case .loading:
                    VStack {
                        ProgressView()
                        Text("Loading tasks...")
                            .foregroundColor(.secondary)
                    }

                case .success:
                    List {
                        ForEach(TaskGroup.allCases, id: \.self) { group in
                            TaskGroupSectionView(
                                group: group,
                                tasks: state.groupedTasks[group] ?? [],
                                onToggleTask: { id in
                                    $state.send(.toggleTask(id: id))
                                },
                                onEditTask: { task in
                                    $state.send(.editTask(task))
                                },
                                onDeleteTask: { id in
                                    $state.send(.deleteTask(id: id))
                                },
                                onReorderTasks: { reorderedTasks in
                                    $state.send(.reorderTasks(reorderedTasks, in: group))
                                }
                            )
                        }
                    }
                    .refreshable {
                        $state.send(.loadTasks)
                    }

                case .failure(let error):
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            $state.send(.loadTasks)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Todo List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        $state.send(.showAddTask)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(state.isLoading)
                }
            }
            .sheet(isPresented: Binding(
                get: { state.showingAddTask },
                set: { _ in $state.send(.hideAddTask) }
            )) {
                TaskEditView(
                    state: $state.binding,
                    editingTask: nil,
                    sendAction: { action in $state.send(action) }
                )
            }
            .sheet(item: Binding(
                get: { state.editingTask },
                set: { _ in $state.send(.clearEdit) }
            )) { task in
                TaskEditView(
                    state: $state.binding,
                    editingTask: task,
                    sendAction: { action in $state.send(action) }
                )
            }
            .alert("Error", isPresented: Binding(
                get: { state.errorMessage != nil },
                set: { _ in }
            )) {
                Button("OK") {
                    $state.send(.clearError)
                }
            } message: {
                Text(state.errorMessage ?? "")
            }
            .onAppear {
                $state.send(.loadTasks)
            }
        }
    }
}

// MARK: - Preview
#Preview("Loading") {
    TodoListView(store: .preview(.init(), state: TodoFeature.State(tasks: .loading)))
}

#Preview("Success") {
    let tasks = [
        TodoTask(title: "Sample Task", description: "This is a sample task", dueDate: Date()),
        TodoTask(title: "Completed Task", description: nil, dueDate: Date().addingTimeInterval(86400), isCompleted: true)
    ]
    TodoListView(store: .preview(.init(), state: TodoFeature.State(tasks: .success(tasks))))
}

#Preview("Error") {
    TodoListView(store: .preview(.init(), state: TodoFeature.State(tasks: .failure("Network error occurred"))))
}
