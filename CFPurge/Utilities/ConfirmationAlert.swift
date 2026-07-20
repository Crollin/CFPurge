import AppKit

enum ConfirmationAlert {
    /// Affiche une confirmation modale fiable dans une app MenuBarExtra.
    /// SwiftUI `.alert` ne déclenche pas toujours les actions des boutons dans ce contexte.
    @MainActor
    static func confirm(
        title: String,
        message: String,
        confirmTitle: String,
        cancelTitle: String = "Annuler",
        isDestructive: Bool = false
    ) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = isDestructive ? .warning : .informational
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: cancelTitle)

        if isDestructive, let confirmButton = alert.buttons.first {
            confirmButton.hasDestructiveAction = true
        }

        return alert.runModal() == .alertFirstButtonReturn
    }

    /// Affiche une alerte informative (succès, erreur, etc.).
    @MainActor
    static func inform(
        title: String,
        message: String,
        buttonTitle: String = "OK",
        style: NSAlert.Style = .informational
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: buttonTitle)
        alert.runModal()
    }
}
