import Foundation

enum CFPurgeError: LocalizedError, Equatable {
    case missingToken
    case invalidTokenFormat
    case globalAPIKeyRejected
    case invalidZoneId
    case invalidDomain
    case invalidSiteName
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
    case dnsPermissionDenied
    case recordValidationFailed(String)
    case invalidDeepLink

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Aucun jeton API Cloudflare configuré. Ajoutez-le dans les réglages."
        case .invalidTokenFormat:
            return "Le jeton API semble trop court. Collez un token API Cloudflare (pas la Global API Key)."
        case .globalAPIKeyRejected:
            return "Les Global API Keys sont refusées. Créez un token API avec des permissions limitées."
        case .invalidZoneId:
            return "Zone ID invalide. Attendu : 32 caractères hexadécimaux (dashboard Cloudflare)."
        case .invalidDomain:
            return "Domaine invalide. Utilisez un hostname du type monsite.com (sans https://)."
        case .invalidSiteName:
            return "Le nom du site est obligatoire."
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
        case .dnsPermissionDenied:
            return "Votre token API doit inclure la permission Zone > DNS > Edit."
        case .recordValidationFailed(let message):
            return message
        case .invalidDeepLink:
            return "Lien CFPurge invalide ou incomplet."
        }
    }
}
