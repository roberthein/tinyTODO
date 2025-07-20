import Foundation

struct CreateTaskRequest: Codable, Sendable {
    let title: String
    let description: String?
    let dueDate: Date
    let order: Int
}
