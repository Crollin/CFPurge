import Foundation

enum SiteStore {
    private static let appSupportFolder = "CFPurge"
    private static let fileName = "sites.json"
    private static let legacyMigrationFlagKey = "didMigrateSitesFromLegacyPath"

    /// Chemin partagé avec l'extension Raycast.
    /// En sandbox, on force `~/Library/Application Support/CFPurge` (exception entitlements)
    /// pour que Raycast puisse toujours lire la liste des sites.
    static var storageURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(appSupportFolder, isDirectory: true)
    }

    static var fileURL: URL {
        storageURL.appendingPathComponent(fileName)
    }

    /// Ancien chemin éventuel dans le container sandbox (migration one-shot).
    private static var containerFileURL: URL? {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        guard base.path.contains("/Containers/") else { return nil }
        return base
            .appendingPathComponent(appSupportFolder, isDirectory: true)
            .appendingPathComponent(fileName)
    }

    static func loadSites() -> [Site] {
        migrateFromContainerIfNeeded()
        enforcePermissions()

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Site].self, from: data)
            let valid = decoded.filter {
                SiteValidator.isValidStoredSite(zoneId: $0.zoneId, domain: $0.domain)
            }
            return normalizeSortOrder(valid)
        } catch {
            return []
        }
    }

    static func saveSites(_ sites: [Site]) throws {
        try FileManager.default.createDirectory(
            at: storageURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(sites)
        try data.write(to: fileURL, options: .atomic)
        enforcePermissions()
    }

    private static func enforcePermissions() {
        let fm = FileManager.default
        if fm.fileExists(atPath: storageURL.path) {
            try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: storageURL.path)
        }
        if fm.fileExists(atPath: fileURL.path) {
            try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        }
    }

    /// Copie one-shot depuis le container sandbox vers le chemin classique partagé.
    private static func migrateFromContainerIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: legacyMigrationFlagKey) else { return }
        defer { UserDefaults.standard.set(true, forKey: legacyMigrationFlagKey) }

        guard let containerFile = containerFileURL else { return }
        let fm = FileManager.default

        guard fm.fileExists(atPath: containerFile.path) else { return }
        guard !fm.fileExists(atPath: fileURL.path) else { return }

        do {
            try fm.createDirectory(
                at: storageURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try fm.copyItem(at: containerFile, to: fileURL)
            enforcePermissions()
        } catch {
            // Migration best-effort
        }
    }

    private static func normalizeSortOrder(_ sites: [Site]) -> [Site] {
        var sorted = sites.sorted {
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        for index in sorted.indices {
            sorted[index].sortOrder = index
        }

        return sorted
    }
}
