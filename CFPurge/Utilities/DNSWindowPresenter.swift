import AppKit
import SwiftUI

enum DNSWindowPresenter {
    private static let windowTitle = "DNS"

    @MainActor
    static func present(openWindow: OpenWindowAction) {
        DockVisibilityController.showInDock()

        let existingWindows = NSApp.windows.filter { $0.title.hasPrefix(windowTitle) }

        if let window = existingWindows.first {
            window.makeKeyAndOrderFront(nil)
            for duplicate in existingWindows.dropFirst() {
                duplicate.close()
            }
            return
        }

        openWindow(id: "dns-window")
    }
}
