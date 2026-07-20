import Foundation

enum DeepLinkAction: Equatable {
    case purgeURL(siteId: UUID, url: String)
    case purgeEverything(siteId: UUID)
}

enum DeepLinkParser {
    static let scheme = "cfpurge"

    static func parse(_ url: URL) throws -> DeepLinkAction {
        guard url.scheme?.lowercased() == scheme else {
            throw CFPurgeError.invalidDeepLink
        }

        let host = (url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).lowercased()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []

        func query(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard let siteIdRaw = query("siteId"), let siteId = UUID(uuidString: siteIdRaw) else {
            throw CFPurgeError.invalidDeepLink
        }

        switch host {
        case "purge":
            guard let rawURL = query("url"), !rawURL.isEmpty else {
                throw CFPurgeError.invalidDeepLink
            }
            return .purgeURL(siteId: siteId, url: rawURL)
        case "purge-all":
            return .purgeEverything(siteId: siteId)
        default:
            throw CFPurgeError.invalidDeepLink
        }
    }

    static func makePurgeURL(siteId: UUID, url: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "purge"
        components.queryItems = [
            URLQueryItem(name: "siteId", value: siteId.uuidString),
            URLQueryItem(name: "url", value: url)
        ]
        return components.url!
    }

    static func makePurgeAllURL(siteId: UUID) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "purge-all"
        components.queryItems = [
            URLQueryItem(name: "siteId", value: siteId.uuidString)
        ]
        return components.url!
    }
}
