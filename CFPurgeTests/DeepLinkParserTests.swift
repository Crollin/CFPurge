import XCTest
@testable import CFPurge

final class DeepLinkParserTests: XCTestCase {
    private let siteId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    func testParsePurgeURL() throws {
        let url = URL(string: "cfpurge://purge?siteId=\(siteId.uuidString)&url=https%3A%2F%2Fexample.com%2Fpage")!
        let action = try DeepLinkParser.parse(url)
        XCTAssertEqual(action, .purgeURL(siteId: siteId, url: "https://example.com/page"))
    }

    func testParsePurgeAll() throws {
        let url = URL(string: "cfpurge://purge-all?siteId=\(siteId.uuidString)")!
        let action = try DeepLinkParser.parse(url)
        XCTAssertEqual(action, .purgeEverything(siteId: siteId))
    }

    func testRejectUnknownHost() {
        let url = URL(string: "cfpurge://unknown?siteId=\(siteId.uuidString)")!
        XCTAssertThrowsError(try DeepLinkParser.parse(url)) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidDeepLink)
        }
    }

    func testRejectMissingSiteId() {
        let url = URL(string: "cfpurge://purge?url=https://example.com")!
        XCTAssertThrowsError(try DeepLinkParser.parse(url)) { error in
            XCTAssertEqual(error as? CFPurgeError, .invalidDeepLink)
        }
    }

    func testMakeURLsRoundTrip() throws {
        let purge = DeepLinkParser.makePurgeURL(siteId: siteId, url: "https://example.com/a")
        XCTAssertEqual(try DeepLinkParser.parse(purge), .purgeURL(siteId: siteId, url: "https://example.com/a"))

        let purgeAll = DeepLinkParser.makePurgeAllURL(siteId: siteId)
        XCTAssertEqual(try DeepLinkParser.parse(purgeAll), .purgeEverything(siteId: siteId))
    }
}
