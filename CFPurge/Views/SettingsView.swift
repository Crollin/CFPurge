import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var updater: UpdaterManager
    @Environment(\.openWindow) private var openWindow

    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "Général"
        case token = "Jeton API"
        case sites = "Sites"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "slider.horizontal.3"
            case .token: return "key.fill"
            case .sites: return "globe"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 170, max: 200)
        } detail: {
            Group {
                switch selectedTab {
                case .general:
                    generalSettings
                case .token:
                    tokenSettings
                case .sites:
                    sitesSettings
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(selectedTab.rawValue)
        }
        .frame(minWidth: 640, minHeight: 480)
        .sheet(isPresented: $viewModel.showingSiteEditor) {
            SiteEditorView(site: viewModel.editingSite)
                .environmentObject(viewModel)
        }
    }

    private var generalSettings: some View {
        Form {
            Section("Fonctionnalités") {
                Toggle("Activer la gestion DNS", isOn: Binding(
                    get: { viewModel.dnsManagementEnabled },
                    set: { viewModel.setDNSManagementEnabled($0) }
                ))

                Text("Nécessite la permission Zone > DNS > Edit sur votre token API Cloudflare, en plus de Cache Purge.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.dnsManagementEnabled {
                    Toggle("Autoriser la modification des enregistrements existants", isOn: Binding(
                        get: { viewModel.dnsAllowModifyExisting },
                        set: { viewModel.setDNSAllowModifyExisting($0) }
                    ))

                    Text("Désactivé par défaut. Une confirmation est demandée à l'activation. Une mauvaise modification DNS peut rendre un site inaccessible.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notifications") {
                Toggle("Son des notifications de purge", isOn: Binding(
                    get: { viewModel.soundNotificationsEnabled },
                    set: { viewModel.setSoundNotificationsEnabled($0) }
                ))

                Toggle("Afficher les URLs dans les notifications", isOn: Binding(
                    get: { viewModel.showURLsInNotifications },
                    set: { viewModel.setShowURLsInNotifications($0) }
                ))

                Text("Par défaut, les notifications n'affichent que le nom du site. Activez l'option pour inclure l'URL purgée (visible dans le Centre de notifications).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Démarrage") {
                Toggle("Lancer CFPurge à la connexion", isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))

                Text(LaunchAtLoginService.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let message = viewModel.launchAtLoginMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Mises à jour") {
                LabeledContent("Version installée") {
                    Text(updater.currentVersion)
                        .foregroundStyle(.secondary)
                }

                Toggle("Vérifier automatiquement les mises à jour", isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                ))

                HStack {
                    Button("Vérifier maintenant") {
                        updater.checkForUpdates()
                    }
                    .disabled(updater.isChecking || updater.isInstalling)

                    if updater.isChecking {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if updater.updateAvailable, let latestVersion = updater.latestVersion {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Version \(latestVersion) disponible", systemImage: "arrow.down.circle.fill")
                            .foregroundStyle(.blue)

                        HStack {
                            Button(updater.isInstalling ? "Installation…" : "Installer la mise à jour") {
                                updater.installUpdate()
                            }
                            .disabled(updater.isInstalling)

                            Button("Voir la release") {
                                updater.openReleasePage()
                            }
                        }
                    }
                }

                if let installError = updater.installError {
                    Text(installError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text("Les mises à jour sont téléchargées depuis GitHub Releases. L'app se ferme brièvement pendant l'installation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var tokenSettings: some View {
        Form {
            Section("Jeton API Cloudflare") {
                SecureField("Jeton API", text: $viewModel.tokenInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Enregistrer le jeton") {
                        viewModel.saveToken()
                    }

                    Button("Tester la connexion") {
                        Task { await viewModel.verifyToken() }
                    }
                    .disabled(!viewModel.tokenConfigured)

                    if viewModel.tokenConfigured {
                        Button("Supprimer", role: .destructive) {
                            viewModel.deleteToken()
                        }
                    }
                }

                if viewModel.tokenConfigured {
                    Label("Jeton configuré", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }

                if let result = viewModel.connectionTestResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Permissions requises : Zone > Cache Purge > Edit. Ajoutez Zone > DNS > Edit si la gestion DNS est activée. N'utilisez jamais la Global API Key.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var sitesSettings: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.sites.isEmpty {
                ContentUnavailableView(
                    "Aucun site",
                    systemImage: "globe",
                    description: Text("Ajoutez un site Cloudflare pour commencer à purger le cache.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.sites) { site in
                        SiteSettingsRow(
                            site: site,
                            dnsEnabled: viewModel.dnsManagementEnabled,
                            onEdit: { viewModel.beginEditSite(site) },
                            onDNS: { viewModel.openDNS(for: site, openWindow: openWindow) }
                        )
                    }
                    .onMove(perform: viewModel.moveSites)
                    .onDelete { indexSet in
                        indexSet.map { viewModel.sites[$0] }.forEach(viewModel.deleteSite)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            Divider()

            HStack {
                Text("Glissez-déposez pour définir l'ordre d'affichage dans la barre de menus.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Ajouter un site") {
                    viewModel.beginAddSite()
                }
            }
            .padding()
        }
    }
}

private struct SiteSettingsRow: View {
    let site: Site
    let dnsEnabled: Bool
    let onEdit: () -> Void
    let onDNS: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 4) {
                Text(site.name)
                    .font(.headline)

                Text(site.domain)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Zone : \(site.zoneId)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }

            Spacer()

            HStack(spacing: 8) {
                if dnsEnabled {
                    Button("DNS", action: onDNS)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }

                Button("Modifier", action: onEdit)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
        .environmentObject(UpdaterManager())
}
