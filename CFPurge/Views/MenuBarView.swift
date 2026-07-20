import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CFPurge")
                    .font(.headline)
                Spacer()
                Button {
                    openSettingsPanel()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Réglages")
            }

            if viewModel.needsSetup {
                setupPrompt
            } else {
                purgeControls
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var setupPrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Configuration requise", systemImage: "exclamationmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            if !viewModel.tokenConfigured {
                Text("1. Ajoutez votre token API Cloudflare")
                    .font(.caption)
            }
            if viewModel.sites.isEmpty {
                Text("2. Ajoutez au moins un site (nom, Zone ID, domaine)")
                    .font(.caption)
            }

            Button("Ouvrir les réglages") {
                openSettingsPanel()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var purgeControls: some View {
        Group {
            Picker("Site", selection: Binding(
                get: { viewModel.selectedSite?.id },
                set: { newId in
                    if let id = newId,
                       let site = viewModel.sites.first(where: { $0.id == id }) {
                        viewModel.selectSite(site)
                    }
                }
            )) {
                ForEach(viewModel.sites) { site in
                    Text(site.name).tag(Optional(site.id))
                }
            }
            .labelsHidden()

            TextField("URL ou chemin (ex. /page)", text: $viewModel.urlInput)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isLoading || viewModel.selectedSite == nil)

            Button("Personnaliser le vidage") {
                Task { await viewModel.purgeURL() }
            }
            .disabled(viewModel.isLoading || viewModel.selectedSite == nil || viewModel.urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Vider tous les éléments") {
                confirmPurgeEverything()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(viewModel.isLoading || viewModel.selectedSite == nil)

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            if let message = viewModel.status.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Attention : vider tout le cache peut impacter les performances temporairement.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func openSettingsPanel() {
        openSettings()
        openWindow(id: "settings-window")
        viewModel.shouldOpenSettings = false
    }

    private func confirmPurgeEverything() {
        guard let site = viewModel.selectedSite else { return }

        let confirmed = ConfirmationAlert.confirm(
            title: "Vider tout le cache ?",
            message: "Cette action purgera l'intégralité du cache Cloudflare pour \(site.name).",
            confirmTitle: "Vider",
            isDestructive: true
        )

        guard confirmed else { return }

        Task { await viewModel.purgeEverything() }
    }

    private var statusColor: Color {
        switch viewModel.status {
        case .success:
            return .green
        case .error:
            return .red
        case .loading, .idle:
            return .secondary
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppViewModel())
}
