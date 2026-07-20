import Foundation

enum SiteStore {
    private static let appSupportFolder = "CFPurge"
    private static let fileName = "sites.json"

    static var storageURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(appSupportFolder, isDirectory: true)
    }

    static var fileURL: URL {
        storageURL.appendingPathComponent(fileName)
    }

    static func loadSites() -> [Site] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let sites = try JSONDecoder().decode([Site].self, from: data)
            return normalizeSortOrder(sites)
        } catch {
            return []
        }
    }

    static func saveSites(_ sites: [Site]) throws {
        try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(sites)
        try data.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
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
