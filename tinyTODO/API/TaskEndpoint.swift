import Foundation
import tinyAPI

enum TaskEndpoint {
    case list
    case create(CreateTaskRequest)
    case update(id: UUID, task: UpdateTaskRequest)
    case delete(id: UUID)
    case toggle(id: UUID)
}

extension TaskEndpoint: TinyAPIEndpoint {
    var baseURL: String { "https://api.todoapp.com" }

    var path: String {
        switch self {
        case .list:
            return "/tasks"
        case .create:
            return "/tasks"
        case .update(let id, _):
            return "/tasks/\(id.uuidString)"
        case .delete(let id):
            return "/tasks/\(id.uuidString)"
        case .toggle(let id):
            return "/tasks/\(id.uuidString)/toggle"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list:
            return .GET
        case .create:
            return .POST
        case .update:
            return .PUT
        case .delete:
            return .DELETE
        case .toggle:
            return .PATCH
        }
    }

    var body: Data? {
        switch self {
        case .create(let request):
            return try? JSONEncoder().encode(request)
        case .update(_, let task):
            return try? JSONEncoder().encode(task)
        default:
            return nil
        }
    }

    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }

    var queryItems: [URLQueryItem]? { nil }
}
