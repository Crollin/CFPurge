import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private weak var viewModel: AppViewModel?
    private var pendingURLs: [URL] = []
    private var windowCloseObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let closingWindow = notification.object as? NSWindow else { return }
            Task { @MainActor in
                DockVisibilityController.hideFromDockIfNeeded(excluding: closingWindow)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let windowCloseObserver {
            NotificationCenter.default.removeObserver(windowCloseObserver)
            self.windowCloseObserver = nil
        }
    }

    func bind(viewModel: AppViewModel) {
        self.viewModel = viewModel
        let queued = pendingURLs
        pendingURLs.removeAll()
        for url in queued {
            Task { await viewModel.handleOpenURL(url) }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let viewModel {
            for url in urls {
                Task { await viewModel.handleOpenURL(url) }
            }
        } else {
            pendingURLs.append(contentsOf: urls)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        let managed = NSApp.windows.filter { window in
            guard window.isVisible || window.isMiniaturized else { return false }
            if window.title == "Réglages CFPurge" { return true }
            return window.title.hasPrefix("DNS")
        }

        if let window = managed.first {
            DockVisibilityController.showInDock()
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        }

        return true
    }
}
