import Foundation

enum CFPurgeError: LocalizedError, Equatable {
    case missingToken
    case invalidURL
    case domainMismatch
    case emptyURL
    case noSiteSelected
    case unauthorized
    case zoneNotFound
    case rateLimited
    case networkError(String)
    case apiError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Aucun jeton API Cloudflare configuré. Ajoutez-le dans les réglages."
        case .invalidURL:
            return "URL invalide."
        case .domainMismatch:
            return "L'URL ne correspond pas au domaine du site sélectionné."
        case .emptyURL:
            return "Veuillez saisir une URL à purger."
        case .noSiteSelected:
            return "Aucun site sélectionné."
        case .unauthorized:
            return "Jeton API invalide ou expiré."
        case .zoneNotFound:
            return "Zone Cloudflare introuvable."
        case .rateLimited:
            return "Limite de requêtes atteinte. Réessayez dans quelques minutes."
        case .networkError(let detail):
            return "Erreur réseau : \(detail)"
        case .apiError(let message):
            return "Erreur Cloudflare : \(message)"
        case .decodingError:
            return "Réponse Cloudflare illisible."
        }
    }
}
