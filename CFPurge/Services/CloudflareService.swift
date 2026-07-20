import Foundation

enum CloudflareService {
    private static let baseURL = "https://api.cloudflare.com/client/v4"

    static func verifyToken(token: String) async throws {
        let url = try makeURL(path: "/zones", queryItems: [URLQueryItem(name: "per_page", value: "1")])
        let request = try makeRequest(url: url, token: token, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleResponse(data: data, httpResponse: response) { data in
            let decoded = try JSONDecoder().decode(CloudflareZonesListResponse.self, from: data)
            guard decoded.success else {
                throw mapAPIErrors(decoded.errors)
            }
        }
    }

    static func purgeEverything(zoneId: String, token: String) async throws {
        let url = try makeURL(path: "/zones/\(zoneId)/purge_cache")
        var request = try makeRequest(url: url, token: token, method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["purge_everything": true])
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleResponse(data: data, httpResponse: response) { data in
            let decoded = try JSONDecoder().decode(CloudflarePurgeResponse.self, from: data)
            guard decoded.success else {
                throw mapAPIErrors(decoded.errors)
            }
        }
    }

    static func purgeURLs(_ urls: [String], zoneId: String, token: String) async throws {
        let url = try makeURL(path: "/zones/\(zoneId)/purge_cache")
        var request = try makeRequest(url: url, token: token, method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["files": urls])
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleResponse(data: data, httpResponse: response) { data in
            let decoded = try JSONDecoder().decode(CloudflarePurgeResponse.self, from: data)
            guard decoded.success else {
                throw mapAPIErrors(decoded.errors)
            }
        }
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
        decodeSuccess: (Data) throws -> Void
    ) throws {
        guard let response = httpResponse as? HTTPURLResponse else {
            throw CFPurgeError.networkError("Réponse HTTP invalide.")
        }

        switch response.statusCode {
        case 200...299:
            do {
                try decodeSuccess(data)
            } catch let error as CFPurgeError {
                throw error
            } catch {
                throw CFPurgeError.decodingError
            }
        case 401:
            throw CFPurgeError.unauthorized
        case 404:
            throw CFPurgeError.zoneNotFound
        case 429:
            throw CFPurgeError.rateLimited
        default:
            if let decoded = try? JSONDecoder().decode(CloudflarePurgeResponse.self, from: data) {
                throw mapAPIErrors(decoded.errors)
            }
            if let decoded = try? JSONDecoder().decode(CloudflareZonesListResponse.self, from: data) {
                throw mapAPIErrors(decoded.errors)
            }
            throw CFPurgeError.apiError("Code HTTP \(response.statusCode)")
        }
    }

    private static func mapAPIErrors(_ errors: [CloudflareAPIError]?) -> CFPurgeError {
        guard let errors, let first = errors.first else {
            return CFPurgeError.apiError("Erreur inconnue.")
        }

        let message = first.message.lowercased()
        if first.code == 1008 || message.contains("rate") || message.contains("limit") {
            return .rateLimited
        }

        return .apiError(first.message)
    }
}
