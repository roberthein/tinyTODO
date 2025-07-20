import Foundation
import SwiftData

extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            let schema = Schema([TodoTask.self])

            // Get the Application Support directory URL
            let appSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!

            // Ensure the directory exists
            try FileManager.default.createDirectory(
                at: appSupportURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let storeURL = appSupportURL.appendingPathComponent("TodoApp.store")

            let configuration = ModelConfiguration(
                url: storeURL
            )

            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Fallback to in-memory store if file creation fails
            print("Failed to create persistent store, falling back to in-memory: \(error)")
            do {
                let schema = Schema([TodoTask.self])
                let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }()
}

