import AppKit

/// Affiche temporairement CFPurge dans le Dock pendant qu'une fenêtre
/// (réglages / DNS) est ouverte — l'app reste un agent (`LSUIElement`) au repos.
enum DockVisibilityController {
    private static let managedWindowTitles = ["Réglages CFPurge"]
    private static let managedWindowTitlePrefixes = ["DNS"]

    @MainActor
    static func showInDock() {
        guard NSApp.activationPolicy() != .regular else {
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    static func hideFromDockIfNeeded(excluding closingWindow: NSWindow? = nil) {
        if hasManagedVisibleWindow(excluding: closingWindow) { return }
        guard NSApp.activationPolicy() != .accessory else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    @MainActor
    private static func hasManagedVisibleWindow(excluding closingWindow: NSWindow?) -> Bool {
        NSApp.windows.contains { window in
            if let closingWindow, window === closingWindow { return false }
            guard window.isVisible, !window.isMiniaturized else { return false }
            if managedWindowTitles.contains(window.title) { return true }
            return managedWindowTitlePrefixes.contains { window.title.hasPrefix($0) }
        }
    }
}
