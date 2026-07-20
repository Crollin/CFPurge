import AppKit
import SwiftUI

enum SettingsWindowPresenter {
    private static let windowTitle = "Réglages CFPurge"

    @MainActor
    static func present(openWindow: OpenWindowAction) {
        NSApp.activate(ignoringOtherApps: true)

        let existingWindows = NSApp.windows.filter { $0.title == windowTitle }

        if let window = existingWindows.first {
            window.makeKeyAndOrderFront(nil)
            for duplicate in existingWindows.dropFirst() {
                duplicate.close()
            }
            return
        }

        openWindow(id: "settings-window")
    }
}
