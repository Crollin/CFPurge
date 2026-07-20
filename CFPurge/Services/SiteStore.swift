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
            return try JSONDecoder().decode([Site].self, from: data)
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
    }
}
