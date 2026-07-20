import Foundation
import UserNotifications

enum PurgeNotificationService {
    private static var authorizationRequested = false

    static func requestAuthorizationIfNeeded() {
        guard !authorizationRequested else { return }
        authorizationRequested = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    @MainActor
    static func notify(
        title: String,
        message: String,
        soundEnabled: Bool,
        isFailure: Bool = false
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        if soundEnabled, !isFailure {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                UNUserNotificationCenter.current().add(request)
            default:
                Task { @MainActor in
                    ConfirmationAlert.inform(title: title, message: message)
                }
            }
        }
    }
}

enum PurgeFeedback {
    @MainActor
    static func showPurgeSuccess(siteName: String, detail: String, soundEnabled: Bool) {
        PurgeNotificationService.notify(
            title: "Cache vidé — \(siteName)",
            message: detail,
            soundEnabled: soundEnabled
        )
    }

    @MainActor
    static func showPurgeFailure(siteName: String, detail: String) {
        PurgeNotificationService.notify(
            title: "Échec du vidage — \(siteName)",
            message: detail,
            soundEnabled: false,
            isFailure: true
        )
    }
}
