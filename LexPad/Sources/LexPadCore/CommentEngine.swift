import Foundation

public enum CommentEngine {
    public static func lineCommentPrefix(for language: EditorLanguage, userLanguage: UserDefinedLanguage? = nil) -> String? {
        if let userLanguage {
            let trimmed = userLanguage.commentLine.trimmingCharacters(in: .whitespaces)
            return trimmed.hasSuffix(" ") ? trimmed : trimmed + " "
        }
        guard let style = LanguageRegistry.commentStyle(for: language) else { return "// " }
        switch style {
        case .hash: return "# "
        case .slashSlash: return "// "
        case .semicolon: return "; "
        case .doubleDash: return "-- "
        case .percent: return "% "
        case .bang: return "! "
        case .apostrophe: return "' "
        case .pipe: return "| "
        case .rem: return "REM "
        case .backslash: return "\\ "
        case .doubleSemicolon: return ";; "
        case .cobol: return "*> "
        case .generic, .block, .ocaml, .html, .autoit, .paren, .none:
            return "// "
        }
    }

    /// Toggle line comments on lines touched by `selectedRange`. Returns nil if language has no line comments.
    public static func toggleLineComments(
        in text: String,
        language: EditorLanguage,
        selectedRange: NSRange,
        tabSize: Int = 4,
        userLanguage: UserDefinedLanguage? = nil
    ) -> String? {
        guard let prefix = lineCommentPrefix(for: language, userLanguage: userLanguage) else { return nil }
        let ns = text as NSString
        guard ns.length > 0 else { return text }
        let lineRange = affectedLineRange(in: ns, selectedRange: selectedRange)
        var lines = text.components(separatedBy: "\n")
        guard lineRange.lowerBound >= 1, lineRange.lowerBound <= lines.count else { return text }

        let affected = lines[(lineRange.lowerBound - 1)..<min(lineRange.upperBound, lines.count)]
        let allCommented = affected.allSatisfy { isCommentedLine($0, prefix: prefix) }

        for i in (lineRange.lowerBound - 1)..<min(lineRange.upperBound, lines.count) {
            if allCommented {
                lines[i] = uncommentLine(lines[i], prefix: prefix)
            } else if !isCommentedLine(lines[i], prefix: prefix) {
                lines[i] = commentLine(lines[i], prefix: prefix, tabSize: tabSize)
            }
        }
        return lines.joined(separator: "\n")
    }

    public static func blockCommentDelimiters(for language: EditorLanguage) -> (open: String, close: String)? {
        guard let style = LanguageRegistry.commentStyle(for: language) else { return nil }
        switch style {
        case .block, .html:
            return ("/*", "*/")
        case .ocaml:
            return ("(*", "*)")
        case .none:
            return nil
        default:
            if [.c_lang, .cpp_lang, .java_lang, .javascript_lang, .css_lang, .php_lang, .rust_lang, .go_lang, .swift_lang].contains(language) {
                return ("/*", "*/")
            }
            return nil
        }
    }

    public static func toggleBlockComments(
        in text: String,
        language: EditorLanguage,
        selectedRange: NSRange
    ) -> String? {
        guard let (open, close) = blockCommentDelimiters(for: language) else { return nil }
        let ns = text as NSString
        guard ns.length > 0 else { return text }
        let range: NSRange
        if selectedRange.length > 0 {
            range = selectedRange
        } else {
            range = NSRange(location: 0, length: ns.length)
        }
        let selected = ns.substring(with: range)
        let trimmed = selected.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix(open), trimmed.hasSuffix(close) {
            var inner = selected
            if let openRange = inner.range(of: open) { inner.removeSubrange(openRange) }
            if let closeRange = inner.range(of: close, options: .backwards) { inner.removeSubrange(closeRange) }
            return ns.replacingCharacters(in: range, with: inner)
        }
        let wrapped = "\(open)\(selected)\(close)"
        return ns.replacingCharacters(in: range, with: wrapped)
    }

    private static func affectedLineRange(in ns: NSString, selectedRange: NSRange) -> ClosedRange<Int> {
        guard ns.length > 0 else { return 1...1 }
        let startPos = min(max(0, selectedRange.location), ns.length - 1)
        let endPos: Int
        if selectedRange.length > 0 {
            endPos = min(NSMaxRange(selectedRange) - 1, ns.length - 1)
        } else {
            endPos = startPos
        }
        let startLine = lineNumber(in: ns, at: startPos)
        var endLine = lineNumber(in: ns, at: endPos)
        if selectedRange.length > 0, endPos < ns.length, ns.character(at: endPos) == 10 {
            endLine = max(startLine, endLine - 1)
        }
        return startLine...max(startLine, endLine)
    }

    private static func lineNumber(in ns: NSString, at position: Int) -> Int {
        guard ns.length > 0 else { return 1 }
        let prefix = ns.substring(to: position + 1) as NSString
        var count = 1
        for i in 0..<prefix.length where prefix.character(at: i) == 10 { count += 1 }
        return count
    }

    private static func isCommentedLine(_ line: String, prefix: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return true }
        return trimmed.hasPrefix(prefix.trimmingCharacters(in: .whitespaces))
            || trimmed.hasPrefix(prefix)
    }

    private static func commentLine(_ line: String, prefix: String, tabSize: Int) -> String {
        if line.trimmingCharacters(in: .whitespaces).isEmpty { return line }
        let leading = line.prefix(while: { $0 == " " || $0 == "\t" })
        return "\(leading)\(prefix)\(line.dropFirst(leading.count))"
    }

    private static func uncommentLine(_ line: String, prefix: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return line }
        let bare = prefix.trimmingCharacters(in: .whitespaces)
        if let range = line.range(of: prefix) {
            var result = line
            result.removeSubrange(range)
            if result.hasPrefix(" ") && bare.count < prefix.count {
                result.removeFirst()
            }
            return result
        }
        if let range = line.range(of: bare) {
            var result = line
            result.removeSubrange(range)
            return result
        }
        return line
    }
}
