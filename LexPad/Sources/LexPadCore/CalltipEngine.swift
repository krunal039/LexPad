import Foundation

public struct CalltipHint: Sendable {
    public let signature: String
    public let highlightStart: Int
    public let highlightEnd: Int

    public init(signature: String, highlightStart: Int = 0, highlightEnd: Int = 0) {
        self.signature = signature
        self.highlightStart = highlightStart
        self.highlightEnd = highlightEnd
    }
}

public enum CalltipEngine {
    /// Built-in API signatures for common languages (subset of Notepad++ API XML).
    private static let signatures: [String: [String: String]] = [
        "cpp": [
            "printf": "int printf(const char *format, ...)",
            "malloc": "void *malloc(size_t size)",
            "free": "void free(void *ptr)",
            "strlen": "size_t strlen(const char *s)",
            "memcpy": "void *memcpy(void *dest, const void *src, size_t n)",
        ],
        "python": [
            "print": "print(*objects, sep=' ', end='\\n', file=sys.stdout, flush=False)",
            "range": "range(stop) | range(start, stop[, step])",
            "len": "len(obj) -> int",
            "open": "open(file, mode='r', encoding=None, ...)",
        ],
        "javascript": [
            "console.log": "console.log(...data)",
            "parseInt": "parseInt(string, radix?)",
            "setTimeout": "setTimeout(callback, delay, ...args)",
            "fetch": "fetch(input, init?)",
        ],
        "php": [
            "echo": "echo string ...$expressions",
            "array_push": "array_push(array &$array, mixed ...$values): int",
            "strlen": "strlen(string $string): int",
        ],
        "sql": [
            "SELECT": "SELECT columns FROM table [WHERE ...]",
            "INSERT": "INSERT INTO table (cols) VALUES (...)",
            "UPDATE": "UPDATE table SET col=val [WHERE ...]",
        ],
    ]

    public static func hint(
        at caret: Int,
        in text: String,
        language: EditorLanguage
    ) -> CalltipHint? {
        let ns = text as NSString
        guard caret > 0, caret <= ns.length else { return nil }

        var paren = caret - 1
        while paren >= 0 {
            let ch = ns.character(at: paren)
            if ch == 40 { break } // (
            if ch == 10 || ch == 13 || ch == 59 { return nil }
            paren -= 1
        }
        guard paren >= 0, ns.character(at: paren) == 40 else { return nil }

        let nameRange = wordRange(endingBefore: paren, in: ns)
        guard nameRange.length > 0 else { return nil }
        let name = ns.substring(with: nameRange)

        let langKey = languageKey(for: language)
        if let sig = signatures[langKey]?[name] ?? signatures[langKey]?[name.lowercased()] {
            return CalltipHint(signature: sig)
        }

        // Generic fallback for unknown functions
        if name.first?.isLetter == true {
            return CalltipHint(signature: "\(name)(...)")
        }
        return nil
    }

    private static func languageKey(for language: EditorLanguage) -> String {
        switch language {
        case .cpp_lang, .c_lang, .objc_lang: return "cpp"
        case .python_lang: return "python"
        case .javascript_js, .javascript_lang, .typescript_lang: return "javascript"
        case .php_lang, .phpscript: return "php"
        case .sql_lang, .mysql, .mssql_lang: return "sql"
        default: return language.rawValue.lowercased()
        }
    }

    private static func wordRange(endingBefore index: Int, in ns: NSString) -> NSRange {
        var end = index
        while end > 0 {
            let ch = ns.character(at: end - 1)
            if ch == 46 || ch == 58 { // . or :
                break
            }
            if !(isIdentChar(ch)) { break }
            end -= 1
        }
        var start = end
        while start > 0 {
            let ch = ns.character(at: start - 1)
            if ch == 46 || ch == 58 {
                start -= 1
                break
            }
            if !isIdentChar(ch) { break }
            start -= 1
        }
        return NSRange(location: start, length: end - start)
    }

    private static func isIdentChar(_ ch: unichar) -> Bool {
        guard let scalar = UnicodeScalar(ch) else { return false }
        return CharacterSet.alphanumerics.contains(scalar) || ch == 95 || ch == 36
    }
}
