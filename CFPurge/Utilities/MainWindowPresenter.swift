import AppKit
import SwiftUI

enum MainWindowPresenter {
    private static let windowTitle = "CFPurge"

    @MainActor
    static func present(openWindow: OpenWindowAction, panel: MainWindowPanel = .cache, viewModel: AppViewModel? = nil) {
        viewModel?.mainWindowPanel = panel
        DockVisibilityController.showInDock()

        let existingWindows = NSApp.windows.filter { $0.title == windowTitle }

        if let window = existingWindows.first {
            window.makeKeyAndOrderFront(nil)
            for duplicate in existingWindows.dropFirst() {
                duplicate.close()
            }
            return
        }

        openWindow(id: "main-window")
    }
}
