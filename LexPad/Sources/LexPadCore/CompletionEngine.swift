import Foundation

public enum CompletionKind: String, Sendable {
    case keyword
    case function
    case symbol
    case word
}

public struct CompletionItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let label: String
    public let kind: CompletionKind

    public init(label: String, kind: CompletionKind) {
        self.id = "\(kind.rawValue):\(label)"
        self.label = label
        self.kind = kind
    }
}

public enum CompletionEngine {
    public static func prefix(at position: Int, in text: String) -> String {
        let ns = text as NSString
        guard position > 0, position <= ns.length else { return "" }
        var start = position
        let set = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        while start > 0 {
            let ch = ns.character(at: start - 1)
            guard let scalar = UnicodeScalar(ch), set.contains(scalar) else { break }
            start -= 1
        }
        return ns.substring(with: NSRange(location: start, length: position - start))
    }

    public static func candidates(
        in text: String,
        language: EditorLanguage,
        userLanguage: UserDefinedLanguage?,
        caretPosition: Int,
        prefix: String? = nil,
        limit: Int = 200
    ) -> [CompletionItem] {
        let needle = (prefix ?? Self.prefix(at: caretPosition, in: text)).lowercased()
        var seen = Set<String>()
        var items: [CompletionItem] = []

        func append(_ label: String, kind: CompletionKind) {
            guard !label.isEmpty, seen.insert(label).inserted else { return }
            if !needle.isEmpty, !label.lowercased().hasPrefix(needle) { return }
            items.append(CompletionItem(label: label, kind: kind))
        }

        let keywords = LanguageContext.keywords(for: language, userLanguage: userLanguage)
        for keyword in keywords {
            append(keyword, kind: .keyword)
        }

        let symbols = SymbolParser.parse(in: text, language: language)
        for symbol in symbols {
            let kind: CompletionKind = symbol.kind == .function || symbol.kind == .method ? .function : .symbol
            append(symbol.name, kind: kind)
        }

        for word in documentWords(in: text) {
            append(word, kind: .word)
        }

        return items
            .sorted { lhs, rhs in
                if lhs.kind.sortRank != rhs.kind.sortRank {
                    return lhs.kind.sortRank < rhs.kind.sortRank
                }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
            .prefix(limit)
            .map { $0 }
    }

    public static func listString(for items: [CompletionItem]) -> String {
        items.map(\.label).joined(separator: " ")
    }

    private static func documentWords(in text: String) -> [String] {
        let pattern = #"[A-Za-z_][\w]{2,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        var words = Set<String>()
        for match in matches {
            let word = ns.substring(with: match.range)
            if word.count >= 3 { words.insert(word) }
        }
        return Array(words)
    }
}

private extension CompletionKind {
    var sortRank: Int {
        switch self {
        case .function: return 0
        case .symbol: return 1
        case .keyword: return 2
        case .word: return 3
        }
    }
}
