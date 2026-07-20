import Foundation
import ServiceManagement

enum LaunchAtLoginService {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static var statusMessage: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "CFPurge se lance automatiquement à la connexion."
        case .requiresApproval:
            return "Autorisez CFPurge dans Réglages Système → Général → Ouverture à la connexion."
        case .notRegistered:
            return "CFPurge ne se lance pas automatiquement."
        case .notFound:
            return "Installez CFPurge dans le dossier Applications pour activer le démarrage automatique."
        @unknown default:
            return "Statut de démarrage automatique inconnu."
        }
    }
}
