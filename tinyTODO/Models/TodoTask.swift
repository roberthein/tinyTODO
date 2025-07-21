import Foundation
import SwiftData
import tinyCLOUD

@Model
final class TodoTask: CloudSyncable, @unchecked Sendable {
    var title: String = ""
    var subtitle: String?
    var dueDate: Date = Date()
    var isCompleted: Bool = false
    var sortOrder: Int = 0

    // CloudSyncable requirements
    var cloudKitRecordID: String?
    var lastSyncDate: Date?
    var lastModifiedDate: Date = Date()
    var isDeleted: Bool = false

    init(title: String, subtitle: String? = nil, dueDate: Date, isCompleted: Bool = false, sortOrder: Int = 0) {
        self.title = title
        self.subtitle = subtitle
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.lastModifiedDate = Date()
    }
}
