import LexPadCore
import XCTest

final class CommentEngineTests: XCTestCase {
    func testCommentSelectedLines() {
        let text = "line one\nline two\nline three"
        let range = NSRange(location: 0, length: 14) // first two lines
        let result = CommentEngine.toggleLineComments(in: text, language: .python_lang, selectedRange: range)
        XCTAssertEqual(result, "# line one\n# line two\nline three")
    }

    func testUncommentSelectedLines() {
        let text = "# line one\n# line two\nline three"
        let range = NSRange(location: 0, length: 22)
        let result = CommentEngine.toggleLineComments(in: text, language: .python_lang, selectedRange: range)
        XCTAssertEqual(result, "line one\nline two\nline three")
    }

    func testHashLanguage() {
        let prefix = CommentEngine.lineCommentPrefix(for: .ruby_lang)
        XCTAssertEqual(prefix, "# ")
    }
}
