<picture>
  <source srcset="SVG/tinyTODO-dark.svg" media="(prefers-color-scheme: dark)">
  <img src="SVG/tinyTODO-light.svg" alt="tinyTODO logo">
</picture>

A modern, Swift 6 concurrency-compliant to-do list application built with [tinyTCA](https://github.com/roberthein/tinyTCA) and SwiftData. tinyTODO demonstrates best practices for state management, data persistence, and user interface design in SwiftUI applications with strict concurrency compliance.

## Requirements

- **Swift 6.0+** with strict concurrency enabled
- **SwiftUI** framework
- **SwiftData** framework
- **iOS 18.0+** / **macOS 15.0+** / **tvOS 18.0+** / **watchOS 11.0+**
- **tinyTCA** 1.0.0+

> ⚠️ **Important**: This application requires Swift 6 strict concurrency mode and the latest iOS 18 APIs. It will not compile with earlier Swift versions or iOS versions.

## Features

- ✅ **Complete Task Management**: Create, read, update, delete, and mark tasks as complete
- 📅 **Smart Grouping**: Tasks automatically grouped by due date (Overdue, Today, Upcoming)
- 🎯 **Drag & Drop Reordering**: Intuitive task reordering within groups
- 💾 **SwiftData Persistence**: Modern, async data persistence with automatic migrations
- 🏗️ **tinyTCA Architecture**: Clean, predictable state management with unidirectional data flow
- ⚡ **Swift 6 Ready**: Full compliance with Swift 6 strict concurrency
- 🧵 **Responsive UI**: All database operations are async and non-blocking
- 📱 **Modern iOS 18 APIs**: NavigationStack, refreshable lists, and latest SwiftUI features

## Architecture Overview

### TodoFeature

The core feature implementation using tinyTCA:

```swift
struct TodoFeature: Feature {
    struct State: Sendable {
        var taskGroups: [TaskGroup: [TodoTask]] = [:]
        var isLoading: Bool = false
        var showingAddTask: Bool = false
        var editingTask: TodoTask?
        var errorMessage: String?
    }
    
    enum Action: Sendable {
        case onAppear
        case loadTasks
        case tasksLoaded([TodoTask])
        case addTask(title: String, subtitle: String?, dueDate: Date)
        case updateTask(TodoTask, title: String, subtitle: String?, dueDate: Date)
        case deleteTask(TodoTask)
        case toggleTaskCompletion(TodoTask)
        case reorderTasks(TaskGroup, IndexSet, Int)
        case showAddTask
        case hideAddTask
        case editTask(TodoTask?)
        case setError(String?)
        case refresh
    }
    
    static var initialState: State {
        State()
    }
    
    static func reducer(state: inout State, action: Action) throws {
        // Synchronous state mutations
    }
    
    static func effect(for action: Action, state: State) async throws -> Action? {
        // Async side effects (database operations)
    }
}
```

### SwiftData Model

Thread-safe model using `@unchecked Sendable`:

```swift
@Model
final class TodoTask: @unchecked Sendable {
    var title: String
    var subtitle: String?
    var dueDate: Date
    var isCompleted: Bool
    var sortOrder: Int

    init(title: String, subtitle: String? = nil, dueDate: Date, isCompleted: Bool = false, sortOrder: Int = 0) {
        self.title = title
        self.subtitle = subtitle
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
    }
}
```

### Repository Pattern

Thread-safe database operations with `@ModelActor`:

```swift
@ModelActor
actor TodoRepository: Sendable {
    func fetchTasks() async throws -> [TodoTask] {
        let descriptor = FetchDescriptor<TodoTask>(
            sortBy: [SortDescriptor(\TodoTask.dueDate), SortDescriptor(\TodoTask.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func save(_ task: TodoTask) async throws {
        modelContext.insert(task)
        try modelContext.save()
    }
    
    // Additional CRUD operations...
}
```

## Installation

### Dependencies

Add the required packages to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/roberthein/tinyTCA", from: "1.0.0")
]
```

### Project Setup

1. Clone the repository
2. Open in Xcode 16+
3. Build and run on iOS 18+ device or simulator

## Core Components

### Task Grouping

Tasks are automatically grouped by their due date:

```swift
enum TaskGroup: String, CaseIterable, Sendable {
    case overdue = "Overdue"
    case today = "Today" 
    case upcoming = "Upcoming"
}

extension Array where Element == TodoTask {
    func groupedByDueDate() -> [TaskGroup: [TodoTask]] {
        // Smart grouping logic based on Calendar comparison
    }
}
```

### SwiftUI Integration

Clean view implementation with tinyTCA:

```swift
struct TodoListView: View {
    @StoreState<TodoFeature> private var state: TodoFeature.State
    
    init(store: Store<TodoFeature> = Store(feature: TodoFeature())) {
        self._state = StoreState(store)
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(TaskGroup.allCases.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.self) { group in
                    if let tasks = state.taskGroups[group], !tasks.isEmpty {
                        Section(group.rawValue) {
                            ForEach(tasks, id: \.persistentModelID) { task in
                                TaskRowView(task: task) {
                                    $state.send(.toggleTaskCompletion(task))
                                } onEdit: {
                                    $state.send(.editTask(task))
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    $state.send(.deleteTask(tasks[index]))
                                }
                            }
                            .onMove { source, destination in
                                $state.send(.reorderTasks(group, source, destination))
                            }
                        }
                    }
                }
            }
            .refreshable {
                $state.send(.refresh)
            }
        }
    }
}
```

## Usage Patterns

### Creating Tasks

```swift
// In your view
Button("Add Task") {
    $state.send(.showAddTask)
}

// Action handling in reducer
case .addTask(let title, let subtitle, let dueDate):
    state.isLoading = true

// Effect handling
case .addTask(let title, let subtitle, let dueDate):
    let newTask = TodoTask(title: title, subtitle: subtitle, dueDate: dueDate)
    try await repository.save(newTask)
    let tasks = try await repository.fetchTasks()
    return .tasksLoaded(tasks)
```

### Updating Tasks

```swift
// Toggle completion
$state.send(.toggleTaskCompletion(task))

// Edit task details  
$state.send(.editTask(task))
```

### Drag and Drop Reordering

```swift
.onMove { source, destination in
    $state.send(.reorderTasks(group, source, destination))
}
```

## SwiftUI Previews

Easy preview setup with tinyTCA:

```swift
#Preview {
    TodoListView(store: .preview(.init(), state: TodoFeature.State(
        taskGroups: [
            .today: [
                TodoTask(title: "Sample Task", subtitle: "This is a sample task", dueDate: Date())
            ]
        ]
    )))
    .modelContainer(ModelContainer.shared)
}
```

## Architecture Benefits

### Unidirectional Data Flow
- Actions flow from UI to reducer
- State flows from reducer to UI
- Effects handle async operations and return actions

### Strict Concurrency Compliance
- All state mutations on `@MainActor`
- Database operations isolated with `@ModelActor`
- Thread-safe model objects with `@unchecked Sendable`

### Testability
- Pure reducer functions are easily testable
- Effects can be mocked for unit testing
- State mutations are predictable and deterministic

### Performance
- Async database operations don't block UI
- Efficient SwiftUI updates with `@Published` state
- Minimal overhead with compile-time safety

## Error Handling

Comprehensive error handling throughout the app:

```swift
// In effects
do {
    let tasks = try await repository.fetchTasks()
    return .tasksLoaded(tasks)
} catch {
    return .setError(error.localizedDescription)
}

// In UI
.alert("Error", isPresented: .constant(state.errorMessage != nil)) {
    Button("OK") {
        $state.send(.setError(nil))
    }
} message: {
    Text(state.errorMessage ?? "")
}
```

## Best Practices Demonstrated

### State Management
- Minimal, focused state structure
- Clear separation of concerns
- Predictable state mutations

### SwiftData Integration
- Proper actor isolation
- Async/await throughout
- Clean repository pattern

### SwiftUI Patterns
- Modern navigation with NavigationStack
- Proper list handling with drag/drop
- Sheet presentations for modal content

### Concurrency Safety
- Swift 6 strict concurrency compliance
- No data races or warnings
- Proper actor isolation boundaries

## License

tinyTODO is available under the MIT license. See LICENSE file for more info.