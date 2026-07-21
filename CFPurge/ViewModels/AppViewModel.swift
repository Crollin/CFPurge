import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var sites: [Site] = []
    @Published var selectedSite: Site?
    @Published var urlInput: String = ""
    @Published var status: PurgeStatus = .idle
    @Published var tokenInput: String = ""
    @Published var tokenConfigured: Bool = false
    @Published var showingSiteEditor = false
    @Published var editingSite: Site?
    @Published var connectionTestResult: String?
    @Published var launchAtLoginEnabled = LaunchAtLoginService.isEnabled
    @Published var launchAtLoginMessage: String?
    @Published var dnsManagementEnabled: Bool
    @Published var dnsAllowModifyExisting: Bool
    @Published var dnsSite: Site?
    @Published var soundNotificationsEnabled: Bool
    @Published var showURLsInNotifications: Bool

    private let lastSelectedSiteIdKey = "lastSelectedSiteId"
    private let dnsManagementEnabledKey = "dnsManagementEnabled"
    private let dnsAllowModifyExistingKey = "dnsAllowModifyExisting"
    private let soundNotificationsEnabledKey = "soundNotificationsEnabled"
    private let showURLsInNotificationsKey = "showURLsInNotifications"
    private var didScheduleInitialSettingsOpen = false
    private var statusDismissTask: Task<Void, Never>?

    var isLoading: Bool {
        status.isLoading
    }

    var needsSetup: Bool {
        !tokenConfigured || sites.isEmpty
    }

    init() {
        dnsManagementEnabled = UserDefaults.standard.bool(forKey: dnsManagementEnabledKey)
        // Désactivé par défaut : la modification d'enregistrements DNS existants est risquée
        dnsAllowModifyExisting = UserDefaults.standard.bool(forKey: dnsAllowModifyExistingKey)
        if UserDefaults.standard.object(forKey: soundNotificationsEnabledKey) == nil {
            soundNotificationsEnabled = true
        } else {
            soundNotificationsEnabled = UserDefaults.standard.bool(forKey: soundNotificationsEnabledKey)
        }
        // Désactivé par défaut : les URLs ne doivent pas apparaître dans le Centre de notifications
        showURLsInNotifications = UserDefaults.standard.bool(forKey: showURLsInNotificationsKey)
        reloadSites()
        tokenConfigured = KeychainService.loadToken() != nil
        PurgeNotificationService.requestAuthorizationIfNeeded()
    }

    func reloadSites() {
        sites = SiteStore.loadSites()
        restoreSelectedSite()
    }

    func persistSites() {
        do {
            try SiteStore.saveSites(sites)
        } catch {
            setStatus(.error(error.localizedDescription))
        }
    }

    func addSite(_ site: Site) {
        var newSite = site
        newSite.sortOrder = (sites.map(\.sortOrder).max() ?? -1) + 1
        sites.append(newSite)
        sortSites()
        persistSites()
        selectedSite = newSite
        saveLastSelectedSiteId(newSite.id)
    }

    func updateSite(_ site: Site) {
        guard let index = sites.firstIndex(where: { $0.id == site.id }) else { return }
        sites[index] = site
        sortSites()
        persistSites()
        if selectedSite?.id == site.id {
            selectedSite = site
        }
    }

    func deleteSite(_ site: Site) {
        sites.removeAll { $0.id == site.id }
        reindexSortOrders()
        persistSites()
        if selectedSite?.id == site.id {
            selectedSite = sites.first
            if let id = selectedSite?.id {
                saveLastSelectedSiteId(id)
            } else {
                UserDefaults.standard.removeObject(forKey: lastSelectedSiteIdKey)
            }
        }
    }

    func moveSites(from source: IndexSet, to destination: Int) {
        sites.move(fromOffsets: source, toOffset: destination)
        reindexSortOrders()
        persistSites()
    }

    func selectSite(_ site: Site?) {
        selectedSite = site
        if let site {
            saveLastSelectedSiteId(site.id)
        }
    }

    func saveToken() {
        do {
            let token = try SiteValidator.validateAPIToken(tokenInput)
            try KeychainService.saveToken(token)
            tokenConfigured = true
            tokenInput = ""
            connectionTestResult = "Jeton enregistré."
        } catch {
            connectionTestResult = error.localizedDescription
        }
    }

    func deleteToken() {
        KeychainService.deleteToken()
        tokenConfigured = false
        tokenInput = ""
        connectionTestResult = "Jeton supprimé."
    }

    func verifyToken() async {
        guard let token = KeychainService.loadToken() else {
            connectionTestResult = CFPurgeError.missingToken.localizedDescription
            return
        }

        connectionTestResult = "Test en cours…"

        do {
            try await CloudflareService.verifyToken(token: token)
            connectionTestResult = "Connexion réussie."
        } catch {
            connectionTestResult = error.localizedDescription
        }
    }

    func purgeURL() async {
        guard let site = selectedSite else {
            setStatus(.error(CFPurgeError.noSiteSelected.localizedDescription))
            return
        }

        guard let token = KeychainService.loadToken() else {
            setStatus(.error(CFPurgeError.missingToken.localizedDescription))
            return
        }

        setStatus(.loading)

        do {
            let normalizedURL = try URLNormalizer.normalize(urlInput, for: site)
            try await CloudflareService.purgeURLs([normalizedURL], zoneId: site.zoneId, token: token)
            let message = "Cache purgé pour \(normalizedURL)"
            setStatus(.success(message))
            PurgeFeedback.showPurgeSuccess(
                siteName: site.name,
                siteDomain: site.domain,
                detail: message,
                soundEnabled: soundNotificationsEnabled,
                showURLsInNotifications: showURLsInNotifications
            )
        } catch {
            let message = error.localizedDescription
            setStatus(.error(message))
            PurgeFeedback.showPurgeFailure(siteName: site.name, detail: message)
        }
    }

    func purgeEverything() async {
        guard let site = selectedSite else {
            setStatus(.error(CFPurgeError.noSiteSelected.localizedDescription))
            return
        }

        guard let token = KeychainService.loadToken() else {
            setStatus(.error(CFPurgeError.missingToken.localizedDescription))
            return
        }

        setStatus(.loading)

        do {
            try await CloudflareService.purgeEverything(zoneId: site.zoneId, token: token)
            let message = "Tout le cache a été vidé pour \(site.name)"
            setStatus(.success(message))
            PurgeFeedback.showPurgeSuccess(
                siteName: site.name,
                siteDomain: site.domain,
                detail: message,
                soundEnabled: soundNotificationsEnabled,
                showURLsInNotifications: showURLsInNotifications
            )
        } catch {
            let message = error.localizedDescription
            setStatus(.error(message))
            PurgeFeedback.showPurgeFailure(siteName: site.name, detail: message)
        }
    }

    /// Gère les deep links `cfpurge://` (extension Raycast et autres clients).
    func handleOpenURL(_ url: URL) async {
        do {
            let action = try DeepLinkParser.parse(url)
            switch action {
            case .purgeURL(let siteId, let rawURL):
                guard let site = sites.first(where: { $0.id == siteId }) else {
                    setStatus(.error(CFPurgeError.noSiteSelected.localizedDescription))
                    return
                }
                selectedSite = site
                urlInput = rawURL
                await purgeURL()

            case .purgeEverything(let siteId):
                guard let site = sites.first(where: { $0.id == siteId }) else {
                    setStatus(.error(CFPurgeError.noSiteSelected.localizedDescription))
                    return
                }
                selectedSite = site

                let confirmed = ConfirmationAlert.confirm(
                    title: "Vider tout le cache ?",
                    message: "Demande reçue via Raycast pour \(site.name) (\(site.domain)).",
                    confirmTitle: "Vider",
                    isDestructive: true
                )
                guard confirmed else { return }
                await purgeEverything()
            }
        } catch {
            setStatus(.error(error.localizedDescription))
            PurgeFeedback.showPurgeFailure(siteName: "CFPurge", detail: error.localizedDescription)
        }
    }

    func openSettingsIfNeeded(_ present: @escaping () -> Void) {
        guard needsSetup, !didScheduleInitialSettingsOpen else { return }
        didScheduleInitialSettingsOpen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            present()
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginService.setEnabled(enabled)
            launchAtLoginEnabled = LaunchAtLoginService.isEnabled
            launchAtLoginMessage = LaunchAtLoginService.statusMessage
        } catch {
            launchAtLoginMessage = "Impossible de modifier le démarrage automatique : \(error.localizedDescription)"
        }
    }

    func beginAddSite() {
        editingSite = nil
        showingSiteEditor = true
    }

    func beginEditSite(_ site: Site) {
        editingSite = site
        showingSiteEditor = true
    }

    func setDNSManagementEnabled(_ enabled: Bool) {
        dnsManagementEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: dnsManagementEnabledKey)
        if !enabled {
            setDNSAllowModifyExisting(false, skipConfirmation: true)
        }
    }

    /// Active ou désactive la modification des enregistrements DNS existants.
    /// L'activation demande une confirmation explicite (sauf `skipConfirmation`).
    @discardableResult
    func setDNSAllowModifyExisting(_ enabled: Bool, skipConfirmation: Bool = false) -> Bool {
        if enabled && !skipConfirmation {
            let confirmed = ConfirmationAlert.confirm(
                title: "Autoriser la modification DNS ?",
                message: """
                Vous pourrez modifier des enregistrements DNS déjà présents sur Cloudflare.

                Une erreur peut rendre un site inaccessible. Activez uniquement si vous savez ce que vous faites.
                """,
                confirmTitle: "Activer",
                isDestructive: true
            )
            guard confirmed else { return false }
        }

        dnsAllowModifyExisting = enabled
        UserDefaults.standard.set(enabled, forKey: dnsAllowModifyExistingKey)
        return true
    }

    func setSoundNotificationsEnabled(_ enabled: Bool) {
        soundNotificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: soundNotificationsEnabledKey)
    }

    func setShowURLsInNotifications(_ enabled: Bool) {
        showURLsInNotifications = enabled
        UserDefaults.standard.set(enabled, forKey: showURLsInNotificationsKey)
    }

    func openDNS(for site: Site?, openWindow: OpenWindowAction) {
        guard let site else { return }
        dnsSite = site
        DNSWindowPresenter.present(openWindow: openWindow)
    }

    func clearStatus() {
        statusDismissTask?.cancel()
        status = .idle
    }

    private func setStatus(_ newStatus: PurgeStatus) {
        statusDismissTask?.cancel()
        status = newStatus

        switch newStatus {
        case .success:
            statusDismissTask = Task {
                try? await Task.sleep(for: .seconds(6))
                guard !Task.isCancelled else { return }
                if case .success = status {
                    status = .idle
                }
            }
        case .error:
            statusDismissTask = Task {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                if case .error = status {
                    status = .idle
                }
            }
        case .idle, .loading:
            break
        }
    }

    private func sortSites() {
        sites.sort { $0.sortOrder < $1.sortOrder }
    }

    private func reindexSortOrders() {
        for index in sites.indices {
            sites[index].sortOrder = index
        }
    }

    private func restoreSelectedSite() {
        if let savedId = UserDefaults.standard.string(forKey: lastSelectedSiteIdKey),
           let uuid = UUID(uuidString: savedId),
           let site = sites.first(where: { $0.id == uuid }) {
            selectedSite = site
            return
        }
        selectedSite = sites.first
    }

    private func saveLastSelectedSiteId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: lastSelectedSiteIdKey)
    }
}
