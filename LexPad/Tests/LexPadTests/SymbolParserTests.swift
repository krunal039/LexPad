import LexPadCore
import XCTest

final class SymbolParserTests: XCTestCase {
    func testPythonFunctionsAndClasses() {
        let text = """
        def hello():
            pass

        class Widget:
            pass
        """
        let symbols = SymbolParser.parse(in: text, language: .python_lang)
        XCTAssertEqual(symbols.count, 2)
        XCTAssertEqual(symbols.first(where: { $0.name == "hello" })?.kind, .function)
        XCTAssertEqual(symbols.first(where: { $0.name == "hello" })?.line, 1)
        XCTAssertEqual(symbols.first(where: { $0.name == "Widget" })?.kind, .class)
        XCTAssertEqual(symbols.first(where: { $0.name == "Widget" })?.line, 4)
    }

    func testJavaScriptFunctions() {
        let text = """
        function main() {}
        export class App {}
        """
        let symbols = SymbolParser.parse(in: text, language: .javascript_js)
        XCTAssertNotNil(symbols.first(where: { $0.name == "main" }))
        XCTAssertNotNil(symbols.first(where: { $0.name == "App" }))
    }

    func testSkipsComments() {
        let text = """
        // function fake() {}
        def real():
            pass
        """
        let symbols = SymbolParser.parse(in: text, language: .python_lang)
        XCTAssertEqual(symbols.count, 1)
        XCTAssertEqual(symbols[0].name, "real")
    }
}
