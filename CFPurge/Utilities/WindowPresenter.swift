import SwiftUI

enum WindowPresenter {
    static let mainWindowId = "main-window"
    static let settingsWindowId = "settings-window"

    @MainActor
    static func presentMain(
        openWindow: OpenWindowAction,
        panel: MainWindowPanel = .cache,
        viewModel: AppViewModel? = nil
    ) {
        viewModel?.mainWindowPanel = panel
        DockVisibilityController.showInDock()
        openWindow(id: mainWindowId)
    }

    @MainActor
    static func presentSettings(openWindow: OpenWindowAction) {
        DockVisibilityController.showInDock()
        openWindow(id: settingsWindowId)
    }
}
