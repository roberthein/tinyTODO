import Foundation
import SwiftData

// The main data model representing a single todo task
@Model
final class TodoTask: @unchecked Sendable {
    var title: String
    var subtitle: String?
    var dueDate: Date
    var isCompleted: Bool
    var sortOrder: Int

    init(title: String, subtitle: String? = nil, dueDate: Date, isCompleted: Bool = false, sortOrder: Int = 0) {
        self.title = title
        self.subtitle = subtitle
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
    }
}
