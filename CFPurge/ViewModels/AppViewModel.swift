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
    @Published var shouldOpenSettings = false
    @Published var launchAtLoginEnabled = LaunchAtLoginService.isEnabled
    @Published var launchAtLoginMessage: String?

    private let lastSelectedSiteIdKey = "lastSelectedSiteId"

    var isLoading: Bool {
        status.isLoading
    }

    var needsSetup: Bool {
        !tokenConfigured || sites.isEmpty
    }

    init() {
        reloadSites()
        tokenConfigured = KeychainService.loadToken() != nil
    }

    func reloadSites() {
        sites = SiteStore.loadSites()
        restoreSelectedSite()
    }

    func persistSites() {
        do {
            try SiteStore.saveSites(sites)
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func addSite(_ site: Site) {
        sites.append(site)
        persistSites()
        selectedSite = site
        saveLastSelectedSiteId(site.id)
    }

    func updateSite(_ site: Site) {
        guard let index = sites.firstIndex(where: { $0.id == site.id }) else { return }
        sites[index] = site
        persistSites()
        if selectedSite?.id == site.id {
            selectedSite = site
        }
    }

    func deleteSite(_ site: Site) {
        sites.removeAll { $0.id == site.id }
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

    func selectSite(_ site: Site?) {
        selectedSite = site
        if let site {
            saveLastSelectedSiteId(site.id)
        }
    }

    func saveToken() {
        let token = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            connectionTestResult = CFPurgeError.missingToken.localizedDescription
            return
        }

        do {
            try KeychainService.saveToken(token)
            tokenConfigured = true
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
            status = .error(CFPurgeError.noSiteSelected.localizedDescription ?? "")
            return
        }

        guard let token = KeychainService.loadToken() else {
            status = .error(CFPurgeError.missingToken.localizedDescription ?? "")
            return
        }

        status = .loading

        do {
            let normalizedURL = try URLNormalizer.normalize(urlInput, for: site)
            try await CloudflareService.purgeURLs([normalizedURL], zoneId: site.zoneId, token: token)
            status = .success("Cache purgé pour \(normalizedURL)")
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func purgeEverything() async {
        guard let site = selectedSite else {
            status = .error(CFPurgeError.noSiteSelected.localizedDescription ?? "")
            return
        }

        guard let token = KeychainService.loadToken() else {
            status = .error(CFPurgeError.missingToken.localizedDescription ?? "")
            return
        }

        status = .loading

        do {
            try await CloudflareService.purgeEverything(zoneId: site.zoneId, token: token)
            status = .success("Tout le cache a été vidé pour \(site.name)")
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func openSettings() {
        shouldOpenSettings = true
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
