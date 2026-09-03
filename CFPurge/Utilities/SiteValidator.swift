import Foundation

enum SiteValidator {
    private static let zoneIdPattern = #"^[a-fA-F0-9]{32}$"#
    private static let domainPattern = #"^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"#
    private static let hostingUsernamePattern = #"^[A-Za-z0-9._-]{2,64}$"#
    static let minimumTokenLength = 40
    static let minimumHostingerTokenLength = 20

    static func normalizeDomain(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
    }

    static func validateZoneId(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.range(of: zoneIdPattern, options: .regularExpression) != nil else {
            throw CFPurgeError.invalidZoneId
        }
        return trimmed
    }

    static func validateHostingUsername(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(of: hostingUsernamePattern, options: .regularExpression) != nil else {
            throw CFPurgeError.invalidHostingUsername
        }
        return trimmed
    }

    static func validateDomain(_ input: String) throws -> String {
        let normalized = normalizeDomain(input)
        guard !normalized.isEmpty else {
            throw CFPurgeError.invalidDomain
        }
        guard normalized.range(of: domainPattern, options: .regularExpression) != nil else {
            throw CFPurgeError.invalidDomain
        }
        return normalized
    }

    static func validateSiteName(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CFPurgeError.invalidSiteName
        }
        return trimmed
    }

    static func validateAPIToken(_ input: String, provider: CDNProvider = .cloudflare) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CFPurgeError.missingToken(provider)
        }

        switch provider {
        case .cloudflare:
            // Global API Key Cloudflare = 37 hex chars — rejeter avant le contrôle de longueur
            if trimmed.count == 37, trimmed.range(of: #"^[a-fA-F0-9]{37}$"#, options: .regularExpression) != nil {
                throw CFPurgeError.globalAPIKeyRejected
            }
            guard trimmed.count >= minimumTokenLength else {
                throw CFPurgeError.invalidTokenFormat
            }
        case .hostinger:
            guard trimmed.count >= minimumHostingerTokenLength else {
                throw CFPurgeError.invalidHostingerTokenFormat
            }
        }

        return trimmed
    }

    static func isValidStoredSite(_ site: Site) -> Bool {
        guard (try? validateDomain(site.domain)) != nil,
              (try? validateSiteName(site.name)) != nil else {
            return false
        }

        switch site.provider {
        case .cloudflare:
            return (try? validateZoneId(site.zoneId)) != nil
        case .hostinger:
            guard let username = site.hostingUsername else { return false }
            return (try? validateHostingUsername(username)) != nil
        }
    }

    /// Compatibilité Raycast / anciens appels.
    static func isValidStoredSite(zoneId: String, domain: String) -> Bool {
        isValidStoredSite(Site(name: "tmp", zoneId: zoneId, domain: domain, provider: .cloudflare))
    }
}
