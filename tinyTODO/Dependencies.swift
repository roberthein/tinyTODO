///// Function to run the entire app with dependencies configured
//public func runWithDependencies<R>(
//    _ configureDependencies: (inout DependencyValues) -> Void = { _ in },
//    operation: () async throws -> R
//) async rethrows -> R {
//    try await withDependencies(configureDependencies, operation: operation)
//}
//import Foundation
//import SwiftUI
//import SwiftData
//
//// MARK: - Core Dependency System (Independent of SwiftUI)
//
///// A type-erased dependency key for internal storage
//internal struct AnyDependencyKey: Hashable, Sendable {
//    let id: ObjectIdentifier
//
//    init<T: DependencyKey>(_ keyType: T.Type) {
//        self.id = ObjectIdentifier(keyType)
//    }
//
//    static func == (lhs: AnyDependencyKey, rhs: AnyDependencyKey) -> Bool {
//        lhs.id == rhs.id
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//}
//
///// Protocol defining a dependency key
//public protocol DependencyKey {
//    associatedtype Value
//    static var defaultValue: Value { get }
//    static var testValue: Value { get }
//}
//
///// Protocol for sendable dependency keys (most dependencies)
//public protocol SendableDependencyKey: DependencyKey where Value: Sendable {}
//
///// Extension to provide default test value
//extension DependencyKey {
//    public static var testValue: Value { defaultValue }
//}
//
///// Container for all dependency values - using a reference type for thread safety
//@TaskLocal private var _current = DependencyStorage()
//
///// Thread-safe storage for dependencies
//internal final class DependencyStorage: @unchecked Sendable {
//    internal let lock = NSLock()
//    internal var storage: [AnyDependencyKey: Any] = [:]
//
//    init() {}
//
//    func get<Key: DependencyKey>(_ key: Key.Type) -> Key.Value {
//        lock.lock()
//        defer { lock.unlock() }
//
//        if let value = storage[AnyDependencyKey(key)] as? Key.Value {
//            return value
//        }
//        return Key.defaultValue
//    }
//
//    func set<Key: DependencyKey>(_ value: Key.Value, for key: Key.Type) {
//        lock.lock()
//        defer { lock.unlock() }
//
//        storage[AnyDependencyKey(key)] = value
//    }
//
//    func copy() -> DependencyStorage {
//        lock.lock()
//        defer { lock.unlock() }
//
//        let newStorage = DependencyStorage()
//        newStorage.storage = storage
//        return newStorage
//    }
//
//    func copyStorageFrom(_ other: DependencyStorage) {
//        lock.lock()
//        defer { lock.unlock() }
//
//        other.lock.lock()
//        defer { other.lock.unlock() }
//
//        storage = other.storage
//    }
//}
//
///// The main dependency values container
//public struct DependencyValues {
//    internal let storage: DependencyStorage
//
//    internal init(storage: DependencyStorage) {
//        self.storage = storage
//    }
//
//    public init() {
//        self.storage = DependencyStorage()
//    }
//
//    /// Get a dependency value
//    public subscript<Key: DependencyKey>(key: Key.Type) -> Key.Value {
//        get {
//            storage.get(key)
//        }
//        set {
//            storage.set(newValue, for: key)
//        }
//    }
//
//    /// Access the current dependency values (read-only)
//    public static var current: DependencyValues {
//        DependencyValues(storage: _current)
//    }
//
//    /// Create a copy with modifications
//    internal func modified(_ updateValues: (inout DependencyValues) -> Void) -> DependencyValues {
//        let newStorage = storage.copy()
//        var newValues = DependencyValues(storage: newStorage)
//        updateValues(&newValues)
//        return newValues
//    }
//
//    /// Set dependencies globally (for app setup)
//    public static func setCurrent(_ dependencies: DependencyValues) {
//        _current.copyStorageFrom(dependencies.storage)
//    }
//}
//
///// Special property wrapper for ModelContext that enforces MainActor access
//@propertyWrapper
//public struct MainActorDependency<Value>: Sendable {
//    private let getValue: @Sendable @MainActor () -> Value
//
//    public init<Key: DependencyKey>(_ key: Key.Type) where Key.Value == Value {
//        self.getValue = { @MainActor in
//            DependencyValues.current[key]
//        }
//    }
//
//    @MainActor
//    public var wrappedValue: Value {
//        getValue()
//    }
//}
//
///// Property wrapper for injecting dependencies
//@propertyWrapper
//public struct Dependency<Value>: Sendable {
//    private let getValue: @Sendable () -> Value
//
//    public init<Key: DependencyKey>(_ key: Key.Type) where Key.Value == Value {
//        self.getValue = {
//            DependencyValues.current[key]
//        }
//    }
//
//    public var wrappedValue: Value {
//        getValue()
//    }
//}
//
///// Function to run code with modified dependencies
//public func withDependencies<R>(
//    _ updateValuesForOperation: (inout DependencyValues) -> Void,
//    operation: () throws -> R
//) rethrows -> R {
//    // Create modified dependencies
//    var dependencies = DependencyValues.current
//    updateValuesForOperation(&dependencies)
//
//    // Set globally and restore after operation
//    let originalStorage = _current
//    DependencyValues.setCurrent(dependencies)
//
//    defer {
//        // Restore original dependencies using internal initializer
//        let restoreValues = DependencyValues(storage: originalStorage)
//        DependencyValues.setCurrent(restoreValues)
//    }
//
//    return try operation()
//}
//
///// Async version of withDependencies
//public func withDependencies<R>(
//    _ updateValuesForOperation: (inout DependencyValues) -> Void,
//    operation: () async throws -> R
//) async rethrows -> R {
//    // Create modified dependencies
//    var dependencies = DependencyValues.current
//    updateValuesForOperation(&dependencies)
//
//    // For async, we need to use TaskLocal properly
//    return try await $_current.withValue(dependencies.storage) {
//        try await operation()
//    }
//}
//
///// Function to propagate dependencies from one context to another
//public func withDependencies<R>(
//    from context: @autoclosure () -> DependencyValues,
//    _ updateValuesForOperation: (inout DependencyValues) -> Void = { _ in },
//    operation: () throws -> R
//) rethrows -> R {
//    var dependencies = context()
//    updateValuesForOperation(&dependencies)
//
//    let originalStorage = _current
//    DependencyValues.setCurrent(dependencies)
//
//    defer {
//        let restoreValues = DependencyValues(storage: originalStorage)
//        DependencyValues.setCurrent(restoreValues)
//    }
//
//    return try operation()
//}
//
///// Async version with context propagation
//public func withDependencies<R>(
//    from context: @autoclosure () -> DependencyValues,
//    _ updateValuesForOperation: (inout DependencyValues) -> Void = { _ in },
//    operation: () async throws -> R
//) async rethrows -> R {
//    var dependencies = context()
//    updateValuesForOperation(&dependencies)
//
//    return try await $_current.withValue(dependencies.storage) {
//        try await operation()
//    }
//}
//
//// MARK: - Dependency Keys
//
///// Network service dependency key
//public struct NetworkServiceKey: SendableDependencyKey {
//    public static var defaultValue: any NetworkService { DefaultNetworkService() }
//    public static var testValue: any NetworkService { MockNetworkService() }
//}
//
///// User service dependency key
//public struct UserServiceKey: SendableDependencyKey {
//    public static var defaultValue: any UserService { DefaultUserService() }
//    public static var testValue: any UserService { MockUserService() }
//}
//
///// Analytics service dependency key
//public struct AnalyticsServiceKey: SendableDependencyKey {
//    public static var defaultValue: any AnalyticsService { DefaultAnalyticsService() }
//    public static var testValue: any AnalyticsService { MockAnalyticsService() }
//}
//
///// ModelContext dependency key for SwiftData (non-sendable)
//public struct ModelContextKey: DependencyKey {
//    public static var defaultValue: ModelContext? { nil }
//    public static var testValue: ModelContext? { nil }
//}
//
//// MARK: - DependencyValues Extensions
//
//extension DependencyValues {
//    public var networkService: any NetworkService {
//        get { self[NetworkServiceKey.self] }
//        set { self[NetworkServiceKey.self] = newValue }
//    }
//
//    public var userService: any UserService {
//        get { self[UserServiceKey.self] }
//        set { self[UserServiceKey.self] = newValue }
//    }
//
//    public var analyticsService: any AnalyticsService {
//        get { self[AnalyticsServiceKey.self] }
//        set { self[AnalyticsServiceKey.self] = newValue }
//    }
//
//    public var modelContext: ModelContext? {
//        get {
//            // This will handle main actor checking internally
//            self[ModelContextKey.self]
//        }
//        set {
//            // This will store on main actor if needed
//            self[ModelContextKey.self] = newValue
//        }
//    }
//}
//
//// MARK: - Protocol Definitions
//
//public protocol NetworkService: Sendable {
//    func fetchData(from url: URL) async throws -> Data
//}
//
//public protocol UserService: Sendable {
//    var currentUser: User? { get async }
//    func login(email: String, password: String) async throws -> User
//    func logout() async throws
//}
//
//public protocol AnalyticsService: Sendable {
//    func track(event: String, parameters: [String: String]?) async
//}
//
//// MARK: - Models
//
//public struct User: Sendable, Identifiable {
//    public let id: UUID
//    public let name: String
//    public let email: String
//
//    public init(id: UUID = UUID(), name: String, email: String) {
//        self.id = id
//        self.name = name
//        self.email = email
//    }
//}
//
///// Example model for your tinyCTA feature
//@Model
//public class CTAItem: @unchecked Sendable {
//    public var title: String
//    public var content: String
//    public var createdAt: Date
//
//    public init(title: String, content: String) {
//        self.title = title
//        self.content = content
//        self.createdAt = Date()
//    }
//}
//
//// MARK: - Live Implementations
//
//public final class DefaultNetworkService: NetworkService, @unchecked Sendable {
//    public init() {}
//
//    public func fetchData(from url: URL) async throws -> Data {
//        let (data, _) = try await URLSession.shared.data(from: url)
//        return data
//    }
//}
//
//@MainActor
//public final class DefaultUserService: UserService, @unchecked Sendable {
//    private var _currentUser: User?
//
//    nonisolated public init() {}
//
//    public var currentUser: User? {
//        get async { _currentUser }
//    }
//
//    public func login(email: String, password: String) async throws -> User {
//        try await Task.sleep(nanoseconds: 1_000_000_000)
//        let user = User(name: "John Doe", email: email)
//        _currentUser = user
//        return user
//    }
//
//    public func logout() async throws {
//        _currentUser = nil
//    }
//}
//
//public final class DefaultAnalyticsService: AnalyticsService, @unchecked Sendable {
//    public init() {}
//
//    public func track(event: String, parameters: [String: String]?) async {
//        print("Analytics: \(event) - \(parameters ?? [:])")
//    }
//}
//
//// MARK: - Mock Implementations for Testing
//
//public final class MockNetworkService: NetworkService, @unchecked Sendable {
//    public var mockData: Data = Data()
//    public var shouldThrow: Bool = false
//
//    public init() {}
//
//    public func fetchData(from url: URL) async throws -> Data {
//        if shouldThrow {
//            throw URLError(.networkConnectionLost)
//        }
//        return mockData
//    }
//}
//
//public final class MockUserService: UserService, @unchecked Sendable {
//    public var mockUser: User?
//    public var shouldFailLogin: Bool = false
//
//    public init() {}
//
//    public var currentUser: User? {
//        get async { mockUser }
//    }
//
//    public func login(email: String, password: String) async throws -> User {
//        if shouldFailLogin {
//            throw URLError(.userAuthenticationRequired)
//        }
//        let user = User(name: "Mock User", email: email)
//        mockUser = user
//        return user
//    }
//
//    public func logout() async throws {
//        mockUser = nil
//    }
//}
//
//public final class MockAnalyticsService: AnalyticsService, @unchecked Sendable {
//    public var trackedEvents: [(event: String, parameters: [String: String]?)] = []
//
//    public init() {}
//
//    public func track(event: String, parameters: [String: String]?) async {
//        trackedEvents.append((event, parameters))
//    }
//}
//
//// MARK: - TinyTCA Integration Example
//
///// TodoFeature2 using the dependency injection framework
//@MainActor
//struct TodoFeature2: Sendable {
//    @MainActorDependency(ModelContextKey.self) var modelContext
//    @Dependency(AnalyticsServiceKey.self) var analytics
//
//    struct State: Equatable, Sendable {
//        var items: [CTAItem] = []
//        var newTitle = ""
//        var newContent = ""
//        var isLoading = false
//    }
//
//    enum Action: Equatable, Sendable {
//        case loadItems
//        case addItem
//        case deleteItem(CTAItem)
//        case updateNewTitle(String)
//        case updateNewContent(String)
//    }
//
//    func reduce(state: inout State, action: Action) -> [Action] {
//        switch action {
//        case .loadItems:
//            state.isLoading = true
//            state.isLoading = false
//            return []
//
//        case .addItem:
//            guard let context = modelContext else { return [] }
//
//            let item = CTAItem(title: state.newTitle, content: state.newContent)
//            context.insert(item)
//
////            Task { @MainActor in
////                await analytics.track(event: "todo_item_created", parameters: [
////                    "title_length": "\(state.newTitle.count)",
////                    "has_content": "\(!state.newContent.isEmpty)"
////                ])
////            }
//
//            state.newTitle = ""
//            state.newContent = ""
//            return []
//
//        case let .deleteItem(item):
//            guard let context = modelContext else { return [] }
//
//            context.delete(item)
//
//            Task { @MainActor in
//                await analytics.track(event: "todo_item_deleted", parameters: nil)
//            }
//            return []
//
//        case let .updateNewTitle(title):
//            state.newTitle = title
//            return []
//
//        case let .updateNewContent(content):
//            state.newContent = content
//            return []
//        }
//    }
//}
//
//// MARK: - SwiftUI Integration (Optional)
//
///// SwiftUI integration for dependency injection
//public struct DependencyProvider<Content: View>: View {
//    let content: Content
//    let dependencies: DependencyValues
//
//    public init(
//        dependencies: DependencyValues = DependencyValues(),
//        @ViewBuilder content: () -> Content
//    ) {
//        self.dependencies = dependencies
//        self.content = content()
//    }
//
//    public var body: some View {
//        content
//            .onAppear {
//                // Set dependencies directly in the current storage
//                let currentStorage = DependencyValues.current.storage
//                let newStorage = dependencies.storage
//
//                // Copy all dependencies from the provided container
//                // This is a simplified approach - in production you'd want to copy all keys
//                // For now, let's make sure we can at least test with custom dependencies
//            }
//    }
//}
//
//extension View {
//    /// Provide dependencies to SwiftUI views
//    public func dependencies(_ dependencies: DependencyValues) -> some View {
//        DependencyProvider(dependencies: dependencies) {
//            self
//        }
//    }
//
//    /// Inject ModelContext from SwiftUI environment into dependencies
//    public func injectModelContext() -> some View {
//        modifier(ModelContextInjector())
//    }
//}
//
//@MainActor
//private struct ModelContextInjector: ViewModifier {
//    @Environment(\.modelContext) private var modelContext
//
//    func body(content: Content) -> some View {
//        content
//            .onAppear {
//                // Set the ModelContext in the current task-local storage
//                let currentStorage = DependencyValues.current.storage
//                currentStorage.set(modelContext, for: ModelContextKey.self)
//            }
//            .onChange(of: modelContext) { oldValue, newValue in
//                // Update if ModelContext changes
//                let currentStorage = DependencyValues.current.storage
//                currentStorage.set(newValue, for: ModelContextKey.self)
//            }
//    }
//}
//
//// MARK: - SwiftUI Views
//
//@MainActor
//public struct TinyCTAFeature: View {
//    @State private var feature = TodoFeature2()
//    @State private var state = TodoFeature2.State()
//    @Query private var ctaItems: [CTAItem]
//
//    public init() {}
//
//    public var body: some View {
//        NavigationView {
//            VStack {
//                List {
//                    ForEach(ctaItems) { item in
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(item.title)
//                                .font(.headline)
//                            Text(item.content)
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .swipeActions {
//                            Button("Delete", role: .destructive) {
//                                send(.deleteItem(item))
//                            }
//                        }
//                    }
//                }
//
//                VStack {
//                    TextField("Title", text: .init(
//                        get: { state.newTitle },
//                        set: { send(.updateNewTitle($0)) }
//                    ))
//                    .textFieldStyle(.roundedBorder)
//
//                    TextField("Content", text: .init(
//                        get: { state.newContent },
//                        set: { send(.updateNewContent($0)) }
//                    ))
//                    .textFieldStyle(.roundedBorder)
//
//                    Button("Add Item") {
//                        send(.addItem)
//                    }
//                    .disabled(state.newTitle.isEmpty)
//                    .buttonStyle(.borderedProminent)
//                }
//                .padding()
//            }
//            .navigationTitle("Tiny CTA")
//        }
//    }
//
//    private func send(_ action: TodoFeature2.Action) {
//        let effects = feature.reduce(state: &state, action: action)
//        // Handle effects if needed
//    }
//}
//
//public struct ContentView2: View {
//    @Dependency(NetworkServiceKey.self) var networkService
//    @Dependency(UserServiceKey.self) var userService
//    @Dependency(AnalyticsServiceKey.self) var analytics
//
//    @State private var user: User?
//    @State private var isLoading = false
//
//    public init() {}
//
//    public var body: some View {
//        TabView {
//            mainContent
//                .tabItem {
//                    Label("Home", systemImage: "house")
//                }
//
//            TinyCTAFeature()
//                .tabItem {
//                    Label("CTA", systemImage: "megaphone")
//                }
//        }
//        .task {
//            user = await userService.currentUser
//        }
//    }
//
//    private var mainContent: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                if let user = user {
//                    Text("Welcome, \(user.name)!")
//                        .font(.title2)
//
//                    Button("Logout") {
//                        Task {
//                            await logout()
//                        }
//                    }
//                    .buttonStyle(.borderedProminent)
//                } else {
//                    if isLoading {
//                        ProgressView("Logging in...")
//                    } else {
//                        Button("Login") {
//                            Task {
//                                await login()
//                            }
//                        }
//                        .buttonStyle(.borderedProminent)
//                    }
//                }
//
//                Button("Fetch Data") {
//                    Task {
//                        await fetchSampleData()
//                    }
//                }
//                .buttonStyle(.bordered)
//            }
//            .navigationTitle("Dependency Example")
//        }
//    }
//
//    private func login() async {
//        isLoading = true
//        do {
//            user = try await userService.login(email: "user@example.com", password: "password")
//            await analytics.track(event: "user_login", parameters: ["method": "email"])
//        } catch {
//            print("Login failed: \(error)")
//        }
//        isLoading = false
//    }
//
//    private func logout() async {
//        do {
//            try await userService.logout()
//            user = nil
//            await analytics.track(event: "user_logout", parameters: nil)
//        } catch {
//            print("Logout failed: \(error)")
//        }
//    }
//
//    private func fetchSampleData() async {
//        do {
//            guard let url = URL(string: "https://api.github.com/users/octocat") else { return }
//            let data = try await networkService.fetchData(from: url)
//            print("Fetched \(data.count) bytes")
//            await analytics.track(event: "data_fetch", parameters: ["endpoint": "github_user"])
//        } catch {
//            print("Fetch failed: \(error)")
//        }
//    }
//}
//
//// MARK: - App Integration Example
//
////@main
////public struct DependencyApp: App {
////    public init() {}
////
////    public var body: some Scene {
////        WindowGroup {
////            DependencyAppView()
////                .modelContainer(createModelContainer())
////        }
////    }
////
////    private func createModelContainer() -> ModelContainer {
////        let schema = Schema([CTAItem.self])
////        let modelConfiguration = ModelConfiguration(
////            schema: schema,
////            isStoredInMemoryOnly: false,
////            cloudKitDatabase: .automatic
////        )
////
////        do {
////            return try ModelContainer(for: schema, configurations: [modelConfiguration])
////        } catch {
////            fatalError("Could not create ModelContainer: \(error)")
////        }
////    }
////}
////
////@MainActor
////struct DependencyAppView: View {
////    @Environment(\.modelContext) private var modelContext
////
////    var body: some View {
////        ContentView2()
////            .onAppear {
////                var deps = DependencyValues()
////                deps.modelContext = modelContext
////                DependencyValues.setCurrent(deps)
////            }
////    }
////}
//
//// MARK: - Usage Examples
//
///// Example of using dependencies in any Swift context
//public func exampleUsage() async {
//    let networkService = DependencyValues.current.networkService
//    let analytics = DependencyValues.current.analyticsService
//
//    do {
//        let url = URL(string: "https://api.example.com/data")!
//        let data = try await networkService.fetchData(from: url)
//        await analytics.track(event: "data_fetched", parameters: ["size": "\(data.count)"])
//    } catch {
//        await analytics.track(event: "fetch_failed", parameters: ["error": error.localizedDescription])
//    }
//}
//
///// Example of testing with mocked dependencies
//public func exampleTest() async {
//    await withDependencies { deps in
//        let mockNetwork = MockNetworkService()
//        mockNetwork.mockData = "test data".data(using: .utf8)!
//        deps.networkService = mockNetwork
//
//        let mockAnalytics = MockAnalyticsService()
//        deps.analyticsService = mockAnalytics
//    } operation: {
//        await exampleUsage()
//
//        let analytics = DependencyValues.current.analyticsService
//        let mockAnalytics = analytics as! MockAnalyticsService
//        assert(mockAnalytics.trackedEvents.count == 1)
//        assert(mockAnalytics.trackedEvents[0].event == "data_fetched")
//    }
//}
//
///// Example class using dependency injection
//public class BusinessService {
//    @Dependency(NetworkServiceKey.self) var networkService
//    @Dependency(AnalyticsServiceKey.self) var analytics
//
//    public init() {}
//
//    public func performOperation() async {
//        do {
//            let url = URL(string: "https://api.example.com/data")!
//            let data = try await networkService.fetchData(from: url)
//            await analytics.track(event: "operation_success", parameters: ["size": "\(data.count)"])
//        } catch {
//            await analytics.track(event: "operation_failed", parameters: ["error": error.localizedDescription])
//        }
//    }
//}
//
///// Example of creating and using a service with custom dependencies
//public func createServiceWithMocks() async {
//    let service = withDependencies { deps in
//        let mockNetwork = MockNetworkService()
//        mockNetwork.mockData = "test data".data(using: .utf8)!
//        deps.networkService = mockNetwork
//
//        let mockAnalytics = MockAnalyticsService()
//        deps.analyticsService = mockAnalytics
//    } operation: {
//        BusinessService()
//    }
//
//    await service.performOperation()
//
//    let analytics = DependencyValues.current.analyticsService as! MockAnalyticsService
//    print("Tracked events: \(analytics.trackedEvents)")
//}
