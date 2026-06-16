import LexPadCore
import XCTest

final class ChangeHistoryEngineTests: XCTestCase {
    func testLinesAffected() {
        let affected = ChangeHistoryEngine.linesAffected(oldText: "a\nb\nc", newText: "a\nB\nc")
        XCTAssertEqual(affected, [2])
    }

    func testCommitSave() {
        var history: [Int: LineChangeState] = [1: .unsaved, 2: .saved]
        ChangeHistoryEngine.commitSave(in: &history)
        XCTAssertEqual(history[1], .saved)
        XCTAssertEqual(history[2], .saved)
    }
}

final class ColumnEditorEngineTests: XCTestCase {
    func testInsertNumbers() {
        let text = "line\nline\nline"
        let range = NSRange(location: 0, length: text.utf16.count)
        let result = ColumnEditorEngine.insertNumbers(in: text, selectedRange: range, start: 10, step: 10, padWidth: 0)
        XCTAssertEqual(result, "line10\nline20\nline30")
    }
}

final class IncrementalSearchEngineTests: XCTestCase {
    func testMatches() {
        let text = "foo bar foo"
        let state = IncrementalSearchState(pattern: "foo", matchCase: false)
        XCTAssertEqual(IncrementalSearchEngine.matches(in: text, state: state).count, 2)
    }
}
