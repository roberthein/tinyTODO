import SwiftUI
import tinyTCA

struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var state: TodoFeature.State
    let editingTask: TodoTask?
    let sendAction: (TodoFeature.Action) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()

    var isEditing: Bool {
        editingTask != nil
    }

    init(state: Binding<TodoFeature.State>, editingTask: TodoTask?, sendAction: @escaping (TodoFeature.Action) -> Void) {
        self._state = state
        self.editingTask = editingTask
        self.sendAction = sendAction
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty || state.isLoading)
                }
            }
            .overlay {
                if state.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
        .onAppear {
            if let task = editingTask {
                title = task.title
                description = task.description ?? ""
                dueDate = task.dueDate
            }
        }
    }

    private func saveTask() {
        if let editingTask = editingTask {
            let updateRequest = UpdateTaskRequest(
                title: title,
                description: description.isEmpty ? nil : description,
                dueDate: dueDate,
                isCompleted: editingTask.isCompleted,
                order: editingTask.order
            )
            sendAction(.updateTask(id: editingTask.id, task: updateRequest))
        } else {
            let createRequest = CreateTaskRequest(
                title: title,
                description: description.isEmpty ? nil : description,
                dueDate: dueDate,
                order: 0
            )
            sendAction(.createTask(createRequest))
        }
        dismiss()
    }
}
