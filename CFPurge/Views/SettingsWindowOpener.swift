import SwiftUI

/// Ouvre automatiquement les réglages au premier lancement ou sur demande.
struct SettingsWindowOpener: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                openSettingsIfNeeded()
            }
            .onChange(of: viewModel.shouldOpenSettings) { _, shouldOpen in
                guard shouldOpen else { return }
                openSettingsWindow()
                viewModel.shouldOpenSettings = false
            }
    }

    private func openSettingsIfNeeded() {
        guard viewModel.needsSetup else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            openSettingsWindow()
        }
    }

    private func openSettingsWindow() {
        openSettings()
        openWindow(id: "settings-window")
    }
}
