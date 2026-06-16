import Foundation

public struct DocumentSymbol: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let name: String
    public let kind: SymbolKind
    public let line: Int

    public init(name: String, kind: SymbolKind, line: Int) {
        self.name = name
        self.kind = kind
        self.line = line
    }
}

public enum SymbolKind: String, Sendable {
    case function
    case `class`
    case structKind = "struct"
    case interface
    case method
    case variable
    case namespace
    case other
}

public enum SymbolParser {
    /// Regex-based symbol extraction (Notepad++ Function List style).
    public static func parse(in text: String, language: EditorLanguage) -> [DocumentSymbol] {
        let lines = text.components(separatedBy: "\n")
        var symbols: [DocumentSymbol] = []
        let patterns = patterns(for: language)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") || trimmed.hasPrefix("#") || trimmed.hasPrefix("--") { continue }
            for (regex, kind) in patterns {
                guard let re = try? NSRegularExpression(pattern: regex, options: []),
                      let match = re.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                      match.numberOfRanges > 1,
                      let range = Range(match.range(at: 1), in: line) else { continue }
                let name = String(line[range]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    symbols.append(DocumentSymbol(name: name, kind: kind, line: index + 1))
                }
                break
            }
        }
        return symbols
    }

    private static func patterns(for language: EditorLanguage) -> [(String, SymbolKind)] {
        switch language.rawValue.lowercased() {
        case let s where s.contains("python"):
            return [
                (#"^\s*def\s+([a-zA-Z_][\w]*)"#, .function),
                (#"^\s*class\s+([a-zA-Z_][\w]*)"#, .class),
            ]
        case let s where s.contains("javascript") || s.contains("typescript"):
            return [
                (#"^\s*(?:export\s+)?function\s+([a-zA-Z_$][\w$]*)"#, .function),
                (#"^\s*(?:export\s+)?class\s+([a-zA-Z_$][\w$]*)"#, .class),
                (#"^\s*([a-zA-Z_$][\w$]*)\s*=\s*(?:async\s*)?\([^)]*\)\s*=>"#, .function),
            ]
        default:
            return [
                (#"^\s*(?:public|private|protected|internal|static|async|override|virtual|final|\s)*\s*(?:class|struct)\s+([a-zA-Z_][\w]*)"#, .class),
                (#"^\s*(?:public|private|protected|internal|static|async|override|virtual|final|\s)*\s*func\s+([a-zA-Z_][\w]*)"#, .function),
                (#"^\s*(?:public|private|protected|internal|static|async|override|virtual|extern|\s)*[\w<>\[\],\s]+\s+([a-zA-Z_][\w]*)\s*\([^;]*\)\s*\{?"#, .function),
                (#"^\s*(?:public|private|protected|internal|static|async|override|virtual|\s)*\s*interface\s+([a-zA-Z_][\w]*)"#, .interface),
                (#"^\s*def\s+([a-zA-Z_][\w]*)"#, .function),
                (#"^\s*function\s+([a-zA-Z_][\w]*)"#, .function),
            ]
        }
    }
}
