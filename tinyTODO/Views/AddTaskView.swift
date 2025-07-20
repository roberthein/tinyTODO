import SwiftUI

struct AddTaskView: View {
    @State private var title = ""
    @State private var subtitle = ""
    @State private var dueDate = Date()
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String?, Date) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Subtitle (Optional)", text: $subtitle)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                }
            }
            .navigationTitle("New Task")
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
