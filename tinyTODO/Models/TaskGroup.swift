import Foundation

// Represents logical groupings for tasks based on due date
// Used for sectioning and sorting in the UI and state
enum TaskGroup: String, CaseIterable, Sendable {
    case overdue = "Overdue"
    case today = "Today"
    case upcoming = "Upcoming"

    // Used for sorting groups in the UI
    var sortOrder: Int {
        switch self {
        case .overdue: return 0
        case .today: return 1
        case .upcoming: return 2
        }
    }
}
