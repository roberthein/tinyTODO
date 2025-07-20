import SwiftUI
import tinyTCA

struct EditTaskView: View {
    @State private var title: String
    @State private var subtitle: String
    @State private var dueDate: Date
    @Environment(\.dismiss) private var dismiss

    let task: TodoTask
    let onSave: (String, String?, Date) -> Void
    let onCancel: () -> Void

    init(task: TodoTask, onSave: @escaping (String, String?, Date) -> Void, onCancel: @escaping () -> Void) {
        self.task = task
        self.onSave = onSave
        self.onCancel = onCancel
        self._title = State(initialValue: task.title)
        self._subtitle = State(initialValue: task.subtitle ?? "")
        self._dueDate = State(initialValue: task.dueDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Subtitle (Optional)", text: $subtitle)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(title, subtitle.isEmpty ? nil : subtitle, dueDate)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
