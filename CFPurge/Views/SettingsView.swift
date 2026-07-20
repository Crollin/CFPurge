import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        Form {
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

            Section("Sites") {
                if viewModel.sites.isEmpty {
                    Text("Aucun site enregistré.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.sites) { site in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(site.name)
                                    .font(.headline)
                                Text(site.domain)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Zone : \(site.zoneId)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Modifier") {
                                viewModel.beginEditSite(site)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { viewModel.sites[$0] }.forEach(viewModel.deleteSite)
                    }
                }

                Button("Ajouter un site") {
                    viewModel.beginAddSite()
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 420)
        .sheet(isPresented: $viewModel.showingSiteEditor) {
            SiteEditorView(site: viewModel.editingSite)
                .environmentObject(viewModel)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}
