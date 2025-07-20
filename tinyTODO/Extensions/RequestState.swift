import Foundation
import tinyAPI

extension RequestState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }

    func clearError() -> RequestState<T> {
        if case .failure = self { return .idle }
        return self
    }
}
