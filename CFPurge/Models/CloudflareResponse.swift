import Foundation

struct CloudflareAPIResponse<T: Decodable>: Decodable {
    let success: Bool
    let errors: [CloudflareAPIError]?
    let messages: [CloudflareAPIMessage]?
    let result: T?
}

struct CloudflareAPIError: Decodable {
    let code: Int
    let message: String
}

struct CloudflareAPIMessage: Decodable {
    let code: Int?
    let message: String?
}

struct CloudflarePurgeResult: Decodable {
    let id: String?
}

struct CloudflareZonesResult: Decodable {
    let zones: [CloudflareZone]?
}

struct CloudflareAccountRef: Decodable {
    let id: String
    let name: String?
}

struct CloudflareZone: Decodable {
    let id: String
    let name: String
    let account: CloudflareAccountRef?
}

struct CloudflareZonesListResponse: Decodable {
    let success: Bool
    let errors: [CloudflareAPIError]?
    let result: [CloudflareZone]?
}

struct CloudflareAccount: Decodable {
    let id: String
    let name: String?
}

struct CloudflareAccountsListResponse: Decodable {
    let success: Bool
    let errors: [CloudflareAPIError]?
    let result: [CloudflareAccount]?
}

struct CloudflarePurgeResponse: Decodable {
    let success: Bool
    let errors: [CloudflareAPIError]?
    let result: CloudflarePurgeResult?
}

struct CloudflareBaseResponse: Decodable {
    let success: Bool
    let errors: [CloudflareAPIError]?
}
