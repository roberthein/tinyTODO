import Foundation
import tinyAPI

struct APIClientDependency {
    let client: any APIClientProtocol

    static let live = APIClientDependency(client: TinyAPIClient.live)
    static let mock = APIClientDependency(client: MockTinyAPIClient.demo)
    static let preview = APIClientDependency(client: MockTinyAPIClient.preview)
}
