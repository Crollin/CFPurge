import XCTest
@testable import CFPurge

final class DNSRecordValidatorTests: XCTestCase {
    private let domain = "example.com"

    func testFullRecordNameRoot() {
        XCTAssertEqual(DNSRecordValidator.fullRecordName("@", domain: domain), "example.com")
        XCTAssertEqual(DNSRecordValidator.fullRecordName("", domain: domain), "example.com")
    }

    func testFullRecordNameSubdomain() {
        XCTAssertEqual(DNSRecordValidator.fullRecordName("www", domain: domain), "www.example.com")
    }

    func testFullRecordNameFQDN() {
        XCTAssertEqual(
            DNSRecordValidator.fullRecordName("api.example.com", domain: domain),
            "api.example.com"
        )
    }

    func testValidARecord() throws {
        let request = try DNSRecordValidator.validate(
            type: "A",
            name: "www",
            content: "192.0.2.1",
            domain: domain
        )

        XCTAssertEqual(request.type, "A")
        XCTAssertEqual(request.name, "www.example.com")
        XCTAssertEqual(request.content, "192.0.2.1")
        XCTAssertEqual(request.proxied, false)
    }

    func testInvalidARecord() {
        XCTAssertThrowsError(
            try DNSRecordValidator.validate(type: "A", name: "www", content: "not-an-ip", domain: domain)
        ) { error in
            XCTAssertEqual(
                error as? CFPurgeError,
                .recordValidationFailed("Adresse IPv4 invalide pour un enregistrement A.")
            )
        }
    }

    func testValidCNAMERecord() throws {
        let request = try DNSRecordValidator.validate(
            type: "CNAME",
            name: "blog",
            content: "target.example.org",
            domain: domain
        )

        XCTAssertEqual(request.type, "CNAME")
        XCTAssertEqual(request.name, "blog.example.com")
        XCTAssertEqual(request.content, "target.example.org")
    }

    func testInvalidCNAMERecord() {
        XCTAssertThrowsError(
            try DNSRecordValidator.validate(type: "CNAME", name: "blog", content: "invalid", domain: domain)
        ) { error in
            if case .recordValidationFailed = error as? CFPurgeError {
                // expected
            } else {
                XCTFail("Expected recordValidationFailed")
            }
        }
    }

    func testValidateWithOptionsProxied() throws {
        let request = try DNSRecordValidator.validateWithOptions(
            type: "A",
            name: "@",
            content: "192.0.2.1",
            domain: domain,
            ttl: 3600,
            proxied: true
        )

        XCTAssertEqual(request.ttl, 3600)
        XCTAssertEqual(request.proxied, true)
    }

    func testTXTRecordNoProxied() throws {
        let request = try DNSRecordValidator.validate(
            type: "TXT",
            name: "@",
            content: "v=spf1 include:_spf.example.com ~all",
            domain: domain
        )

        XCTAssertNil(request.proxied)
    }

    func testUnsupportedType() {
        XCTAssertThrowsError(
            try DNSRecordValidator.validate(type: "SRV", name: "_sip", content: "data", domain: domain)
        ) { error in
            XCTAssertEqual(
                error as? CFPurgeError,
                .recordValidationFailed("Type d'enregistrement non supporté.")
            )
        }
    }
}
