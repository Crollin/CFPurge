import XCTest
@testable import CFPurge

final class URLNormalizerTests: XCTestCase {
    private let site = Site(
        name: "Test",
        zoneId: "a1b2c3d4e5f6789012345678abcdef01",
        domain: "example.com"
    )

    func testRelativePath() throws {
        let result = try URLNormalizer.normalize("/about", for: site)
        XCTAssertEqual(result, "https://example.com/about")
    }

    func testFullURL() throws {
        let result = try URLNormalizer.normalize("https://example.com/contact", for: site)
        XCTAssertEqual(result, "https://example.com/contact")
    }

    func testDomainMismatch() {
        XCTAssertThrowsError(try URLNormalizer.normalize("https://other.com/page", for: site)) { error in
            XCTAssertEqual(error as? CFPurgeError, .domainMismatch)
        }
    }

    func testEmptyURL() {
        XCTAssertThrowsError(try URLNormalizer.normalize("   ", for: site)) { error in
            XCTAssertEqual(error as? CFPurgeError, .emptyURL)
        }
    }
}
