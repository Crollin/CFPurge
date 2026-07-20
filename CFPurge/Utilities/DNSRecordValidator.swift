import Darwin
import Foundation

enum DNSRecordValidator {
    static let supportedTypes = DNSRecordType.allCases.map(\.rawValue)

    static func fullRecordName(_ name: String, domain: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDomain = domain
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if trimmed.isEmpty || trimmed == "@" {
            return normalizedDomain
        }

        let lower = trimmed.lowercased()
        if lower == normalizedDomain || lower.hasSuffix(".\(normalizedDomain)") {
            return lower
        }

        if lower.contains(".") {
            return lower
        }

        return "\(lower).\(normalizedDomain)"
    }

    static func validate(
        type: String,
        name: String,
        content: String,
        domain: String
    ) throws -> CreateDNSRecordRequest {
        let trimmedType = type.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard supportedTypes.contains(trimmedType) else {
            throw CFPurgeError.recordValidationFailed("Type d'enregistrement non supporté.")
        }

        let recordType = DNSRecordType(rawValue: trimmedType)!
        let fullName = fullRecordName(name, domain: domain)

        guard !trimmedContent.isEmpty else {
            throw CFPurgeError.recordValidationFailed("Le contenu est obligatoire.")
        }

        switch recordType {
        case .a:
            guard isValidIPv4(trimmedContent) else {
                throw CFPurgeError.recordValidationFailed("Adresse IPv4 invalide pour un enregistrement A.")
            }
        case .aaaa:
            guard isValidIPv6(trimmedContent) else {
                throw CFPurgeError.recordValidationFailed("Adresse IPv6 invalide pour un enregistrement AAAA.")
            }
        case .cname:
            guard isValidHostname(trimmedContent) else {
                throw CFPurgeError.recordValidationFailed("Nom d'hôte invalide pour un enregistrement CNAME.")
            }
        case .mx:
            guard isValidHostname(trimmedContent) else {
                throw CFPurgeError.recordValidationFailed("Serveur mail invalide pour un enregistrement MX.")
            }
        case .txt:
            break
        }

        return CreateDNSRecordRequest(
            type: trimmedType,
            name: fullName,
            content: trimmedContent,
            ttl: 1,
            proxied: recordType.isProxiable ? false : nil
        )
    }

    static func validateWithOptions(
        type: String,
        name: String,
        content: String,
        domain: String,
        ttl: Int,
        proxied: Bool
    ) throws -> CreateDNSRecordRequest {
        var request = try validate(type: type, name: name, content: content, domain: domain)
        let recordType = DNSRecordType(rawValue: request.type)!

        return CreateDNSRecordRequest(
            type: request.type,
            name: request.name,
            content: request.content,
            ttl: ttl,
            proxied: recordType.isProxiable ? proxied : nil
        )
    }

    private static func isValidIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let number = Int(part), number >= 0, number <= 255 else { return false }
            return true
        }
    }

    private static func isValidIPv6(_ value: String) -> Bool {
        var buffer = in6_addr()
        return value.withCString { inet_pton(AF_INET6, $0, &buffer) == 1 }
    }

    private static func isValidHostname(_ value: String) -> Bool {
        let pattern = #"^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}\.?$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
