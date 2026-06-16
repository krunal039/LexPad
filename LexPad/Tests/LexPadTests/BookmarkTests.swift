import LexPadCore
import XCTest

final class BookmarkTests: XCTestCase {
    func testToggleAndNavigate() {
        var bookmarks: [Bookmark] = []
        XCTAssertTrue(BookmarkStore.toggle(bookmarks: &bookmarks, line: 5))
        XCTAssertTrue(BookmarkStore.toggle(bookmarks: &bookmarks, line: 10))
        XCTAssertEqual(bookmarks.count, 2)
        XCTAssertEqual(BookmarkStore.next(from: 1, in: bookmarks)?.line, 5)
        XCTAssertEqual(BookmarkStore.previous(from: 20, in: bookmarks)?.line, 10)
        XCTAssertFalse(BookmarkStore.toggle(bookmarks: &bookmarks, line: 5))
        XCTAssertEqual(bookmarks.count, 1)
    }
}

final class ReplaceInFilesTests: XCTestCase {
    func testReplaceInTempDirectory() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("lexpad-rif-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let file = dir.appendingPathComponent("sample.txt")
        try "foo bar foo".write(to: file, atomically: true, encoding: .utf8)

        let result = try ReplaceInFilesEngine.replace(
            directory: dir,
            pattern: "foo",
            replacement: "baz",
            options: FindOptions(pattern: "foo")
        )
        XCTAssertEqual(result.filesModified, 1)
        XCTAssertEqual(result.replacements, 2)
        let updated = try String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(updated, "baz bar baz")
    }
}
