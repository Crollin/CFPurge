import Foundation

enum SiteValidator {
    private static let zoneIdPattern = #"^[a-fA-F0-9]{32}$"#
    private static let domainPattern = #"^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"#
    static let minimumTokenLength = 40

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

    static func validateAPIToken(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CFPurgeError.missingToken
        }
        // Global API Key Cloudflare = 37 hex chars — rejeter avant le contrôle de longueur
        if trimmed.count == 37, trimmed.range(of: #"^[a-fA-F0-9]{37}$"#, options: .regularExpression) != nil {
            throw CFPurgeError.globalAPIKeyRejected
        }
        guard trimmed.count >= minimumTokenLength else {
            throw CFPurgeError.invalidTokenFormat
        }
        return trimmed
    }

    static func isValidStoredSite(zoneId: String, domain: String) -> Bool {
        (try? validateZoneId(zoneId)) != nil && (try? validateDomain(domain)) != nil
    }
}
