import AppKit
import XCTest
@testable import CFPurge

@MainActor
final class CFPurgeMenuBarIconTests: XCTestCase {
    func testMenuBarIconIsRenderableImage() {
        let image = CFPurgeMenuBarIcon.nsImage
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
        XCTAssertFalse(image.isTemplate, "L'icône marque doit rester en couleurs dans la barre de menus")
    }
}
