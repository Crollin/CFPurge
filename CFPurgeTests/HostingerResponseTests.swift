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

    func testDNSUpdatePreservesSiblingRecords() throws {
        let zoneRecords = [
            HostingerDNSZoneRecord(
                name: "@",
                type: "MX",
                ttl: 14400,
                records: [
                    HostingerDNSNameRecord(content: "10 mx1.example.com", isDisabled: false),
                    HostingerDNSNameRecord(content: "20 mx2.example.com", isDisabled: false)
                ]
            )
        ]
        let original = DNSRecord(
            id: "MX|@|10 mx1.example.com",
            type: "MX",
            name: "example.com",
            content: "10 mx1.example.com",
            ttl: 14400,
            proxied: nil,
            proxiable: false
        )

        let request = try HostingerService.makeDNSUpdateRequest(
            zoneRecords: zoneRecords,
            originalRecord: original,
            domain: "example.com",
            type: "MX",
            name: "@",
            content: "5 mx1.example.com",
            ttl: 3600
        )

        XCTAssertTrue(request.overwrite)
        XCTAssertEqual(request.zone.count, 1)
        XCTAssertEqual(request.zone[0].name, "@")
        XCTAssertEqual(request.zone[0].type, "MX")
        XCTAssertEqual(request.zone[0].ttl, 3600)
        XCTAssertEqual(
            request.zone[0].records.map(\.content),
            ["5 mx1.example.com", "20 mx2.example.com"]
        )
    }

    func testDNSUpdateRejectsRenamingAHostingerRecord() throws {
        let zoneRecords = [
            HostingerDNSZoneRecord(
                name: "www",
                type: "A",
                ttl: 14400,
                records: [
                    HostingerDNSNameRecord(content: "192.0.2.1", isDisabled: false)
                ]
            )
        ]
        let original = DNSRecord(
            id: "A|www|192.0.2.1",
            type: "A",
            name: "www.example.com",
            content: "192.0.2.1",
            ttl: 14400,
            proxied: nil,
            proxiable: false
        )

        XCTAssertThrowsError(
            try HostingerService.makeDNSUpdateRequest(
                zoneRecords: zoneRecords,
                originalRecord: original,
                domain: "example.com",
                type: "A",
                name: "api",
                content: "192.0.2.2",
                ttl: 14400
            )
        )
    }

    func testDNSUpdateRejectsDisabledSiblingRecord() throws {
        let zoneRecords = [
            HostingerDNSZoneRecord(
                name: "@",
                type: "MX",
                ttl: 14400,
                records: [
                    HostingerDNSNameRecord(content: "10 mx1.example.com", isDisabled: false),
                    HostingerDNSNameRecord(content: "20 mx2.example.com", isDisabled: true)
                ]
            )
        ]
        let original = DNSRecord(
            id: "MX|@|10 mx1.example.com",
            type: "MX",
            name: "example.com",
            content: "10 mx1.example.com",
            ttl: 14400,
            proxied: nil,
            proxiable: false
        )

        XCTAssertThrowsError(
            try HostingerService.makeDNSUpdateRequest(
                zoneRecords: zoneRecords,
                originalRecord: original,
                domain: "example.com",
                type: "MX",
                name: "@",
                content: "5 mx1.example.com",
                ttl: 14400
            )
        )
    }

    func testDNSUpdateRejectsStaleOriginalContent() throws {
        let zoneRecords = [
            HostingerDNSZoneRecord(
                name: "www",
                type: "A",
                ttl: 14400,
                records: [
                    HostingerDNSNameRecord(content: "192.0.2.2", isDisabled: false)
                ]
            )
        ]
        let staleOriginal = DNSRecord(
            id: "A|www|192.0.2.1",
            type: "A",
            name: "www.example.com",
            content: "192.0.2.1",
            ttl: 14400,
            proxied: nil,
            proxiable: false
        )

        XCTAssertThrowsError(
            try HostingerService.makeDNSUpdateRequest(
                zoneRecords: zoneRecords,
                originalRecord: staleOriginal,
                domain: "example.com",
                type: "A",
                name: "www",
                content: "192.0.2.3",
                ttl: 14400
            )
        )
    }

    @MainActor
    func testReplacingHostingerRecordSynchronizesSiblingTTL() {
        let original = DNSRecord(
            id: "MX|@|10 mx1.example.com",
            type: "MX",
            name: "example.com",
            content: "10 mx1.example.com",
            ttl: 14400,
            proxied: nil,
            proxiable: false
        )
        let sibling = DNSRecord(
            id: "MX|@|20 mx2.example.com",
            type: "MX",
            name: "example.com",
            content: "20 mx2.example.com",
            ttl: 14400,
            proxied: nil,
            proxiable: false
        )
        let updated = DNSRecord(
            id: "MX|@|5 mx1.example.com",
            type: "MX",
            name: "example.com",
            content: "5 mx1.example.com",
            ttl: 3600,
            proxied: nil,
            proxiable: false
        )

        let records = DNSViewModel.replacingHostingerRecord(
            in: [original, sibling],
            recordId: original.id,
            with: updated
        )

        XCTAssertEqual(records.map(\.ttl), [3600, 3600])
        XCTAssertEqual(records.map(\.content), ["5 mx1.example.com", "20 mx2.example.com"])
    }

    func testCDNProviderCapabilities() {
        XCTAssertTrue(CDNProvider.cloudflare.supportsURLPurge)
        XCTAssertFalse(CDNProvider.hostinger.supportsURLPurge)
        XCTAssertFalse(CDNProvider.hostinger.supportsProxiedDNS)
    }
}
