import LexPadCore
import XCTest

final class SyntextTests: XCTestCase {
    func testDetectSyntextExtension() {
        let url = URL(fileURLWithPath: "/tmp/example.syntext")
        XCTAssertEqual(EditorLanguage.detect(from: url), .syntext_lang)
    }

    func testDetectStxExtension() {
        let url = URL(fileURLWithPath: "/tmp/example.stx")
        XCTAssertEqual(EditorLanguage.detect(from: url), .syntext_lang)
    }
}
