import LexPadCore
import XCTest

final class LanguageDetectionTests: XCTestCase {
    func testPowerShellExtensions() {
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/script.ps1")), .powershell_lang)
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/module.psm1")), .powershell_lang)
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/data.psd1")), .powershell_lang)
    }

    func testCSharpExtension() {
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/Program.cs")), .cs_lang)
    }

    func testCommonExtensions() {
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/app.rb")), .ruby_lang)
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/index.php")), .php_lang)
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/main.kt")), .kotlin_lang)
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/Dockerfile")), .dockerfile_lang)
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/Makefile")), .makefile_lang)
    }

    func testLanguageCountMatchesNotepadPlusPlus() {
        XCTAssertGreaterThanOrEqual(LanguageRegistry.languageCount, 150)
    }

    func testUnknownExtensionIsPlain() {
        XCTAssertEqual(EditorLanguage.detect(from: URL(fileURLWithPath: "/tmp/file.xyz")), .normal_lang)
    }
}
