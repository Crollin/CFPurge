import Foundation

enum HostingerService {
    private static let baseURL = "https://developers.hostinger.com"
    private static let websitesPerPage = 100

    static let createAPITokenURL = URL(string: "https://hpanel.hostinger.com/api")!

    /// Vérifie le jeton en listant les sites (endpoint léger et authentifié).
    @discardableResult
    static func verifyToken(token: String) async throws -> Int {
        let url = try makeURL(
            path: "/api/hosting/v1/websites",
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "per_page", value: "1")
            ]
        )
        let request = try makeRequest(url: url, token: token, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        var listResponse: HostingerWebsitesListResponse?
        try handleResponse(data: data, httpResponse: response) { data in
            listResponse = try JSONDecoder().decode(HostingerWebsitesListResponse.self, from: data)
        }

        return listResponse?.meta?.total ?? listResponse?.data?.count ?? 0
    }

    static func listWebsites(token: String, page: Int = 1, perPage: Int = websitesPerPage) async throws -> [HostingerWebsite] {
        var all: [HostingerWebsite] = []
        var currentPage = page
        var lastPage = page

        repeat {
            let url = try makeURL(
                path: "/api/hosting/v1/websites",
                queryItems: [
                    URLQueryItem(name: "page", value: String(currentPage)),
                    URLQueryItem(name: "per_page", value: String(perPage))
                ]
            )
            let request = try makeRequest(url: url, token: token, method: "GET")
            let (data, response) = try await URLSession.shared.data(for: request)

            var listResponse: HostingerWebsitesListResponse?
            try handleResponse(data: data, httpResponse: response) { data in
                listResponse = try JSONDecoder().decode(HostingerWebsitesListResponse.self, from: data)
            }

            let pageItems = listResponse?.data ?? []
            all.append(contentsOf: pageItems)
            lastPage = listResponse?.meta?.lastPage ?? currentPage
            currentPage += 1
        } while currentPage <= lastPage

        return all.filter { website in
            guard let domain = website.domain, !domain.isEmpty else { return false }
            guard let username = website.username, !username.isEmpty else { return false }
            return website.isEnabled != false
        }
    }

    static func purgeEverything(username: String, domain: String, token: String) async throws {
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? domain
        let url = try makeURL(path: "/api/hosting/v1/accounts/\(encodedUsername)/websites/\(encodedDomain)/cache/clear")
        let request = try makeRequest(url: url, token: token, method: "DELETE")
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleResponse(data: data, httpResponse: response) { _ in }
    }

    static func listDNSRecords(domain: String, token: String) async throws -> [DNSRecord] {
        let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? domain
        let url = try makeURL(path: "/api/dns/v1/zones/\(encodedDomain)")
        let request = try makeRequest(url: url, token: token, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        var zoneRecords: [HostingerDNSZoneRecord] = []
        try handleResponse(data: data, httpResponse: response, isDNSOperation: true) { data in
            zoneRecords = try JSONDecoder().decode([HostingerDNSZoneRecord].self, from: data)
        }

        return flattenDNSRecords(zoneRecords, domain: domain)
    }

    static func createDNSRecord(
        domain: String,
        token: String,
        type: String,
        name: String,
        content: String,
        ttl: Int
    ) async throws -> DNSRecord {
        let relativeName = relativeDNSName(name, domain: domain)
        let effectiveTTL = ttl <= 1 ? 14400 : ttl
        let body = HostingerDNSUpdateRequest(
            overwrite: false,
            zone: [
                HostingerDNSUpdateZoneEntry(
                    name: relativeName,
                    type: type.uppercased(),
                    ttl: effectiveTTL,
                    records: [HostingerDNSUpdateContent(content: content)]
                )
            ]
        )

        try await updateDNSZone(domain: domain, token: token, body: body)
        return DNSRecord(
            id: syntheticDNSRecordId(type: type, name: relativeName, content: content),
            type: type.uppercased(),
            name: absoluteDNSName(relativeName, domain: domain),
            content: content,
            ttl: effectiveTTL,
            proxied: nil,
            proxiable: false
        )
    }

    static func updateDNSRecord(
        domain: String,
        token: String,
        type: String,
        name: String,
        content: String,
        ttl: Int
    ) async throws -> DNSRecord {
        let relativeName = relativeDNSName(name, domain: domain)
        let effectiveTTL = ttl <= 1 ? 14400 : ttl
        let body = HostingerDNSUpdateRequest(
            overwrite: true,
            zone: [
                HostingerDNSUpdateZoneEntry(
                    name: relativeName,
                    type: type.uppercased(),
                    ttl: effectiveTTL,
                    records: [HostingerDNSUpdateContent(content: content)]
                )
            ]
        )

        try await updateDNSZone(domain: domain, token: token, body: body)
        return DNSRecord(
            id: syntheticDNSRecordId(type: type, name: relativeName, content: content),
            type: type.uppercased(),
            name: absoluteDNSName(relativeName, domain: domain),
            content: content,
            ttl: effectiveTTL,
            proxied: nil,
            proxiable: false
        )
    }

    private static func updateDNSZone(domain: String, token: String, body: HostingerDNSUpdateRequest) async throws {
        let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? domain
        let url = try makeURL(path: "/api/dns/v1/zones/\(encodedDomain)")
        var request = try makeRequest(url: url, token: token, method: "PUT")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleResponse(data: data, httpResponse: response, isDNSOperation: true) { _ in }
    }

    private static func flattenDNSRecords(_ zoneRecords: [HostingerDNSZoneRecord], domain: String) -> [DNSRecord] {
        var result: [DNSRecord] = []

        for zone in zoneRecords {
            guard let type = zone.type?.uppercased(), !type.isEmpty else { continue }
            let name = zone.name ?? "@"
            let ttl = zone.ttl ?? 14400
            let contents = (zone.records ?? []).compactMap { record -> String? in
                guard record.isDisabled != true else { return nil }
                guard let content = record.content, !content.isEmpty else { return nil }
                return content
            }

            for content in contents {
                result.append(
                    DNSRecord(
                        id: syntheticDNSRecordId(type: type, name: name, content: content),
                        type: type,
                        name: absoluteDNSName(name, domain: domain),
                        content: content,
                        ttl: ttl,
                        proxied: nil,
                        proxiable: false
                    )
                )
            }
        }

        return result.sorted {
            if $0.type != $1.type { return $0.type < $1.type }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private static func syntheticDNSRecordId(type: String, name: String, content: String) -> String {
        "\(type.uppercased())|\(name.lowercased())|\(content)"
    }

    private static func relativeDNSName(_ name: String, domain: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let domainLower = domain.lowercased()

        if trimmed.isEmpty || trimmed == "@" || trimmed == domainLower {
            return "@"
        }

        let suffix = ".\(domainLower)"
        if trimmed.hasSuffix(suffix) {
            let relative = String(trimmed.dropLast(suffix.count))
            return relative.isEmpty ? "@" : relative
        }

        return trimmed
    }

    private static func absoluteDNSName(_ name: String, domain: String) -> String {
        let relative = relativeDNSName(name, domain: domain)
        if relative == "@" {
            return domain.lowercased()
        }
        return "\(relative).\(domain.lowercased())"
    }

    private static func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw CFPurgeError.invalidURL
        }
        return url
    }

    private static func makeRequest(url: URL, token: String, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private static func handleResponse(
        data: Data,
        httpResponse: URLResponse,
        isDNSOperation: Bool = false,
        decodeSuccess: (Data) throws -> Void
    ) throws {
        guard let response = httpResponse as? HTTPURLResponse else {
            throw CFPurgeError.networkError("Réponse HTTP invalide.")
        }

        switch response.statusCode {
        case 200...299:
            // Certaines réponses Hostinger (DELETE) sont vides.
            if data.isEmpty {
                return
            }
            do {
                try decodeSuccess(data)
            } catch let error as CFPurgeError {
                throw error
            } catch {
                // Succès HTTP sans corps décodable utile (ex. objet vide).
                if data.count <= 2 {
                    return
                }
                throw CFPurgeError.decodingError
            }
        case 401:
            throw CFPurgeError.unauthorized
        case 403:
            throw isDNSOperation
                ? CFPurgeError.dnsPermissionDenied
                : CFPurgeError.apiError("Accès Hostinger refusé.")
        case 404:
            throw CFPurgeError.zoneNotFound
        case 429:
            throw CFPurgeError.rateLimited
        default:
            if let body = try? JSONDecoder().decode(HostingerAPIErrorBody.self, from: data) {
                let message = body.message ?? body.error ?? firstValidationError(body.errors) ?? "Code HTTP \(response.statusCode)"
                throw CFPurgeError.apiError(message)
            }
            throw CFPurgeError.apiError("Code HTTP \(response.statusCode)")
        }
    }

    private static func firstValidationError(_ errors: [String: [String]]?) -> String? {
        guard let errors else { return nil }
        for (_, messages) in errors {
            if let first = messages.first, !first.isEmpty {
                return first
            }
        }
        return nil
    }
}
