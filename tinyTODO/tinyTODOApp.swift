import SwiftUI
import SwiftData
import tinyTCA

@main
struct tinyTODOApp: App {
    let todoStore = Store(feature: TodoFeature())

    var body: some Scene {
        WindowGroup {
            TodoListView(store: todoStore)
        }
    }

//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([TodoItem.self])
//        let modelConfiguration = ModelConfiguration(
//            schema: schema,
//            isStoredInMemoryOnly: false,
//            cloudKitDatabase: .automatic
//        )
//
//        do {
//            return try ModelContainer(
//                for: schema,
//                configurations: [modelConfiguration]
//            )
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        .modelContainer(sharedModelContainer)
//    }
}
