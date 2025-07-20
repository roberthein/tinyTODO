import Foundation
import SwiftData

// Provides a shared persistent ModelContainer for the app, with fallback to in-memory if needed
extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            let schema = Schema([TodoTask.self])

            // Store the persistent data in Application Support
            let appSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!

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
            // If persistent store creation fails, use an in-memory store for reliability (e.g. in previews/tests)
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

