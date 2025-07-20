import Foundation

// Safe subscript to avoid out-of-bounds errors
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Extension for grouping TodoTask items by their due date into TaskGroups
extension Array where Element == TodoTask {
    func groupedByDueDate() -> [TaskGroup: [TodoTask]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var groups: [TaskGroup: [TodoTask]] = [
            .overdue: [],
            .today: [],
            .upcoming: []
        ]

        for task in self {
            let taskDate = calendar.startOfDay(for: task.dueDate)

            if taskDate < today {
                groups[.overdue]?.append(task)
            } else if calendar.isDate(taskDate, inSameDayAs: today) {
                groups[.today]?.append(task)
            } else {
                groups[.upcoming]?.append(task)
            }
        }

        return groups
    }
}
