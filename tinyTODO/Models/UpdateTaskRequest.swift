import Foundation

struct UpdateTaskRequest: Codable, Sendable {
    let title: String
    let description: String?
    let dueDate: Date
    let isCompleted: Bool
    let order: Int
}
