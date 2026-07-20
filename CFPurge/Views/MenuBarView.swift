import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if viewModel.needsSetup {
                setupPrompt
            } else {
                purgeControls
            }

            Divider()

            Button("Quitter CFPurge") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(width: 340)
        .animation(.easeInOut(duration: 0.2), value: viewModel.status)
        .onAppear {
            viewModel.openSettingsIfNeeded {
                SettingsWindowPresenter.present(openWindow: openWindow)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            CFPurgeMark(size: 28)

            Text("CFPurge")
                .font(.headline.weight(.semibold))

            Spacer()

            Button {
                openSettingsPanel()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Réglages")
        }
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
            .tint(CFPurgeBrand.orange)
            .controlSize(.large)
        }
    }

    private var purgeControls: some View {
        Group {
            sitePicker

            TextField("URL ou chemin (ex. /page)", text: $viewModel.urlInput)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isLoading || viewModel.selectedSite == nil)

            HStack(spacing: 8) {
                Button("Personnaliser le vidage") {
                    Task { await viewModel.purgeURL() }
                }
                .disabled(
                    viewModel.isLoading
                        || viewModel.selectedSite == nil
                        || viewModel.urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Button("Vider tous les éléments") {
                confirmPurgeEverything()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(viewModel.isLoading || viewModel.selectedSite == nil)

            if viewModel.status.message != nil {
                PurgeStatusBanner(status: viewModel.status)
            }

            Text("Attention : vider tout le cache peut impacter les performances temporairement.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.dnsManagementEnabled {
                Divider()

                Button("Gérer le DNS") {
                    viewModel.openDNS(for: viewModel.selectedSite, openWindow: openWindow)
                }
                .disabled(viewModel.selectedSite == nil)
            }
        }
    }

    private var sitePicker: some View {
        Menu {
            ForEach(viewModel.sites) { site in
                Button {
                    viewModel.selectSite(site)
                } label: {
                    if viewModel.selectedSite?.id == site.id {
                        Label(site.name, systemImage: "checkmark")
                    } else {
                        Text(site.name)
                    }
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedSite?.name ?? "Choisir un site")
                        .font(.body.weight(.medium))
                    if let domain = viewModel.selectedSite?.domain {
                        Text(domain)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .disabled(viewModel.sites.isEmpty)
    }

    private func openSettingsPanel() {
        SettingsWindowPresenter.present(openWindow: openWindow)
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
}

#Preview {
    MenuBarView()
        .environmentObject(AppViewModel())
}
