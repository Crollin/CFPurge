import Foundation

enum URLNormalizer {
    static let maxURLsPerRequest = 30

    static func normalize(_ input: String, for site: Site) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CFPurgeError.emptyURL
        }

        let siteDomain = siteDomain(for: site)

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

    /// Une entrée par ligne (lignes vides ignorées). Déduplique en préservant l'ordre. Max 30.
    static func normalizeMany(_ input: String, for site: Site) throws -> [String] {
        let lines = input
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw CFPurgeError.emptyURL
        }
        guard lines.count <= maxURLsPerRequest else {
            throw CFPurgeError.tooManyURLs(max: maxURLsPerRequest)
        }

        var seen = Set<String>()
        var result: [String] = []
        for line in lines {
            let normalized = try normalize(line, for: site)
            if seen.insert(normalized).inserted {
                result.append(normalized)
            }
        }
        return result
    }

    static func siteDomain(for site: Site) -> String {
        site.domain
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    static func hostMatches(host: String, siteDomain: String) -> Bool {
        host == siteDomain || host.hasSuffix(".\(siteDomain)")
    }
}
