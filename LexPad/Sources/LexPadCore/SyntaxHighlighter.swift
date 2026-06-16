import AppKit
import Foundation

public enum SyntaxHighlighter {
    public struct Theme: Sendable {
        public var keyword: NSColor
        public var string: NSColor
        public var comment: NSColor
        public var number: NSColor
        public var type: NSColor
        public var plain: NSColor

        public static func forAppearance(_ dark: Bool) -> Theme {
            if dark {
                return Theme(
                    keyword: NSColor(red: 0.67, green: 0.39, blue: 0.98, alpha: 1),
                    string: NSColor(red: 0.98, green: 0.43, blue: 0.42, alpha: 1),
                    comment: NSColor(red: 0.42, green: 0.47, blue: 0.53, alpha: 1),
                    number: NSColor(red: 0.82, green: 0.60, blue: 0.32, alpha: 1),
                    type: NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1),
                    plain: NSColor.textColor
                )
            }
            return Theme(
                keyword: NSColor(red: 0.55, green: 0.0, blue: 0.75, alpha: 1),
                string: NSColor(red: 0.77, green: 0.10, blue: 0.09, alpha: 1),
                comment: NSColor(red: 0.0, green: 0.53, blue: 0.0, alpha: 1),
                number: NSColor(red: 0.11, green: 0.21, blue: 0.85, alpha: 1),
                type: NSColor(red: 0.0, green: 0.45, blue: 0.70, alpha: 1),
                plain: NSColor.textColor
            )
        }
    }

    public static func apply(to storage: NSTextStorage, language: EditorLanguage, font: NSFont, darkMode: Bool) {
        let full = NSRange(location: 0, length: (storage.string as NSString).length)
        let theme = Theme.forAppearance(darkMode)

        storage.beginEditing()
        storage.removeAttribute(.foregroundColor, range: full)
        storage.addAttribute(.foregroundColor, value: theme.plain, range: full)
        storage.addAttribute(.font, value: font, range: full)

        guard language != .normal_lang else {
            storage.endEditing()
            return
        }

        guard let spec = LanguageRegistry.spec(for: language) else {
            storage.endEditing()
            return
        }

        if let special = spec.specialHighlighter {
            switch special {
            case .log:
                applyLog(to: storage, range: full)
            case .syntext:
                applySyntext(to: storage, theme: theme, font: font, range: full)
            case .markdown:
                applyMarkdown(to: storage, theme: theme, font: font, range: full)
            case .json:
                applyJSON(to: storage, theme: theme, range: full)
            case .yaml:
                applyYAML(to: storage, theme: theme, range: full)
            case .html, .xml:
                applyMarkup(to: storage, theme: theme, range: full)
            case .css:
                applyCSS(to: storage, theme: theme, range: full)
            case .diff:
                applyDiff(to: storage, theme: theme, range: full)
            }
            storage.endEditing()
            return
        }

        applyComments(spec.commentStyle, to: storage, theme: theme, range: full)
        applyStringsAndNumbers(to: storage, theme: theme, range: full, language: language)

        if language == .powershell_lang {
            highlightPattern(#"\$\w+"#, in: storage, color: theme.type, range: full)
        }
        if language == .php_lang || language == .phpscript {
            highlightPattern(#"<\?[\s\S]*?\?>"#, in: storage, color: theme.type, range: full)
        }
        if language == .batch_lang {
            highlightPattern(#"%[\w]+%"#, in: storage, color: theme.type, range: full)
        }

        applyKeywords(spec.keywords, to: storage, theme: theme, range: full, caseInsensitive: shouldIgnoreCase(language))
        storage.endEditing()
    }

    private static func shouldIgnoreCase(_ language: EditorLanguage) -> Bool {
        switch language {
        case .powershell_lang, .vb_lang, .vbscript, .sql_lang, .mssql_lang, .mysql:
            return true
        default:
            return false
        }
    }

    private static func applyComments(
        _ style: LanguageRegistryData.CommentStyle,
        to storage: NSTextStorage,
        theme: Theme,
        range: NSRange
    ) {
        switch style {
        case .hash:
            highlightPattern(#"(?m)^\s*#.*$"#, in: storage, color: theme.comment, range: range)
        case .slashSlash:
            highlightPattern(#"//.*$"#, in: storage, color: theme.comment, range: range, options: .anchorsMatchLines)
        case .semicolon:
            highlightPattern(#";[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .doubleDash:
            highlightPattern(#"--[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .percent:
            highlightPattern(#"%[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .bang:
            highlightPattern(#"![^\n]*"#, in: storage, color: theme.comment, range: range)
        case .apostrophe:
            highlightPattern(#"'[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .pipe:
            highlightPattern(#"(?m)^\s*\|[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .cobol:
            highlightPattern(#"(?m)^\s*\*>[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .doubleSemicolon:
            highlightPattern(#";;[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .rem:
            highlightPattern(#"(?i)(?:^|\s)(?:rem|::)[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .backslash:
            highlightPattern(#"\\[^\n]*"#, in: storage, color: theme.comment, range: range)
        case .block:
            highlightPattern(#"/\*[\s\S]*?\*/"#, in: storage, color: theme.comment, range: range)
            highlightPattern(#"//.*$"#, in: storage, color: theme.comment, range: range, options: .anchorsMatchLines)
        case .ocaml:
            highlightPattern(#"\(\*[\s\S]*?\*\)"#, in: storage, color: theme.comment, range: range)
        case .html:
            highlightPattern(#"<!--[\s\S]*?-->"#, in: storage, color: theme.comment, range: range)
        case .autoit:
            highlightPattern(#"(?m)^\s*;.*$"#, in: storage, color: theme.comment, range: range)
            highlightPattern(#"(?s)#CS[\s\S]*?#CE"#, in: storage, color: theme.comment, range: range)
        case .paren:
            highlightPattern(#"\([^)]*\)"#, in: storage, color: theme.comment, range: range)
        case .generic:
            highlightPattern(#"(//.*$|#.*$)"#, in: storage, color: theme.comment, range: range, options: .anchorsMatchLines)
            highlightPattern(#"/\*[\s\S]*?\*/"#, in: storage, color: theme.comment, range: range)
        case .none:
            break
        }
    }

    private static func applyStringsAndNumbers(
        to storage: NSTextStorage,
        theme: Theme,
        range: NSRange,
        language: EditorLanguage
    ) {
        highlightPattern(#"(?s)@["'].*?["']@"#, in: storage, color: theme.string, range: range)
        highlightPattern(#"""(?:\\.|[^"\\])*"""#, in: storage, color: theme.string, range: range)
        highlightPattern(#"(?<![\w$])"(?:\\.|[^"\\])*""#, in: storage, color: theme.string, range: range)
        highlightPattern(#"'(?:\\.|[^'\\])*'"#, in: storage, color: theme.string, range: range)
        highlightPattern(#"\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#, in: storage, color: theme.number, range: range)

        if language == .latex_lang || language == .tex_lang {
            highlightPattern(#"\$[^$\n]+\$"#, in: storage, color: theme.string, range: range)
            highlightPattern(#"\\[\w]+(?:\[[^\]]*\])?"#, in: storage, color: theme.type, range: range)
        }
    }

    private static func applyKeywords(
        _ keywords: [String],
        to storage: NSTextStorage,
        theme: Theme,
        range: NSRange,
        caseInsensitive: Bool
    ) {
        guard !keywords.isEmpty else { return }
        let options: NSRegularExpression.Options = caseInsensitive ? .caseInsensitive : []
        let pattern = "\\b(" + keywords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")\\b"
        highlightPattern(pattern, in: storage, color: theme.keyword, range: range, options: options)
    }

    private static func applyLog(to storage: NSTextStorage, range: NSRange) {
        highlightPattern(#"\b(ERROR|FATAL|CRITICAL)\b"#, in: storage, color: NSColor.systemRed, range: range)
        highlightPattern(#"\b(WARN|WARNING)\b"#, in: storage, color: NSColor.systemOrange, range: range)
        highlightPattern(#"\b(INFO|DEBUG|TRACE)\b"#, in: storage, color: NSColor.systemBlue, range: range)
    }

    private static func applyDiff(to storage: NSTextStorage, theme: Theme, range: NSRange) {
        highlightPattern(#"(?m)^\+[^\n]*"#, in: storage, color: NSColor.systemGreen, range: range)
        highlightPattern(#"(?m)^-[^\n]*"#, in: storage, color: NSColor.systemRed, range: range)
        highlightPattern(#"(?m)^@@[^\n]*"#, in: storage, color: theme.type, range: range)
        highlightPattern(#"(?m)^diff[^\n]*"#, in: storage, color: theme.keyword, range: range)
    }

    private static func applySyntext(to storage: NSTextStorage, theme: Theme, font: NSFont, range: NSRange) {
        highlightPattern(#"^:::+\s*comment\b[^\n]*"#, in: storage, color: theme.comment, range: range, options: .anchorsMatchLines)
        highlightPattern(#"^:::+\s*end\s*:?\s*$"#, in: storage, color: theme.type, range: range, options: .anchorsMatchLines)
        highlightPattern(#"^:::+\s*[\w!-]+[^\n]*"#, in: storage, color: theme.type, range: range, options: .anchorsMatchLines)
        highlightPattern(#"^:[A-Za-z][\w-]*[^\n]*"#, in: storage, color: theme.type, range: range, options: .anchorsMatchLines)
        highlightPattern(#"^#{1,6}\s+.+"#, in: storage, color: theme.type, range: range, options: .anchorsMatchLines)
        highlightPattern(#"`[^`\n]+`"#, in: storage, color: theme.string, range: range)
        highlightPattern(#"\[[^\]\n]+\]\([^)\n]+\)"#, in: storage, color: theme.string, range: range)
    }

    private static func applyMarkdown(to storage: NSTextStorage, theme: Theme, font: NSFont, range: NSRange) {
        highlightPattern(#"^#{1,6}\s+.+"#, in: storage, color: theme.type, range: range, options: .anchorsMatchLines)
        highlightPattern(#"\*\*[^*\n]+\*\*"#, in: storage, color: theme.keyword, range: range)
        highlightPattern(#"(?<!\*)\*[^*\n]+\*(?!\*)"#, in: storage, color: theme.keyword, range: range)
        highlightPattern(#"`[^`\n]+`"#, in: storage, color: theme.string, range: range)
        highlightPattern(#"\[[^\]\n]+\]\([^)\n]+\)"#, in: storage, color: theme.string, range: range)
    }

    private static func applyJSON(to storage: NSTextStorage, theme: Theme, range: NSRange) {
        highlightPattern(#""(?:\\.|[^"\\])*"(?=\s*:)"#, in: storage, color: theme.type, range: range)
        highlightPattern(#""(?:\\.|[^"\\])*""#, in: storage, color: theme.string, range: range)
        highlightPattern(#"\b(true|false|null)\b"#, in: storage, color: theme.keyword, range: range)
        highlightPattern(#"-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?"#, in: storage, color: theme.number, range: range)
    }

    private static func applyYAML(to storage: NSTextStorage, theme: Theme, range: NSRange) {
        highlightPattern(#"#[^\n]*"#, in: storage, color: theme.comment, range: range)
        highlightPattern(#"^[\w-]+:"#, in: storage, color: theme.type, range: range, options: .anchorsMatchLines)
        highlightPattern(#""(?:\\.|[^"\\])*""#, in: storage, color: theme.string, range: range)
        highlightPattern(#"'(?:\\.|[^'\\])*'"#, in: storage, color: theme.string, range: range)
    }

    private static func applyMarkup(to storage: NSTextStorage, theme: Theme, range: NSRange) {
        highlightPattern(#"<!--[\s\S]*?-->"#, in: storage, color: theme.comment, range: range)
        highlightPattern(#"</?[\w:-]+(?:\s+[^>]*)?>"#, in: storage, color: theme.type, range: range)
        highlightPattern(#""(?:\\.|[^"\\])*""#, in: storage, color: theme.string, range: range)
    }

    private static func applyCSS(to storage: NSTextStorage, theme: Theme, range: NSRange) {
        highlightPattern(#"/\*[\s\S]*?\*/"#, in: storage, color: theme.comment, range: range)
        highlightPattern(#"[.#][\w-]+"#, in: storage, color: theme.type, range: range)
        highlightPattern(#"[\w-]+(?=\s*:)"#, in: storage, color: theme.keyword, range: range)
        highlightPattern(#":\s*[^;{}]+"#, in: storage, color: theme.string, range: range)
    }

    private static func highlightPattern(
        _ pattern: String,
        in storage: NSTextStorage,
        color: NSColor,
        range: NSRange,
        options: NSRegularExpression.Options = []
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let text = storage.string
        regex.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
            guard let result else { return }
            storage.addAttribute(.foregroundColor, value: color, range: result.range)
        }
    }
}
