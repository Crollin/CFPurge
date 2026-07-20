import Foundation

enum PurgeStatus: Equatable {
    case idle
    case loading
    case success(String)
    case error(String)

    var message: String? {
        switch self {
        case .idle:
            return nil
        case .loading:
            return "Vidage en cours…"
        case .success(let message):
            return message
        case .error(let message):
            return message
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
