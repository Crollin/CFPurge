import AppKit
import SwiftUI

@main
struct CFPurgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var dnsViewModel = DNSViewModel()
    @StateObject private var updater = UpdaterManager()

    var body: some Scene {
        // Label = Image (pas un View Canvas) : sinon pas d'icône barre de menus.
        MenuBarExtra {
            MenuBarView()
                .environmentObject(viewModel)
                .onAppear {
                    appDelegate.bind(viewModel: viewModel)
                }
        } label: {
            Image(nsImage: CFPurgeMenuBarIcon.nsImage)
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
                .onAppear {
                    appDelegate.bind(viewModel: viewModel)
                }
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
