import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private weak var viewModel: AppViewModel?
    private var pendingURLs: [URL] = []

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
}
