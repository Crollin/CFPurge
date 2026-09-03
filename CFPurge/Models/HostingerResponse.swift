import Foundation

struct HostingerWebsite: Decodable, Identifiable, Equatable {
    let domain: String?
    let username: String?
    let isEnabled: Bool?
    let websiteType: String?
    let vhostType: String?
    let parentDomain: String?

    var id: String {
        "\(username ?? "")|\(domain ?? "")"
    }

    enum CodingKeys: String, CodingKey {
        case domain, username
        case isEnabled = "is_enabled"
        case websiteType = "website_type"
        case vhostType = "vhost_type"
        case parentDomain = "parent_domain"
    }

    var displayName: String {
        domain ?? parentDomain ?? "Site Hostinger"
    }
}

struct HostingerWebsitesListResponse: Decodable {
    let data: [HostingerWebsite]?
    let meta: HostingerPaginationMeta?
}

struct HostingerPaginationMeta: Decodable {
    let currentPage: Int?
    let perPage: Int?
    let total: Int?
    let lastPage: Int?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case perPage = "per_page"
        case total
        case lastPage = "last_page"
    }
}

struct HostingerAPIErrorBody: Decodable {
    let message: String?
    let error: String?
    let errors: [String: [String]]?
}

struct HostingerDNSZoneRecord: Decodable {
    let name: String?
    let type: String?
    let ttl: Int?
    let records: [HostingerDNSNameRecord]?
}

struct HostingerDNSNameRecord: Decodable {
    let content: String?
    let isDisabled: Bool?

    enum CodingKeys: String, CodingKey {
        case content
        case isDisabled = "is_disabled"
    }
}

struct HostingerDNSUpdateRequest: Encodable {
    let overwrite: Bool
    let zone: [HostingerDNSUpdateZoneEntry]
}

struct HostingerDNSUpdateZoneEntry: Encodable {
    let name: String
    let type: String
    let ttl: Int?
    let records: [HostingerDNSUpdateContent]
}

struct HostingerDNSUpdateContent: Encodable {
    let content: String
}
