import AppKit
import SwiftUI

@main
struct CFPurgeApp: App {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var dnsViewModel = DNSViewModel()
    @StateObject private var updater = UpdaterManager()

    var body: some Scene {
        MenuBarExtra("CFPurge", systemImage: "cloud.fill") {
            MenuBarView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quitter CFPurge") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }

        Window("Réglages CFPurge", id: "settings-window") {
            SettingsView()
                .environmentObject(viewModel)
                .environmentObject(updater)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 680, height: 520)

        Window("DNS", id: "dns-window") {
            Group {
                if let site = viewModel.dnsSite {
                    DNSRecordsView(site: site)
                } else {
                    Text("Aucun site sélectionné.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .environmentObject(dnsViewModel)
            .environmentObject(viewModel)
        }
        .defaultSize(width: 720, height: 560)
    }
}
