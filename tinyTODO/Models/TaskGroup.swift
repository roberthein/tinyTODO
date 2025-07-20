import Foundation

enum TaskGroup: String, CaseIterable, Sendable {
    case past = "Past"
    case today = "Today"
    case upcoming = "Upcoming"

    func contains(date: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()

        switch self {
        case .past:
            return calendar.compare(date, to: today, toGranularity: .day) == .orderedAscending
        case .today:
            return calendar.isDate(date, inSameDayAs: today)
        case .upcoming:
            return calendar.compare(date, to: today, toGranularity: .day) == .orderedDescending
        }
    }
}
