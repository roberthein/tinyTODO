import SwiftUI
import SwiftData
import tinyTCA
import tinyCLOUD
import UIKit

@main
struct TodoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let cloudApp: CloudApp
    let todoStore = Store(feature: TodoFeature())

    init() {
        do {
            cloudApp = try CloudApp(
                models: [TodoTask.self],
                configuration: CloudConfiguration(
                    containerIdentifier: "iCloud.rh.com.tinyTODO"
                )
            )
            cloudApp.registerSyncAdapter(TodoTaskSyncAdapter.self)
        } catch {
            fatalError("Failed to setup CloudApp: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TodoListView(store: todoStore)
                .modelContainer(cloudApp.modelContainer)
                .environment(\.cloudManager, cloudApp.cloudManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Task {
            await CloudManager.shared.startSync()
            completionHandler(.newData)
        }
    }
}
