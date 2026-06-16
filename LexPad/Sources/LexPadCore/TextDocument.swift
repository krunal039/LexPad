import Foundation

public enum EndOfLine: String, Sendable, CaseIterable {
    case lf = "LF"
    case crlf = "CRLF"
    case cr = "CR"

    public var displayName: String {
        switch self {
        case .lf: return "Unix (LF)"
        case .crlf: return "Windows (CR LF)"
        case .cr: return "Macintosh (CR)"
        }
    }
}

public enum EditorLanguage: String, Sendable, CaseIterable {
    case plain = "Plain Text"
    case log = "Log"
    case json = "JSON"
    case xml = "XML"
    case yaml = "YAML"
    case python = "Python"
    case swift = "Swift"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case shell = "Shell"
    case markdown = "Markdown"
    case cpp = "C++"
    case c = "C"
    case java = "Java"
    case rust = "Rust"
    case go = "Go"
    case sql = "SQL"
    case html = "HTML"
    case css = "CSS"
    case ini = "INI"
    case toml = "TOML"

    public static func detect(from url: URL) -> EditorLanguage {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "log", "out": return .log
        case "json": return .json
        case "xml", "plist", "xhtml": return .xml
        case "yaml", "yml": return .yaml
        case "py", "pyw": return .python
        case "swift": return .swift
        case "js", "mjs", "cjs": return .javascript
        case "ts", "tsx": return .typescript
        case "sh", "bash", "zsh": return .shell
        case "md", "markdown": return .markdown
        case "cpp", "cc", "cxx", "hpp", "hxx": return .cpp
        case "c", "h": return .c
        case "java": return .java
        case "rs": return .rust
        case "go": return .go
        case "sql": return .sql
        case "html", "htm": return .html
        case "css": return .css
        case "ini", "cfg", "conf": return .ini
        case "toml": return .toml
        default: return .plain
        }
    }
}

public struct CaretPosition: Equatable, Sendable {
    public var line: Int
    public var column: Int

    public init(line: Int = 1, column: Int = 1) {
        self.line = line
        self.column = column
    }
}

public struct TextDocument: Identifiable, Sendable {
    public let id: UUID
    public var url: URL?
    public var text: String
    public var isDirty: Bool
    public var encoding: String.Encoding
    public var endOfLine: EndOfLine
    public var language: EditorLanguage
    public var caret: CaretPosition

    public init(
        id: UUID = UUID(),
        url: URL? = nil,
        text: String = "",
        isDirty: Bool = false,
        encoding: String.Encoding = .utf8,
        endOfLine: EndOfLine = .lf,
        language: EditorLanguage = .plain,
        caret: CaretPosition = CaretPosition()
    ) {
        self.id = id
        self.url = url
        self.text = text
        self.isDirty = isDirty
        self.encoding = encoding
        self.endOfLine = endOfLine
        self.language = language
        self.caret = caret
    }

    public var displayName: String {
        if let url {
            return url.lastPathComponent + (isDirty ? " •" : "")
        }
        return "Untitled" + (isDirty ? " •" : "")
    }

    public var lineCount: Int {
        max(1, text.split(separator: "\n", omittingEmptySubsequences: false).count)
    }

    public var characterCount: Int {
        text.utf16.count
    }
}

public enum DocumentLoadError: Error, LocalizedError {
    case fileNotFound
    case readFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound: return "File not found."
        case .readFailed(let message): return message
        }
    }
}

public enum DocumentStore {
    public static func load(from url: URL) throws -> TextDocument {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DocumentLoadError.fileNotFound
        }

        let start = CFAbsoluteTimeGetCurrent()
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        let encoding = detectEncoding(in: data) ?? .utf8
        guard let text = String(data: data, encoding: encoding) else {
            throw DocumentLoadError.readFailed("Could not decode file using \(encoding).")
        }

        let eol = detectEndOfLine(in: text)
        let language = EditorLanguage.detect(from: url)

        return TextDocument(
            url: url,
            text: text,
            isDirty: false,
            encoding: encoding,
            endOfLine: eol,
            language: language,
            caret: CaretPosition()
        )
        .withLoadMetrics(bytes: data.count, seconds: elapsed)
    }

    public static func save(_ document: TextDocument, to url: URL? = nil) throws -> TextDocument {
        let target = url ?? document.url
        guard let target else {
            throw DocumentLoadError.readFailed("No save location specified.")
        }

        var output = document.text
        switch document.endOfLine {
        case .lf:
            output = output.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        case .crlf:
            output = output.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            output = output.replacingOccurrences(of: "\n", with: "\r\n")
        case .cr:
            output = output.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n", with: "\r")
        }

        guard let data = output.data(using: document.encoding) else {
            throw DocumentLoadError.readFailed("Could not encode document.")
        }
        try data.write(to: target, options: .atomic)
        var saved = document
        saved.url = target
        saved.text = output
        saved.isDirty = false
        saved.language = EditorLanguage.detect(from: target)
        return saved
    }

    private static func detectEncoding(in data: Data) -> String.Encoding? {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) { return .utf8 }
        if data.starts(with: [0xFF, 0xFE]) { return .utf16LittleEndian }
        if data.starts(with: [0xFE, 0xFF]) { return .utf16BigEndian }
        if String(data: data, encoding: .utf8) != nil { return .utf8 }
        return .isoLatin1
    }

    private static func detectEndOfLine(in text: String) -> EndOfLine {
        let crlf = text.components(separatedBy: "\r\n").count - 1
        let lf = text.components(separatedBy: "\n").count - 1 - crlf
        let cr = text.components(separatedBy: "\r").count - 1 - crlf
        if crlf > lf && crlf > cr { return .crlf }
        if cr > lf && cr > crlf { return .cr }
        return .lf
    }
}

private extension TextDocument {
    func withLoadMetrics(bytes: Int, seconds: Double) -> TextDocument {
        _ = (bytes, seconds)
        return self
    }
}
