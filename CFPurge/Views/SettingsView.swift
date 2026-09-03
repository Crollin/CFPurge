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
        case updates = "Mises à jour"
        case about = "À propos"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            case .token: return "key.fill"
            case .sites: return "globe"
            case .updates: return "arrow.triangle.2.circlepath"
            case .about: return "info.circle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .general: return CFDesignTokens.iconPurple
            case .token: return CFDesignTokens.iconOrange
            case .sites: return CFDesignTokens.accent
            case .updates: return CFDesignTokens.iconGreen
            case .about: return CFDesignTokens.iconBlue
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar
            Divider().overlay(CFDesignTokens.border)
            settingsContent
        }
        .cfWindowBackground()
        .cfConfigureWindow()
        .preferredColorScheme(.dark)
        .frame(minWidth: 780, minHeight: 560)
        .sheet(isPresented: $viewModel.showingSiteEditor) {
            SiteEditorView(site: viewModel.editingSite)
                .environmentObject(viewModel)
        }
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Réglages")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CFDesignTokens.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases) { tab in
                    CFSidebarItem(
                        title: tab.rawValue,
                        icon: tab.icon,
                        iconColor: tab.iconColor,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: CFDesignTokens.animationNormal)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()
        }
        .frame(width: 200)
        .background(CFDesignTokens.sidebar)
    }

    @ViewBuilder
    private var settingsContent: some View {
        ScrollView {
            Group {
                switch selectedTab {
                case .general:
                    generalSettings
                case .token:
                    tokenSettings
                case .sites:
                    sitesSettings
                case .updates:
                    updatesSettings
                case .about:
                    aboutSettings
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(CFDesignTokens.background)
    }

    // MARK: - Général

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            CFSectionHeader("Fonctionnalités")
            CFCard {
                CFSettingRow(
                    title: "Activer la gestion DNS",
                    subtitle: "Cloudflare : permission Zone > DNS > Edit. Hostinger : jeton API avec accès DNS."
                ) {
                    CFToggle(isOn: Binding(
                        get: { viewModel.dnsManagementEnabled },
                        set: { viewModel.setDNSManagementEnabled($0) }
                    ))
                }

                if viewModel.dnsManagementEnabled {
                    CFSettingRowDivider()
                    CFSettingRow(
                        title: "Autoriser la modification des enregistrements existants",
                        subtitle: "Désactivé par défaut. Une confirmation est demandée à l'activation. Une mauvaise modification DNS peut rendre un site inaccessible."
                    ) {
                        CFToggle(isOn: Binding(
                            get: { viewModel.dnsAllowModifyExisting },
                            set: { viewModel.setDNSAllowModifyExisting($0) }
                        ))
                    }
                }
            }

            CFSectionHeader("Notifications")
            CFCard {
                CFSettingRow(
                    title: "Son des notifications de purge",
                    subtitle: "Joue un son lorsque la purge est terminée."
                ) {
                    CFToggle(isOn: Binding(
                        get: { viewModel.soundNotificationsEnabled },
                        set: { viewModel.setSoundNotificationsEnabled($0) }
                    ))
                }
                CFSettingRowDivider()
                CFSettingRow(
                    title: "Afficher les URLs dans les notifications",
                    subtitle: "Par défaut, les notifications n'affichent que le nom du site."
                ) {
                    CFToggle(isOn: Binding(
                        get: { viewModel.showURLsInNotifications },
                        set: { viewModel.setShowURLsInNotifications($0) }
                    ))
                }
            }

            CFSectionHeader("Démarrage")
            CFCard {
                CFSettingRow(
                    title: "Lancer CFPurge à la connexion",
                    subtitle: LaunchAtLoginService.statusMessage
                ) {
                    CFToggle(isOn: Binding(
                        get: { viewModel.launchAtLoginEnabled },
                        set: { viewModel.setLaunchAtLogin($0) }
                    ))
                }

                if let message = viewModel.launchAtLoginMessage {
                    CFSettingRowDivider()
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - Jeton API

    private var tokenSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            cloudflareTokenSection
            hostingerTokenSection
        }
        .onAppear {
            if viewModel.cloudflareTokenConfigured,
               viewModel.cloudflareAccountId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await viewModel.refreshCloudflareAccountId() }
            }
        }
        .onDisappear {
            viewModel.saveCloudflareAccountId()
        }
    }

    private var cloudflareTokenSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            CFSectionHeader("Compte Cloudflare")
            CFCard {
                VStack(alignment: .leading, spacing: 16) {
                    CFTextFieldLabel(label: "Account ID", text: $viewModel.cloudflareAccountId)

                    HStack(spacing: 8) {
                        CFButton(
                            title: viewModel.accountIdCopyFeedback ?? "Copier",
                            icon: "doc.on.doc",
                            style: .secondary
                        ) {
                            viewModel.copyCloudflareAccountId()
                        }
                        .disabled(viewModel.cloudflareAccountId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if viewModel.cloudflareTokenConfigured {
                            CFButton(title: "Détecter", icon: "arrow.clockwise", style: .secondary) {
                                Task { await viewModel.refreshCloudflareAccountId() }
                            }
                        }
                    }

                    Text("Affiché pour copie rapide (scripts, wrangler, R2…). Détecté automatiquement après un test de connexion réussi.")
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.textTertiary)
                }
                .padding(16)
            }

            CFSectionHeader("Jeton API Cloudflare")
            CFCard {
                VStack(alignment: .leading, spacing: 16) {
                    providerTokenLinkButton(
                        title: "Créer un jeton API sur Cloudflare",
                        action: { viewModel.openCreateAPITokenPage() }
                    )

                    CFTextFieldLabel(label: "Jeton API", text: $viewModel.tokenInput, isSecure: true)

                    HStack(spacing: 8) {
                        CFButton(title: "Enregistrer le jeton", style: .primary) {
                            viewModel.saveToken()
                        }
                        CFButton(title: "Tester la connexion", style: .secondary) {
                            Task { await viewModel.verifyToken() }
                        }
                        .disabled(!viewModel.cloudflareTokenConfigured)

                        if viewModel.cloudflareTokenConfigured {
                            CFButton(title: "Supprimer", style: .destructive) {
                                viewModel.deleteToken()
                            }
                        }
                    }

                    if viewModel.cloudflareTokenConfigured {
                        configuredTokenBadge(label: "Jeton Cloudflare configuré")
                    }

                    if let result = viewModel.connectionTestResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(CFDesignTokens.textSecondary)
                    }
                }
                .padding(16)
            }

            Text("Permissions requises : Zone > Cache Purge > Edit. Ajoutez Zone > DNS > Edit si la gestion DNS est activée. N'utilisez jamais la Global API Key.")
                .font(.caption)
                .foregroundStyle(CFDesignTokens.textSecondary)
        }
    }

    private var hostingerTokenSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            CFSectionHeader("Jeton API Hostinger")
            CFCard {
                VStack(alignment: .leading, spacing: 16) {
                    providerTokenLinkButton(
                        title: "Créer un jeton API sur Hostinger (hPanel)",
                        action: { viewModel.openCreateHostingerAPITokenPage() }
                    )

                    CFTextFieldLabel(label: "Jeton API Hostinger", text: $viewModel.hostingerTokenInput, isSecure: true)

                    HStack(spacing: 8) {
                        CFButton(title: "Enregistrer le jeton", style: .primary) {
                            viewModel.saveHostingerToken()
                        }
                        CFButton(title: "Tester la connexion", style: .secondary) {
                            Task { await viewModel.verifyHostingerToken() }
                        }
                        .disabled(!viewModel.hostingerTokenConfigured)

                        if viewModel.hostingerTokenConfigured {
                            CFButton(title: "Supprimer", style: .destructive) {
                                viewModel.deleteHostingerToken()
                            }
                        }
                    }

                    if viewModel.hostingerTokenConfigured {
                        configuredTokenBadge(label: "Jeton Hostinger configuré")
                    }

                    if let result = viewModel.hostingerConnectionTestResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(CFDesignTokens.textSecondary)
                    }
                }
                .padding(16)
            }

            Text("Générez le jeton dans hPanel → API. La purge Hostinger vide tout le cache serveur (et CDN Hostinger si activé). Pas de purge par URL.")
                .font(.caption)
                .foregroundStyle(CFDesignTokens.textSecondary)
        }
    }

    private func providerTokenLinkButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.body.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CFDesignTokens.textTertiary)
            }
            .foregroundStyle(CFDesignTokens.accent)
            .padding(12)
            .background(CFDesignTokens.surfaceElevated, in: RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CFDesignTokens.radiusButton, style: .continuous)
                    .strokeBorder(CFDesignTokens.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func configuredTokenBadge(label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CFDesignTokens.success)
            Text(label)
                .font(.caption)
                .foregroundStyle(CFDesignTokens.success)
        }
    }

    // MARK: - Sites

    private var sitesSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                CFSectionHeader("Sites")
                Spacer()
                if viewModel.hostingerTokenConfigured {
                    CFButton(title: "Importer Hostinger", icon: "square.and.arrow.down", style: .secondary) {
                        Task { await viewModel.importHostingerWebsites() }
                    }
                }
                CFButton(title: "Ajouter un site", icon: "plus", style: .primary) {
                    viewModel.beginAddSite()
                }
            }

            if let importMessage = viewModel.hostingerImportMessage {
                Text(importMessage)
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textSecondary)
            }

            if viewModel.sites.isEmpty {
                CFCard {
                    VStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.title)
                            .foregroundStyle(CFDesignTokens.textTertiary)
                        Text("Aucun site")
                            .font(.headline)
                            .foregroundStyle(CFDesignTokens.textPrimary)
                        Text("Ajoutez un site Cloudflare ou Hostinger pour commencer.")
                            .font(.caption)
                            .foregroundStyle(CFDesignTokens.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                }
            } else {
                ForEach(viewModel.sites) { site in
                    SiteSettingsCard(
                        site: site,
                        dnsEnabled: viewModel.dnsManagementEnabled,
                        onEdit: { viewModel.beginEditSite(site) },
                        onDNS: { viewModel.openDNS(for: site, openWindow: openWindow) }
                    )
                }

                Text("Glissez-déposez pour définir l'ordre d'affichage dans la barre de menus.")
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textTertiary)
            }
        }
    }

    // MARK: - Mises à jour

    private var updatesSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            CFSectionHeader("Mises à jour")
            CFCard {
                CFSettingRow(
                    title: "Vérifier automatiquement les mises à jour",
                    subtitle: "Recherche de nouvelles versions en arrière-plan."
                ) {
                    CFToggle(isOn: Binding(
                        get: { updater.automaticallyChecksForUpdates },
                        set: { updater.automaticallyChecksForUpdates = $0 }
                    ))
                }
                CFSettingRowDivider()
                CFSettingRow(
                    title: "Version installée",
                    subtitle: updater.currentVersion
                ) {
                    HStack(spacing: 8) {
                        CFButton(title: "Vérifier maintenant", style: .secondary) {
                            updater.checkForUpdates()
                        }
                        .disabled(updater.isChecking || updater.isInstalling)

                        if updater.isChecking {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }

                if updater.updateAvailable, let latestVersion = updater.latestVersion {
                    CFSettingRowDivider()
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(CFDesignTokens.accent)
                            Text("Version \(latestVersion) disponible")
                                .font(.body.weight(.medium))
                                .foregroundStyle(CFDesignTokens.textPrimary)
                        }

                        HStack(spacing: 8) {
                            CFButton(
                                title: updater.isInstalling ? "Installation…" : "Installer la mise à jour",
                                style: .primary
                            ) {
                                updater.installUpdate()
                            }
                            .disabled(updater.isInstalling)

                            CFButton(title: "Voir la release", style: .secondary) {
                                updater.openReleasePage()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if let installError = updater.installError {
                    CFSettingRowDivider()
                    Text(installError)
                        .font(.caption)
                        .foregroundStyle(CFDesignTokens.destructive)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }

            Text("Les mises à jour sont téléchargées depuis GitHub Releases. L'app se ferme brièvement pendant l'installation.")
                .font(.caption)
                .foregroundStyle(CFDesignTokens.textSecondary)
        }
    }

    // MARK: - À propos

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            CFSectionHeader("À propos")
            CFCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        CFPurgeMark(size: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CFPurge")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(CFDesignTokens.textPrimary)
                            Text("Purge de cache Cloudflare & Hostinger pour macOS")
                                .font(.caption)
                                .foregroundStyle(CFDesignTokens.textSecondary)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

// MARK: - Site Card

private struct SiteSettingsCard: View {
    let site: Site
    let dnsEnabled: Bool
    let onEdit: () -> Void
    let onDNS: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(CFDesignTokens.textTertiary)

            CFIconBadge(icon: "globe", color: CFDesignTokens.accent, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(site.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(CFDesignTokens.textPrimary)
                    Text(site.provider.displayName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(CFDesignTokens.textTertiary)
                }
                Text(site.domain)
                    .font(.caption)
                    .foregroundStyle(CFDesignTokens.textSecondary)
                Group {
                    switch site.provider {
                    case .cloudflare:
                        Text("Zone : \(site.zoneId)")
                    case .hostinger:
                        Text("Utilisateur : \(site.hostingUsername ?? "—")")
                    }
                }
                .font(.caption2)
                .foregroundStyle(CFDesignTokens.textTertiary)
                .textSelection(.enabled)
            }

            Spacer()

            HStack(spacing: 8) {
                if dnsEnabled {
                    CFButton(title: "DNS", style: .secondary, action: onDNS)
                }
                CFButton(title: "Modifier", style: .secondary, action: onEdit)
            }
        }
        .padding(14)
        .cfHoverable(isHovered: isHovered)
        .overlay {
            RoundedRectangle(cornerRadius: CFDesignTokens.radiusCard, style: .continuous)
                .strokeBorder(CFDesignTokens.border, lineWidth: 1)
        }
        .onHover { isHovered = $0 }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
        .environmentObject(UpdaterManager())
}
