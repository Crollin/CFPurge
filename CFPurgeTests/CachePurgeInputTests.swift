import XCTest
@testable import CFPurge

final class CachePurgeInputTests: XCTestCase {
    private let site = Site(
        name: "Test",
        zoneId: "a1b2c3d4e5f6789012345678abcdef01",
        domain: "example.com"
    )

    func testParsePrefixesFromPathAndURL() throws {
        let prefixes = try CachePurgeInput.parsePrefixes(
            """
            /blog/
            https://www.example.com/images
            """,
            for: site
        )
        XCTAssertEqual(prefixes, [
            "example.com/blog/",
            "www.example.com/images"
        ])
    }

    func testParseTagsCommaAndLines() throws {
        let tags = try CachePurgeInput.parseTags("post-1, post-2\nproduct-images")
        XCTAssertEqual(tags, ["post-1", "post-2", "product-images"])
    }

    func testParseHosts() throws {
        let hosts = try CachePurgeInput.parseHosts("www.example.com, example.com", for: site)
        XCTAssertEqual(hosts, ["www.example.com", "example.com"])
    }

    func testParseHostsRejectsForeign() {
        XCTAssertThrowsError(try CachePurgeInput.parseHosts("evil.com", for: site)) { error in
            XCTAssertEqual(error as? CFPurgeError, .domainMismatch)
        }
    }

    func testParseEmpty() {
        XCTAssertThrowsError(try CachePurgeInput.parseTags("  \n ")) { error in
            XCTAssertEqual(error as? CFPurgeError, .emptyPurgeInput)
        }
    }
}
