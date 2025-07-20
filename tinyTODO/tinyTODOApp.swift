import SwiftUI
import SwiftData
import tinyTCA

@main
struct TodoApp: App {
    let todoStore = Store(feature: TodoFeature())

    var body: some Scene {
        WindowGroup {
            TodoListView(store: todoStore)
                .modelContainer(ModelContainer.shared)
        }
    }
}
