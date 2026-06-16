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
    public var userLanguageID: String?
    public var caret: CaretPosition
    public var bookmarks: [Bookmark]
    public var isOverwriteMode: Bool
    public var lineChangeHistory: [Int: LineChangeState]
    public var isLargeFileMode: Bool
    public var isReadOnly: Bool
    public var isPinned: Bool
    public var encodingLabel: String?
    /// Custom label for untitled tabs (session restore + inline rename).
    public var untitledName: String?

    public init(
        id: UUID = UUID(),
        url: URL? = nil,
        text: String = "",
        isDirty: Bool = false,
        encoding: String.Encoding = .utf8,
        endOfLine: EndOfLine = .lf,
        language: EditorLanguage = .normal_lang,
        userLanguageID: String? = nil,
        caret: CaretPosition = CaretPosition(),
        bookmarks: [Bookmark] = [],
        isOverwriteMode: Bool = false,
        lineChangeHistory: [Int: LineChangeState] = [:],
        isLargeFileMode: Bool = false,
        isReadOnly: Bool = false,
        isPinned: Bool = false,
        encodingLabel: String? = nil,
        untitledName: String? = nil
    ) {
        self.id = id
        self.url = url
        self.text = text
        self.isDirty = isDirty
        self.encoding = encoding
        self.endOfLine = endOfLine
        self.language = language
        self.userLanguageID = userLanguageID
        self.caret = caret
        self.bookmarks = bookmarks
        self.isOverwriteMode = isOverwriteMode
        self.lineChangeHistory = lineChangeHistory
        self.isLargeFileMode = isLargeFileMode
        self.isReadOnly = isReadOnly
        self.isPinned = isPinned
        self.encodingLabel = encodingLabel
        self.untitledName = untitledName
    }

    /// Tab title without dirty/pin/read-only adornments (used for inline rename).
    public var tabTitle: String {
        if let url {
            return url.lastPathComponent
        }
        return untitledName ?? "Untitled"
    }

    public var displayName: String {
        var name = tabTitle
        if isReadOnly { name += " 🔒" }
        if isPinned { name = "📌 " + name }
        return name + (isDirty ? " •" : "")
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

public enum DocumentRenameError: Error, LocalizedError {
    case invalidName
    case fileExists
    case renameFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidName: return "Invalid file name."
        case .fileExists: return "A file with that name already exists."
        case .renameFailed(let message): return message
        }
    }
}

public enum DocumentStore {
    public static func load(from url: URL, largeFileThresholdBytes: Int? = nil) throws -> TextDocument {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DocumentLoadError.fileNotFound
        }

        let start = CFAbsoluteTimeGetCurrent()
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        let detection = EncodingDetector.detect(in: data)
        let encoding = detection.encoding
        guard let text = String(data: data, encoding: encoding) else {
            throw DocumentLoadError.readFailed("Could not decode file using \(encoding).")
        }

        let eol = detectEndOfLine(in: text)
        let userLanguageID = UserLanguagePersistence.detect(from: url)
        let language = EditorLanguage.detect(from: url)
        let threshold = largeFileThresholdBytes ?? LargeFilePolicy.defaultThresholdBytes
        let largeFile = LargeFilePolicy.shouldUseLargeFileMode(byteCount: data.count, threshold: threshold)

        return TextDocument(
            url: url,
            text: text,
            isDirty: false,
            encoding: encoding,
            endOfLine: eol,
            language: largeFile ? LargeFilePolicy.languageForLargeFile(current: language) : language,
            userLanguageID: userLanguageID,
            caret: CaretPosition(),
            isLargeFileMode: largeFile,
            isReadOnly: !FileManager.default.isWritableFile(atPath: url.path),
            encodingLabel: detection.label
        )
        .withLoadMetrics(bytes: data.count, seconds: elapsed)
    }

    public static func save(_ document: TextDocument, to url: URL? = nil) throws -> TextDocument {
        let target = url ?? document.url
        guard let target else {
            throw DocumentLoadError.readFailed("No save location specified.")
        }
        if document.isReadOnly {
            throw DocumentLoadError.readFailed("Document is read-only.")
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
        saved.userLanguageID = UserLanguagePersistence.detect(from: target)
        ChangeHistoryEngine.commitSave(in: &saved.lineChangeHistory)
        return saved
    }

    /// Legacy helper — prefer `EncodingDetector`.
    private static func detectEncoding(in data: Data) -> String.Encoding? {
        EncodingDetector.detect(in: data).encoding
    }

    private static func detectEndOfLine(in text: String) -> EndOfLine {
        var crlf = 0, lf = 0, cr = 0
        let bytes = Array(text.utf8)
        var i = 0
        while i < bytes.count {
            if bytes[i] == 0x0D {
                if i + 1 < bytes.count, bytes[i + 1] == 0x0A {
                    crlf += 1
                    i += 2
                } else {
                    cr += 1
                    i += 1
                }
            } else if bytes[i] == 0x0A {
                lf += 1
                i += 1
            } else {
                i += 1
            }
        }
        if crlf > 0, crlf >= lf, crlf >= cr { return .crlf }
        if cr > lf, cr > crlf { return .cr }
        return .lf
    }
}

private extension TextDocument {
    func withLoadMetrics(bytes: Int, seconds: Double) -> TextDocument {
        _ = (bytes, seconds)
        return self
    }
}
