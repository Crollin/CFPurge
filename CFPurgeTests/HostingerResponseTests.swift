import XCTest
@testable import CFPurge

final class HostingerResponseTests: XCTestCase {
    func testDecodeWebsitesList() throws {
        let json = """
        {
          "data": [
            {
              "domain": "example.com",
              "username": "u123456789",
              "is_enabled": true,
              "website_type": "wordpress",
              "vhost_type": "main"
            }
          ],
          "meta": {
            "current_page": 1,
            "per_page": 25,
            "total": 1,
            "last_page": 1
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(HostingerWebsitesListResponse.self, from: json)
        XCTAssertEqual(decoded.data?.count, 1)
        XCTAssertEqual(decoded.data?.first?.domain, "example.com")
        XCTAssertEqual(decoded.data?.first?.username, "u123456789")
        XCTAssertEqual(decoded.meta?.total, 1)
    }

    func testDecodeDNSZoneRecords() throws {
        let json = """
        [
          {
            "name": "@",
            "type": "A",
            "ttl": 14400,
            "records": [
              { "content": "192.0.2.1", "is_disabled": false }
            ]
          }
        ]
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode([HostingerDNSZoneRecord].self, from: json)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.type, "A")
        XCTAssertEqual(decoded.first?.records?.first?.content, "192.0.2.1")
    }

    func testCDNProviderCapabilities() {
        XCTAssertTrue(CDNProvider.cloudflare.supportsURLPurge)
        XCTAssertFalse(CDNProvider.hostinger.supportsURLPurge)
        XCTAssertFalse(CDNProvider.hostinger.supportsProxiedDNS)
    }
}
