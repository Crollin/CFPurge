import Foundation

enum URLNormalizer {
    static func normalize(_ input: String, for site: Site) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CFPurgeError.emptyURL
        }

        let siteDomain = site.domain
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            guard let url = URL(string: trimmed),
                  let host = url.host?.lowercased(),
                  hostMatches(host: host, siteDomain: siteDomain) else {
                throw CFPurgeError.domainMismatch
            }
            return trimmed
        }

        let path = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        let normalized = "https://\(siteDomain)\(path)"

        guard URL(string: normalized) != nil else {
            throw CFPurgeError.invalidURL
        }

        return normalized
    }

    private static func hostMatches(host: String, siteDomain: String) -> Bool {
        host == siteDomain || host.hasSuffix(".\(siteDomain)")
    }
}
