import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().overlay(CFDesignTokens.border)
            mainContent
        }
        .cfWindowBackground()
        .cfConfigureWindow()
        .preferredColorScheme(.dark)
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            viewModel.openSettingsIfNeeded {
                SettingsWindowPresenter.present(openWindow: openWindow)
            }
        }
        .sheet(isPresented: $viewModel.showingSiteEditor) {
            SiteEditorView(site: viewModel.editingSite)
                .environmentObject(viewModel)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            sitesSection
            Spacer()
            sidebarFooter
        }
        .frame(width: 260)
        .background(CFDesignTokens.sidebar)
    }

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            CFPurgeMark(size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("CFPurge")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CFDesignTokens.textPrimary)
                Text("Cache Cloudflare")
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textSecondary)
            }
            Spacer()
            CFStatusBadge(style: viewModel.needsSetup ? .warning : .active)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var sitesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CFSectionHeader("Sites")
                Spacer()
                Button {
                    viewModel.beginAddSite()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CFDesignTokens.textSecondary)
                        .frame(width: 22, height: 22)
                        .background(CFDesignTokens.surfaceElevated, in: Circle())
                }
                .buttonStyle(.plain)
                .help("Ajouter un site")
            }
            .padding(.horizontal, 16)

            if viewModel.sites.isEmpty {
                Text("Aucun site configuré")
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textTertiary)
                    .padding(.horizontal, 16)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(viewModel.sites) { site in
                            SiteSidebarRow(
                                site: site,
                                isSelected: viewModel.selectedSite?.id == site.id
                            ) {
                                withAnimation(.easeInOut(duration: CFDesignTokens.animationNormal)) {
                                    viewModel.selectSite(site)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
    }

    private var sidebarFooter: some View {
        Button {
            SettingsWindowPresenter.present(openWindow: openWindow)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .font(.caption.weight(.semibold))
                Text("Réglages")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(CFDesignTokens.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .background(CFDesignTokens.surface.opacity(0.5))
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.needsSetup {
            setupContent
        } else {
            purgeContent
        }
    }

    private var setupContent: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(CFDesignTokens.accentOrange)

            Text("Configuration requise")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CFDesignTokens.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                if !viewModel.tokenConfigured {
                    Text("1. Ajoutez votre token API Cloudflare")
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.textSecondary)
                }
                if viewModel.sites.isEmpty {
                    Text("2. Ajoutez au moins un site (nom, Zone ID, domaine)")
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.textSecondary)
                }
            }

            CFButton(title: "Ouvrir les réglages", style: .primary) {
                SettingsWindowPresenter.present(openWindow: openWindow)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CFDesignTokens.background)
    }

    private var purgeContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentHeader
            Divider().overlay(CFDesignTokens.border)
            contentBody
        }
        .background(CFDesignTokens.background)
        .animation(.easeInOut(duration: CFDesignTokens.animationNormal), value: viewModel.selectedSite?.id)
    }

    private var contentHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            if let site = viewModel.selectedSite {
                CFIconBadge(icon: "globe", color: CFDesignTokens.accent, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(site.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CFDesignTokens.textPrimary)
                    Text(site.domain)
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.textSecondary)
                }
            } else {
                Text("Sélectionnez un site")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CFDesignTokens.textPrimary)
            }

            Spacer()

            HStack(spacing: 8) {
                CFButton(title: "Purger URL", icon: "bolt.fill", style: .primary) {
                    Task { await viewModel.purgeURL() }
                }
                .disabled(
                    viewModel.isLoading
                        || viewModel.selectedSite == nil
                        || viewModel.urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                CFButton(title: "Vider tout", icon: "trash", style: .destructive) {
                    confirmPurgeEverything()
                }
                .disabled(viewModel.isLoading || viewModel.selectedSite == nil)

                if viewModel.dnsManagementEnabled {
                    CFButton(title: "DNS", icon: "network", style: .secondary) {
                        viewModel.openDNS(for: viewModel.selectedSite, openWindow: openWindow)
                    }
                    .disabled(viewModel.selectedSite == nil)
                }
            }
        }
        .padding(20)
    }

    private var contentBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CFCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("URL ou chemin")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(CFDesignTokens.textSecondary)

                        CFTextField(placeholder: "ex. /page ou https://…", text: $viewModel.urlInput)
                            .disabled(viewModel.isLoading || viewModel.selectedSite == nil)

                        HStack(spacing: 8) {
                            CFButton(title: "Personnaliser le vidage", style: .primary) {
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

                        if viewModel.status.message != nil {
                            PurgeStatusBanner(status: viewModel.status)
                        }

                        Text("Attention : vider tout le cache peut impacter les performances temporairement.")
                            .font(.caption2)
                            .foregroundStyle(CFDesignTokens.textTertiary)
                    }
                    .padding(20)
                }
            }
            .padding(20)
        }
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

// MARK: - Site Sidebar Row

private struct SiteSidebarRow: View {
    let site: Site
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal")
                    .font(.caption2)
                    .foregroundStyle(CFDesignTokens.textTertiary)

                CFIconBadge(icon: "globe", color: CFDesignTokens.accent, size: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(site.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(CFDesignTokens.textPrimary)
                        .lineLimit(1)
                    Text(site.domain)
                        .font(.caption2)
                        .foregroundStyle(CFDesignTokens.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous)
                    .fill(isSelected ? CFDesignTokens.accent.opacity(0.12) : (isHovered ? CFDesignTokens.surfaceElevated : Color.clear))
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous)
                        .strokeBorder(CFDesignTokens.accent.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: CFDesignTokens.animationFast), value: isSelected)
    }
}

#Preview {
    MainWindowView()
        .environmentObject(AppViewModel())
}
