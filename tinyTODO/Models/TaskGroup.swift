import Foundation

enum TaskGroup: String, CaseIterable, Sendable {
    case overdue = "Overdue"
    case today = "Today"
    case upcoming = "Upcoming"

    var sortOrder: Int {
        switch self {
        case .overdue: return 0
        case .today: return 1
        case .upcoming: return 2
        }
    }
}
