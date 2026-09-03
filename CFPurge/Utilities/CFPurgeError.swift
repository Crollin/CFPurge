import Foundation

enum CFPurgeError: LocalizedError, Equatable {
    case missingToken(CDNProvider)
    case invalidTokenFormat
    case invalidHostingerTokenFormat
    case globalAPIKeyRejected
    case invalidZoneId
    case invalidHostingUsername
    case invalidDomain
    case invalidSiteName
    case invalidURL
    case domainMismatch
    case emptyURL
    case noSiteSelected
    case urlPurgeUnsupported
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
        case .missingToken(let provider):
            return "Aucun jeton API \(provider.displayName) configuré. Ajoutez-le dans les réglages."
        case .invalidTokenFormat:
            return "Le jeton API semble trop court. Collez un token API Cloudflare (pas la Global API Key)."
        case .invalidHostingerTokenFormat:
            return "Le jeton API Hostinger semble trop court. Collez le token généré dans hPanel → API."
        case .globalAPIKeyRejected:
            return "Les Global API Keys sont refusées. Créez un token API avec des permissions limitées."
        case .invalidZoneId:
            return "Zone ID invalide. Attendu : 32 caractères hexadécimaux (dashboard Cloudflare)."
        case .invalidHostingUsername:
            return "Nom d'utilisateur Hostinger invalide (ex. u123456789)."
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
        case .urlPurgeUnsupported:
            return "La purge par URL n'est pas disponible pour Hostinger. Utilisez « Vider tout »."
        case .unauthorized:
            return "Jeton API invalide ou expiré."
        case .zoneNotFound:
            return "Site ou zone introuvable."
        case .rateLimited:
            return "Limite de requêtes atteinte. Réessayez dans quelques minutes."
        case .networkError(let detail):
            return "Erreur réseau : \(detail)"
        case .apiError(let message):
            return "Erreur API : \(message)"
        case .decodingError:
            return "Réponse API illisible."
        case .dnsPermissionDenied:
            return "Permission DNS insuffisante sur le jeton API."
        case .recordValidationFailed(let message):
            return message
        case .invalidDeepLink:
            return "Lien CFPurge invalide ou incomplet."
        }
    }
}
