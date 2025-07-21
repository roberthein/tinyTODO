import SwiftUI
import SwiftData
import CloudKit
import CoreData
import tinyCLOUD

struct TodoTaskSyncAdapter: CloudSyncAdapter {
    static let recordType = "TodoTask"

    static func toRecord(_ model: TodoTask) -> [String: CKRecordValue] {
        var record: [String: CKRecordValue] = [
            "title": model.title as CKRecordValue,
            "dueDate": model.dueDate as CKRecordValue,
            "isCompleted": (model.isCompleted ? 1 : 0) as CKRecordValue,
            "sortOrder": model.sortOrder as CKRecordValue,
            "lastModifiedDate": model.lastModifiedDate as CKRecordValue
        ]

        if let subtitle = model.subtitle {
            record["subtitle"] = subtitle as CKRecordValue
        }

        return record
    }

    static func fromRecord(_ record: CKRecord, to model: TodoTask) throws {
        model.title = record["title"] as? String ?? ""
        model.subtitle = record["subtitle"] as? String
        model.dueDate = record["dueDate"] as? Date ?? Date()
        model.isCompleted = (record["isCompleted"] as? Int ?? 0) == 1
        model.sortOrder = record["sortOrder"] as? Int ?? 0
        model.lastModifiedDate = record["lastModifiedDate"] as? Date ?? Date()
    }

    static func createModel(from record: CKRecord, in context: ModelContext) throws -> TodoTask {
        let task = TodoTask(
            title: record["title"] as? String ?? "",
            subtitle: record["subtitle"] as? String,
            dueDate: record["dueDate"] as? Date ?? Date(),
            isCompleted: (record["isCompleted"] as? Int ?? 0) == 1,
            sortOrder: record["sortOrder"] as? Int ?? 0
        )

        if let modifiedDate = record["lastModifiedDate"] as? Date {
            task.lastModifiedDate = modifiedDate
        }

        context.insert(task)
        return task
    }

    static func resolveConflict(local: TodoTask, remote: CKRecord) throws -> ConflictResolution<TodoTask> {
        // Use modification dates for conflict resolution
        let remoteModified = remote["lastModifiedDate"] as? Date ?? Date.distantPast

        if remoteModified > local.lastModifiedDate {
            // Remote is newer, use remote data
            try fromRecord(remote, to: local)
            return .useRemote(local)
        } else if remoteModified < local.lastModifiedDate {
            // Local is newer, keep local data
            return .useLocal(local)
        } else {
            // Same modification date, prefer completed tasks
            let remoteCompleted = (remote["isCompleted"] as? Int ?? 0) == 1
            if remoteCompleted && !local.isCompleted {
                try fromRecord(remote, to: local)
                return .useRemote(local)
            }
            return .useLocal(local)
        }
    }
}
