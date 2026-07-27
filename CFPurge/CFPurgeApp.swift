import AppKit
import SwiftUI

@main
struct CFPurgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var dnsViewModel = DNSViewModel()
    @StateObject private var updater = UpdaterManager()

    var body: some Scene {
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

        Window("CFPurge", id: "main-window") {
            MainWindowView()
                .environmentObject(viewModel)
                .onAppear {
                    appDelegate.bind(viewModel: viewModel)
                }
        }
        .defaultSize(width: 900, height: 600)

        Window("Réglages CFPurge", id: "settings-window") {
            SettingsView()
                .environmentObject(viewModel)
                .environmentObject(updater)
                .onAppear {
                    appDelegate.bind(viewModel: viewModel)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 780, height: 560)

        Window("DNS", id: "dns-window") {
            Group {
                if let site = viewModel.dnsSite {
                    DNSRecordsView(site: site)
                } else {
                    Text("Aucun site sélectionné.")
                        .foregroundStyle(CFDesignTokens.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cfWindowBackground()
                }
            }
            .environmentObject(dnsViewModel)
            .environmentObject(viewModel)
        }
        .defaultSize(width: 720, height: 560)
    }
}
