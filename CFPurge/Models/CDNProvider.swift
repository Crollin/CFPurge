import Foundation

enum CDNProvider: String, Codable, CaseIterable, Identifiable, Hashable {
    case cloudflare
    case hostinger

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cloudflare: return "Cloudflare"
        case .hostinger: return "Hostinger"
        }
    }

    var supportsURLPurge: Bool {
        switch self {
        case .cloudflare: return true
        case .hostinger: return false
        }
    }

    var supportsProxiedDNS: Bool {
        switch self {
        case .cloudflare: return true
        case .hostinger: return false
        }
    }
}
