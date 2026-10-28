import Foundation

enum CachePurgeMode: String, CaseIterable, Hashable {
    case url = "URL"
    case prefix = "Préfixe"
    case tag = "Tag"
    case host = "Host"
}

enum CachePurgeInput {
    static let maxItemsPerRequest = 30

    /// Tokens séparés par ligne ou virgule.
    static func splitTokens(_ input: String) -> [String] {
        input
            .replacingOccurrences(of: ",", with: "\n")
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func parseURLs(_ input: String, for site: Site) throws -> [String] {
        try URLNormalizer.normalizeMany(input, for: site)
    }

    /// Préfixes = hostname + chemin sans schéma. Accepte aussi un chemin (`/blog/`) → préfixe site.
    static func parsePrefixes(_ input: String, for site: Site) throws -> [String] {
        let siteDomain = URLNormalizer.siteDomain(for: site)
        let tokens = splitTokens(input)
        guard !tokens.isEmpty else { throw CFPurgeError.emptyPurgeInput }
        guard tokens.count <= maxItemsPerRequest else {
            throw CFPurgeError.tooManyURLs(max: maxItemsPerRequest)
        }

        var seen = Set<String>()
        var result: [String] = []
        for token in tokens {
            let prefix = try normalizePrefix(token, siteDomain: siteDomain)
            if seen.insert(prefix).inserted {
                result.append(prefix)
            }
        }
        return result
    }

    static func parseTags(_ input: String) throws -> [String] {
        let tokens = splitTokens(input)
        guard !tokens.isEmpty else { throw CFPurgeError.emptyPurgeInput }
        guard tokens.count <= maxItemsPerRequest else {
            throw CFPurgeError.tooManyURLs(max: maxItemsPerRequest)
        }

        var seen = Set<String>()
        var result: [String] = []
        for token in tokens {
            guard !token.isEmpty else { continue }
            if seen.insert(token).inserted {
                result.append(token)
            }
        }
        guard !result.isEmpty else { throw CFPurgeError.emptyPurgeInput }
        return result
    }

    static func parseHosts(_ input: String, for site: Site) throws -> [String] {
        let siteDomain = URLNormalizer.siteDomain(for: site)
        let tokens = splitTokens(input)
        guard !tokens.isEmpty else { throw CFPurgeError.emptyPurgeInput }
        guard tokens.count <= maxItemsPerRequest else {
            throw CFPurgeError.tooManyURLs(max: maxItemsPerRequest)
        }

        var seen = Set<String>()
        var result: [String] = []
        for token in tokens {
            let host = try normalizeHost(token, siteDomain: siteDomain)
            if seen.insert(host).inserted {
                result.append(host)
            }
        }
        return result
    }

    private static func normalizePrefix(_ input: String, siteDomain: String) throws -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: value), value.hasPrefix("http://") || value.hasPrefix("https://"),
           let host = url.host?.lowercased() {
            guard URLNormalizer.hostMatches(host: host, siteDomain: siteDomain) else {
                throw CFPurgeError.domainMismatch
            }
            let path = url.path
            value = path.isEmpty || path == "/" ? host : "\(host)\(path)"
            if value.hasSuffix("/"), value != host {
                // keep trailing slash if user had path segments — Cloudflare accepts both
            }
            return value
        }

        if value.hasPrefix("/") {
            return "\(siteDomain)\(value)"
        }

        let lower = value.lowercased()
        if lower == siteDomain || lower.hasPrefix("\(siteDomain)/") || lower.hasSuffix(".\(siteDomain)")
            || lower.contains(".\(siteDomain)/") {
            return lower
        }

        // hostname.path without scheme
        if lower.contains("/") {
            let hostPart = String(lower.split(separator: "/", maxSplits: 1)[0])
            guard URLNormalizer.hostMatches(host: hostPart, siteDomain: siteDomain) else {
                throw CFPurgeError.domainMismatch
            }
            return lower
        }

        throw CFPurgeError.invalidPrefix
    }

    private static func normalizeHost(_ input: String, siteDomain: String) throws -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value
            .replacingOccurrences(of: "https://", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "http://", with: "", options: .caseInsensitive)
        if let slash = value.firstIndex(of: "/") {
            value = String(value[..<slash])
        }
        value = value.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !value.isEmpty else { throw CFPurgeError.invalidHost }
        guard URLNormalizer.hostMatches(host: value, siteDomain: siteDomain) else {
            throw CFPurgeError.domainMismatch
        }
        return value
    }
}
