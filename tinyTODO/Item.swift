import Foundation
import SwiftData

@Model
final class TodoItem: @unchecked Sendable {
    var title: String
    var subtitle: String?
    var createdAt: Date
    var dueAt: Date
    var isCompleted: Bool

    init(title: String, subtitle: String? = nil, createdAt: Date, dueAt: Date, isCompleted: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.createdAt = createdAt
        self.dueAt = dueAt
        self.isCompleted = isCompleted
    }
}
