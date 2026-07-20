import Foundation

struct DNSRecord: Identifiable, Decodable, Equatable {
    let id: String
    let type: String
    let name: String
    let content: String
    let ttl: Int
    let proxied: Bool?
    let proxiable: Bool?
}

struct CloudflareResultInfo: Decodable {
    let page: Int?
    let perPage: Int?
    let totalPages: Int?
    let count: Int?
    let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalPages = "total_pages"
        case count
        case totalCount = "total_count"
    }
}

struct CloudflareDNSListResponse: Decodable {
    let success: Bool
    let errors: [CloudflareAPIError]?
    let result: [DNSRecord]?
    let resultInfo: CloudflareResultInfo?

    enum CodingKeys: String, CodingKey {
        case success, errors, result
        case resultInfo = "result_info"
    }
}

struct CloudflareDNSCreateResponse: Decodable {
    let success: Bool
    let errors: [CloudflareAPIError]?
    let result: DNSRecord?
}

struct CreateDNSRecordRequest: Encodable {
    let type: String
    let name: String
    let content: String
    let ttl: Int
    let proxied: Bool?
}

enum DNSRecordType: String, CaseIterable, Identifiable {
    case a = "A"
    case aaaa = "AAAA"
    case cname = "CNAME"
    case mx = "MX"
    case txt = "TXT"

    var id: String { rawValue }

    var isProxiable: Bool {
        switch self {
        case .a, .aaaa, .cname:
            return true
        case .mx, .txt:
            return false
        }
    }
}

enum DNSStatus: Equatable {
    case idle
    case loading
    case success(String)
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var message: String? {
        switch self {
        case .success(let message), .error(let message):
            return message
        case .idle, .loading:
            return nil
        }
    }
}
