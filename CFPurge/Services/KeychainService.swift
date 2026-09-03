import Foundation
import Security

enum KeychainService {
    private static let service = "com.creactiveweb.cfpurge"
    private static let cloudflareAccount = "cloudflare-api-token"
    private static let hostingerAccount = "hostinger-api-token"
    private static let accessGroupSuffix = "com.creactiveweb.cfpurge"

    /// Access group `TEAMID.com.creactiveweb.cfpurge` lorsque l'app est signée avec un Team ID.
    /// En signature ad hoc, l'access group est omis (Keychain standard).
    private static var accessGroup: String? {
        guard let teamID = signingTeamID(), !teamID.isEmpty else {
            return nil
        }
        return "\(teamID).\(accessGroupSuffix)"
    }

    private static func signingTeamID() -> String? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else {
            return nil
        }

        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else {
            return nil
        }

        var info: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(staticCode, flags, &info) == errSecSuccess,
              let dict = info as? [String: Any],
              let teamID = dict[kSecCodeInfoTeamIdentifier as String] as? String,
              !teamID.isEmpty else {
            return nil
        }

        return teamID
    }

    // MARK: - Cloudflare (compatibilité API existante)

    static func saveToken(_ token: String) throws {
        try saveToken(token, for: .cloudflare)
    }

    static func loadToken() -> String? {
        loadToken(for: .cloudflare)
    }

    static func deleteToken() {
        deleteToken(for: .cloudflare)
    }

    // MARK: - Provider

    static func saveToken(_ token: String, for provider: CDNProvider) throws {
        let data = Data(token.utf8)
        let query = baseQuery(account: account(for: provider))
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        attributes[kSecAttrSynchronizable as String] = kCFBooleanFalse

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CFPurgeError.networkError("Impossible d'enregistrer le jeton (code \(status)).")
        }
    }

    static func loadToken(for provider: CDNProvider) -> String? {
        var query = baseQuery(account: account(for: provider))
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            return nil
        }

        return token
    }

    static func deleteToken(for provider: CDNProvider) {
        SecItemDelete(baseQuery(account: account(for: provider)) as CFDictionary)
    }

    static func isConfigured(for provider: CDNProvider) -> Bool {
        loadToken(for: provider) != nil
    }

    private static func account(for provider: CDNProvider) -> String {
        switch provider {
        case .cloudflare: return cloudflareAccount
        case .hostinger: return hostingerAccount
        }
    }

    private static func baseQuery(account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
