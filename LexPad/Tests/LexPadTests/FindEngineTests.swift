import LexPadCore
import XCTest

final class FindEngineTests: XCTestCase {
    func testLiteralFindAll() throws {
        let text = "alpha beta\nbeta gamma"
        let matches = try FindEngine.findAll(in: text, options: FindOptions(pattern: "beta"))
        XCTAssertEqual(matches.count, 2)
    }

    func testRegexFindAll() throws {
        let text = "error: one\ninfo: two\nerror: three"
        let matches = try FindEngine.findAll(in: text, options: FindOptions(pattern: "error: .*", isRegex: true))
        XCTAssertEqual(matches.count, 2)
    }

    func testReplaceAll() throws {
        let text = "foo bar foo"
        let result = try FindEngine.replaceAll(in: text, options: FindOptions(pattern: "foo"), replacement: "baz")
        XCTAssertEqual(result.text, "baz bar baz")
        XCTAssertEqual(result.count, 2)
    }

    func testLargeFileFindPerformance() throws {
        let line = "2026-06-15 ERROR connection timeout host=server-\(UUID().uuidString)\n"
        let text = String(repeating: line, count: 500_000)
        let bench = FindEngine.benchmarkFind(in: text, pattern: "ERROR.*timeout", isRegex: true)
        XCTAssertGreaterThan(bench.matches, 0)
        XCTAssertLessThan(bench.seconds, 2.0, "Regex find should complete in under 2 seconds")
    }
}

final class DocumentStoreTests: XCTestCase {
    func testEndOfLineDetection() throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("lexpad-eol-test.txt")
        try "a\r\nb\nc".write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let doc = try DocumentStore.load(from: temp)
        XCTAssertEqual(doc.endOfLine, .crlf)
    }
}
