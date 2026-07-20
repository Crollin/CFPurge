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

    func testIsValidStoredSite() {
        XCTAssertTrue(
            SiteValidator.isValidStoredSite(
                zoneId: "a1b2c3d4e5f6789012345678abcdef01",
                domain: "example.com"
            )
        )
        XCTAssertFalse(SiteValidator.isValidStoredSite(zoneId: "bad", domain: "example.com"))
        XCTAssertFalse(
            SiteValidator.isValidStoredSite(
                zoneId: "a1b2c3d4e5f6789012345678abcdef01",
                domain: "com"
            )
        )
    }
}
