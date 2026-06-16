import XCTest
@testable import LexPadCore

final class CompletionEngineTests: XCTestCase {
    func testIncludesKeywordsAndSymbols() {
        let text = "def hello():\n    pass\n"
        let items = CompletionEngine.candidates(
            in: text,
            language: .python_lang,
            userLanguage: nil,
            caretPosition: 0
        )
        XCTAssertTrue(items.contains { $0.label == "hello" && $0.kind == .function })
        XCTAssertTrue(items.contains { $0.label == "def" && $0.kind == .keyword })
    }

    func testUserLanguageKeywords() {
        let udl = UserDefinedLanguage(
            name: "Test",
            extensions: ["tst"],
            keywords: ["widget", "gadget"]
        )
        let items = CompletionEngine.candidates(
            in: "widget",
            language: .normal_lang,
            userLanguage: udl,
            caretPosition: 0,
            prefix: "wid"
        )
        XCTAssertTrue(items.contains { $0.label == "widget" && $0.kind == .keyword })
    }

    func testPrefixAtCaret() {
        XCTAssertEqual(CompletionEngine.prefix(at: 3, in: "foo_bar"), "foo")
    }
}

final class UserLanguageStoreTests: XCTestCase {
    func testSaveAndDetect() throws {
        let lang = UserDefinedLanguage(name: "TestLang", extensions: ["tlang"], keywords: ["alpha"])
        try UserLanguagePersistence.save(lang)
        defer { try? UserLanguagePersistence.delete(id: lang.id) }
        let url = URL(fileURLWithPath: "/tmp/sample.tlang")
        XCTAssertEqual(UserLanguagePersistence.detect(from: url), lang.id)
    }
}
