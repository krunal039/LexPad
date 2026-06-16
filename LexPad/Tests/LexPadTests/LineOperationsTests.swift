import LexPadCore
import XCTest

final class LineOperationsTests: XCTestCase {
    func testDuplicateLine() {
        let text = "a\nb\nc"
        XCTAssertEqual(LineOperations.duplicateLine(in: text, line: 2), "a\nb\nb\nc")
    }

    func testSortLines() {
        let text = "c\na\nb"
        XCTAssertEqual(LineOperations.sortLines(in: text, ascending: true, caseInsensitive: false), "a\nb\nc")
    }

    func testRemoveDuplicates() {
        let text = "a\nb\na\nc"
        XCTAssertEqual(LineOperations.removeDuplicateLines(in: text, consecutiveOnly: false), "a\nb\nc")
    }

    func testConvertEOL() {
        let text = "a\nb"
        XCTAssertEqual(LineOperations.convertEndOfLine(in: text, to: .crlf), "a\r\nb")
    }
}
