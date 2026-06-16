import Foundation

public struct EncodingOption: Identifiable, Sendable, Hashable {
    public let id: String
    public let encoding: String.Encoding
    public let displayName: String

    public init(id: String, encoding: String.Encoding, displayName: String) {
        self.id = id
        self.encoding = encoding
        self.displayName = displayName
    }
}

public enum EncodingCatalog {
    public static let common: [EncodingOption] = [
        EncodingOption(id: "utf8", encoding: .utf8, displayName: "UTF-8"),
        EncodingOption(id: "utf16le", encoding: .utf16LittleEndian, displayName: "UTF-16 LE"),
        EncodingOption(id: "utf16be", encoding: .utf16BigEndian, displayName: "UTF-16 BE"),
        EncodingOption(id: "latin1", encoding: .isoLatin1, displayName: "Western (ISO Latin-1)"),
        EncodingOption(id: "ascii", encoding: .ascii, displayName: "ASCII"),
        EncodingOption(id: "macosroman", encoding: .macOSRoman, displayName: "macOS Roman"),
        EncodingOption(id: "windows1252", encoding: .windowsCP1252, displayName: "Windows Latin-1 (CP1252)"),
    ]

    public static func option(for encoding: String.Encoding) -> EncodingOption? {
        common.first { $0.encoding == encoding }
    }
}

public enum EncodingConverter {
    public static func reload(from url: URL, using encoding: String.Encoding) throws -> TextDocument {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        guard let text = String(data: data, encoding: encoding) else {
            throw DocumentLoadError.readFailed("Could not decode using \(encoding).")
        }
        let eol = detectEndOfLine(in: text)
        let userLanguageID = UserLanguagePersistence.detect(from: url)
        let language = EditorLanguage.detect(from: url)
        let largeFile = LargeFilePolicy.shouldUseLargeFileMode(byteCount: data.count)
        return TextDocument(
            url: url,
            text: text,
            isDirty: false,
            encoding: encoding,
            endOfLine: eol,
            language: largeFile ? LargeFilePolicy.languageForLargeFile(current: language) : language,
            userLanguageID: userLanguageID,
            caret: CaretPosition(),
            isLargeFileMode: largeFile
        )
    }

    public static func convert(document: TextDocument, to encoding: String.Encoding) throws -> TextDocument {
        guard let data = document.text.data(using: encoding) else {
            throw DocumentLoadError.readFailed("Could not encode text as \(encoding).")
        }
        guard let text = String(data: data, encoding: encoding) else {
            throw DocumentLoadError.readFailed("Round-trip encoding failed.")
        }
        var copy = document
        copy.text = text
        copy.encoding = encoding
        copy.isDirty = true
        return copy
    }

    private static func detectEndOfLine(in text: String) -> EndOfLine {
        let crlf = text.components(separatedBy: "\r\n").count - 1
        let lf = text.components(separatedBy: "\n").count - 1
        let cr = text.components(separatedBy: "\r").count - 1
        if crlf > 0, crlf >= lf { return .crlf }
        if cr > lf { return .cr }
        return .lf
    }
}
