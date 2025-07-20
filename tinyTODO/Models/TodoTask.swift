import Foundation

import SwiftUI
import Foundation
import tinyTCA
import tinyAPI

// MARK: - Task Model
struct TodoTask: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var description: String?
    var dueDate: Date
    var isCompleted: Bool
    var order: Int

    init(id: UUID = UUID(), title: String, description: String? = nil, dueDate: Date, isCompleted: Bool = false, order: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.order = order
    }

    // Custom coding to handle UUID and Date parsing
    enum CodingKeys: String, CodingKey {
        case id, title, description, dueDate, isCompleted, order
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Parse UUID from string
        let idString = try container.decode(String.self, forKey: .id)
        guard let uuid = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string")
        }
        id = uuid

        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        order = try container.decode(Int.self, forKey: .order)

        // Parse ISO8601 date from string
        let dateString = try container.decode(String.self, forKey: .dueDate)
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .dueDate, in: container, debugDescription: "Date string does not match ISO8601 format")
        }
        dueDate = date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode UUID as string
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(order, forKey: .order)

        // Encode date as ISO8601 string
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: dueDate)
        try container.encode(dateString, forKey: .dueDate)
    }
}
