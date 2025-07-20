import SwiftUI

struct TaskGroupSectionView: View {
    let group: TaskGroup
    let tasks: [TodoTask]
    let onToggleTask: (UUID) -> Void
    let onEditTask: (TodoTask) -> Void
    let onDeleteTask: (UUID) -> Void
    let onReorderTasks: ([TodoTask]) -> Void

    var body: some View {
        if !tasks.isEmpty {
            Section(group.rawValue) {
                ForEach(tasks) { task in
                    TaskRowView(
                        task: task,
                        onToggle: {
                            onToggleTask(task.id)
                        },
                        onEdit: {
                            onEditTask(task)
                        },
                        onDelete: {
                            onDeleteTask(task.id)
                        }
                    )
                }
                .onMove { from, to in
                    var reorderedTasks = tasks
                    reorderedTasks.move(fromOffsets: from, toOffset: to)
                    onReorderTasks(reorderedTasks)
                }
            }
        }
    }
}
