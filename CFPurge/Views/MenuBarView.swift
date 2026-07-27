import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if viewModel.needsSetup {
                setupPrompt
            } else {
                quickActions
            }

            Divider().overlay(CFDesignTokens.border)

            footer
        }
        .padding(14)
        .frame(width: 320)
        .cfWindowBackground()
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: CFDesignTokens.animationNormal), value: viewModel.status)
        .onAppear {
            viewModel.openSettingsIfNeeded {
                SettingsWindowPresenter.present(openWindow: openWindow)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            CFPurgeMark(size: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text("CFPurge")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CFDesignTokens.textPrimary)
                Text("Cache Cloudflare")
                    .font(.caption2)
                    .foregroundStyle(CFDesignTokens.textSecondary)
            }
            Spacer()
            CFStatusBadge(style: viewModel.needsSetup ? .warning : .active)
        }
    }

    private var setupPrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Configuration requise", systemImage: "exclamationmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CFDesignTokens.accentOrange)

            if !viewModel.tokenConfigured {
                Text("1. Ajoutez votre token API Cloudflare")
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textSecondary)
            }
            if viewModel.sites.isEmpty {
                Text("2. Ajoutez au moins un site")
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textSecondary)
            }

            CFButton(title: "Ouvrir les réglages", style: .primary) {
                openSettingsPanel()
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            sitePicker

            CFTextField(placeholder: "URL ou chemin (ex. /page)", text: $viewModel.urlInput)
                .disabled(viewModel.isLoading || viewModel.selectedSite == nil)

            HStack(spacing: 8) {
                CFButton(title: "Purger URL", icon: "bolt.fill", style: .primary) {
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

            CFButton(title: "Vider tous les éléments", style: .destructive) {
                confirmPurgeEverything()
            }
            .disabled(viewModel.isLoading || viewModel.selectedSite == nil)

            if viewModel.status.message != nil {
                PurgeStatusBanner(status: viewModel.status)
            }

            if viewModel.dnsManagementEnabled {
                CFButton(title: "Gérer le DNS", icon: "network", style: .secondary) {
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
                        .foregroundStyle(CFDesignTokens.textPrimary)
                    if let domain = viewModel.selectedSite?.domain {
                        Text(domain)
                            .font(.caption)
                            .foregroundStyle(CFDesignTokens.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CFDesignTokens.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(CFDesignTokens.surface, in: RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous)
                    .strokeBorder(CFDesignTokens.border, lineWidth: 1)
            }
        }
        .menuStyle(.borderlessButton)
        .disabled(viewModel.sites.isEmpty)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Button {
                MainWindowPresenter.present(openWindow: openWindow)
            } label: {
                HStack {
                    Image(systemName: "macwindow")
                        .font(.caption)
                    Text("Ouvrir CFPurge")
                        .font(.caption.weight(.medium))
                    Spacer()
                }
                .foregroundStyle(CFDesignTokens.accent)
            }
            .buttonStyle(.plain)

            HStack {
                Button("Réglages") {
                    openSettingsPanel()
                }
                .buttonStyle(.plain)
                .foregroundStyle(CFDesignTokens.textSecondary)
                .font(.caption)

                Spacer()

                Button("Quitter") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(CFDesignTokens.textTertiary)
                .font(.caption)
            }
        }
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
