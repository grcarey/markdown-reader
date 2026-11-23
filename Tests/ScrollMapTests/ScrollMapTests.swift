import XCTest
import ScrollMap

final class ScrollMapTests: XCTestCase {
    let e = [0.0, 100, 300, 400]
    let p = [0.0, 50, 500, 600]

    func testIdentityAtAnchors() {
        for (a, b) in zip(e, p) {
            XCTAssertEqual(mapScroll(a, from: e, to: p), b, accuracy: 1e-9)
            XCTAssertEqual(mapScroll(b, from: p, to: e), a, accuracy: 1e-9)
        }
    }

    func testInterpolatesBetweenAnchors() {
        XCTAssertEqual(mapScroll(200, from: e, to: p), 275, accuracy: 1e-9)
        XCTAssertEqual(mapScroll(25, from: e, to: p), 12.5, accuracy: 1e-9)
    }

    func testClampsBeyondEnds() {
        XCTAssertEqual(mapScroll(-10, from: e, to: p), 0)
        XCTAssertEqual(mapScroll(999, from: e, to: p), 600)
    }

    func testRoundTrip() {
        for y in stride(from: 0.0, through: 400, by: 17) {
            let back = mapScroll(mapScroll(y, from: e, to: p), from: p, to: e)
            XCTAssertEqual(back, y, accuracy: 1e-9)
        }
    }

    func testDropsNonMonotonicPairs() {
        // Second heading goes backwards in the preview, fourth sits past the editor max.
        let b = scrollBreakpoints(editor: [100, 200, 300, 900], preview: [50, 40, 500, 700], editorMax: 400, previewMax: 600)
        XCTAssertEqual(b.editor, [0, 100, 300, 400])
        XCTAssertEqual(b.preview, [0, 50, 500, 600])
    }

    func testNoHeadingsIsProportional() {
        let b = scrollBreakpoints(editor: [], preview: [], editorMax: 400, previewMax: 800)
        XCTAssertEqual(mapScroll(100, from: b.editor, to: b.preview), 200, accuracy: 1e-9)
    }
}
