import Foundation
import LexPadCore
import XCTest

final class ExtendedFindTests: XCTestCase {
    func testExpandNewlineTab() {
        XCTAssertEqual(ExtendedFind.expandPattern("a\\nb\\t"), "a\nb\t")
    }

    func testFindWithExtendedMode() throws {
        let text = "hello\nworld"
        let options = FindOptions(pattern: "\\n", isExtended: true)
        let matches = try FindEngine.findAll(in: text, options: options)
        XCTAssertEqual(matches.count, 1)
    }
}

final class SplitLineTests: XCTestCase {
    func testSplitAtColumn() {
        let text = "abcdef"
        let result = LineOperations.splitLine(in: text, line: 1, column: 4)
        XCTAssertEqual(result, "abc\ndef")
    }
}
