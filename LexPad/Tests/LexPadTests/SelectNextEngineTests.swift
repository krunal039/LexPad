import XCTest
@testable import LexPadCore

final class SelectNextEngineTests: XCTestCase {
    func testWordRangeAtCaret() {
        let text = "hello world"
        let range = SelectNextEngine.wordRange(at: 1, in: text)
        XCTAssertEqual(range, NSRange(location: 0, length: 5))
    }

    func testNextOccurrenceWraps() {
        let text = "foo bar foo"
        let first = SelectNextEngine.nextOccurrence(
            of: "foo",
            in: text,
            after: 3,
            matchCase: true,
            wholeWord: true
        )
        XCTAssertEqual(first, NSRange(location: 8, length: 3))

        let wrapped = SelectNextEngine.nextOccurrence(
            of: "foo",
            in: text,
            after: 11,
            matchCase: true,
            wholeWord: true
        )
        XCTAssertEqual(wrapped, NSRange(location: 0, length: 3))
    }

    func testWholeWordSkipsPartial() {
        let text = "foobar foo bar"
        let found = SelectNextEngine.nextOccurrence(
            of: "foo",
            in: text,
            after: 0,
            matchCase: true,
            wholeWord: true
        )
        XCTAssertEqual(found, NSRange(location: 7, length: 3))
    }
}

final class SnippetEngineTests: XCTestCase {
    func testInsertReplacesSelection() {
        let result = SnippetEngine.insert("X", into: "abc", replacing: NSRange(location: 1, length: 1))
        XCTAssertEqual(result.text, "aXc")
        XCTAssertEqual(result.selection, NSRange(location: 1, length: 1))
    }

    func testPlaceholderExpansion() {
        let result = SnippetEngine.insert("${date}", into: "", replacing: NSRange(location: 0, length: 0))
        XCTAssertFalse(result.text.isEmpty)
        XCTAssertEqual(result.text.count, 10)
    }
}
