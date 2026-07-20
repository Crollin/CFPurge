import XCTest
@testable import CFPurge

final class UpdaterManagerTests: XCTestCase {
    func testStableReleaseIsNewerThanPrevious() {
        XCTAssertTrue(UpdaterManager.isNewer("1.1.0", than: "1.0.0"))
        XCTAssertFalse(UpdaterManager.isNewer("1.0.0", than: "1.0.0"))
        XCTAssertFalse(UpdaterManager.isNewer("1.0.0", than: "1.1.0"))
    }

    func testPrereleaseOrdering() {
        XCTAssertEqual(
            UpdaterManager.compareVersions("1.0.0", "1.0.0-beta.1"),
            .orderedDescending
        )
        XCTAssertEqual(
            UpdaterManager.compareVersions("1.0.0-beta.1", "1.0.0-alpha.8"),
            .orderedDescending
        )
        XCTAssertEqual(
            UpdaterManager.compareVersions("1.0.0-beta.1", "1.0.0-beta.2"),
            .orderedAscending
        )
    }

    func testPatchComparison() {
        XCTAssertTrue(UpdaterManager.isNewer("1.0.10", than: "1.0.9"))
        XCTAssertFalse(UpdaterManager.isNewer("1.0.9", than: "1.0.10"))
    }

    func testCanonicalInstallPath() {
        XCTAssertEqual(
            UpdaterManager.canonicalInstallURL.path,
            "/Applications/CFPurge.app"
        )
    }

    func testUserInstalledAppIgnoresBuildProducts() {
        XCTAssertTrue(
            UpdaterManager.isUserInstalledApp(
                at: URL(fileURLWithPath: "/Applications/CFPurge.app")
            )
        )
        XCTAssertTrue(
            UpdaterManager.isUserInstalledApp(
                at: URL(fileURLWithPath: "/Users/me/Downloads/CFPurge.app")
            )
        )
        XCTAssertFalse(
            UpdaterManager.isUserInstalledApp(
                at: URL(fileURLWithPath: "/Users/me/Library/Developer/Xcode/DerivedData/CFPurge/Build/Products/Debug/CFPurge.app")
            )
        )
        XCTAssertFalse(
            UpdaterManager.isUserInstalledApp(
                at: URL(fileURLWithPath: "/Users/me/CFPurge/.build/DerivedData/Build/Products/Release/CFPurge.app")
            )
        )
        XCTAssertFalse(
            UpdaterManager.isUserInstalledApp(
                at: URL(fileURLWithPath: "/tmp/CFPurge")
            )
        )
    }
}
