import XCTest
@testable import CFPurge

final class SiteValidatorTests: XCTestCase {
    func testValidZoneId() throws {
        let zoneId = try SiteValidator.validateZoneId("a1b2c3d4e5f6789012345678abcdef01")
        XCTAssertEqual(zoneId, "a1b2c3d4e5f6789012345678abcdef01")
    }

    func testZoneIdNormalizedToLowercase() throws {
        let zoneId = try SiteValidator.validateZoneId("A1B2C3D4E5F6789012345678ABCDEF01")
        XCTAssertEqual(zoneId, "a1b2c3d4e5f6789012345678abcdef01")
    }

    func testInvalidZoneIdTooShort() {
        XCTAssertThrowsError(try SiteValidator.validateZoneId("abc123")) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidZoneId)
        }
    }

    func testInvalidZoneIdNonHex() {
        XCTAssertThrowsError(try SiteValidator.validateZoneId("zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz")) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidZoneId)
        }
    }

    func testValidDomain() throws {
        XCTAssertEqual(try SiteValidator.validateDomain("Example.COM"), "example.com")
        XCTAssertEqual(try SiteValidator.validateDomain("https://blog.example.com/"), "blog.example.com")
    }

    func testInvalidDomainSingleLabel() {
        XCTAssertThrowsError(try SiteValidator.validateDomain("com")) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidDomain)
        }
    }

    func testInvalidDomainEmpty() {
        XCTAssertThrowsError(try SiteValidator.validateDomain("   ")) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidDomain)
        }
    }

    func testTokenMinimumLength() {
        XCTAssertThrowsError(try SiteValidator.validateAPIToken(String(repeating: "a", count: 39))) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidTokenFormat)
        }
        XCTAssertNoThrow(try SiteValidator.validateAPIToken(String(repeating: "a", count: 40)))
    }

    func testRejectGlobalAPIKey() {
        let globalKey = String(repeating: "a", count: 37)
        XCTAssertThrowsError(try SiteValidator.validateAPIToken(globalKey)) { error in
            XCTAssertEqual(error as? CFPurgeError, .globalAPIKeyRejected)
        }
    }

    func testHostingerTokenMinimumLength() {
        XCTAssertThrowsError(
            try SiteValidator.validateAPIToken(String(repeating: "a", count: 19), provider: .hostinger)
        ) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidHostingerTokenFormat)
        }
        XCTAssertNoThrow(
            try SiteValidator.validateAPIToken(String(repeating: "a", count: 20), provider: .hostinger)
        )
    }

    func testValidHostingUsername() throws {
        XCTAssertEqual(try SiteValidator.validateHostingUsername("u123456789"), "u123456789")
    }

    func testInvalidHostingUsername() {
        XCTAssertThrowsError(try SiteValidator.validateHostingUsername("a")) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidHostingUsername)
        }
    }

    func testIsValidStoredSiteCloudflare() {
        XCTAssertTrue(
            SiteValidator.isValidStoredSite(
                Site(
                    name: "Demo",
                    zoneId: "a1b2c3d4e5f6789012345678abcdef01",
                    domain: "example.com",
                    provider: .cloudflare
                )
            )
        )
        XCTAssertFalse(
            SiteValidator.isValidStoredSite(
                Site(name: "Demo", zoneId: "bad", domain: "example.com", provider: .cloudflare)
            )
        )
    }

    func testIsValidStoredSiteHostinger() {
        XCTAssertTrue(
            SiteValidator.isValidStoredSite(
                Site(
                    name: "WP",
                    zoneId: "",
                    domain: "monsite.com",
                    provider: .hostinger,
                    hostingUsername: "u123456789"
                )
            )
        )
        XCTAssertFalse(
            SiteValidator.isValidStoredSite(
                Site(
                    name: "WP",
                    zoneId: "",
                    domain: "monsite.com",
                    provider: .hostinger,
                    hostingUsername: nil
                )
            )
        )
    }

    func testSiteDecodingDefaultsProviderToCloudflare() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "name": "Legacy",
          "zoneId": "a1b2c3d4e5f6789012345678abcdef01",
          "domain": "example.com",
          "sortOrder": 0
        }
        """.data(using: .utf8)!

        let site = try JSONDecoder().decode(Site.self, from: json)
        XCTAssertEqual(site.provider, .cloudflare)
        XCTAssertNil(site.hostingUsername)
    }
}
