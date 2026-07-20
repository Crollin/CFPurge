import SwiftUI

@main
struct CFPurgeApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra("CFPurge", systemImage: "cloud.fill") {
            MenuBarView()
                .environmentObject(viewModel)
                .background {
                    SettingsWindowOpener()
                        .environmentObject(viewModel)
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }

        Window("Réglages CFPurge", id: "settings-window") {
            SettingsView()
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 500)
    }
}
