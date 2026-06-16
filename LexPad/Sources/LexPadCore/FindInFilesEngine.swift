import Foundation

public struct FindInFilesResult: Identifiable, Sendable {
    public let id = UUID()
    public let fileURL: URL
    public let line: Int
    public let column: Int
    public let lineText: String
    public let matchRange: Range<String.Index>?

    public init(fileURL: URL, line: Int, column: Int, lineText: String, matchRange: Range<String.Index>? = nil) {
        self.fileURL = fileURL
        self.line = line
        self.column = column
        self.lineText = lineText
        self.matchRange = matchRange
    }
}

public enum FindInFilesEngine {
    private static let defaultExtensions = [
        "txt", "md", "swift", "py", "js", "ts", "json", "xml", "html", "css",
        "c", "cpp", "h", "hpp", "cs", "java", "go", "rs", "rb", "php", "sh",
        "ps1", "yaml", "yml", "toml", "ini", "cfg", "log", "sql", "pl", "lua",
    ]

    public static func search(
        directory: URL,
        pattern: String,
        options: FindOptions,
        fileFilter: String = "*.*",
        recursive: Bool = true,
        maxResults: Int = 5000
    ) throws -> [FindInFilesResult] {
        guard !pattern.isEmpty else { throw FindEngineError.emptyPattern }

        var results: [FindInFilesResult] = []
        let fm = FileManager.default
        let extensions = extensionsFromFilter(fileFilter)

        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: recursive ? [] : [.skipsSubdirectoryDescendants]
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            if results.count >= maxResults { break }
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values?.isRegularFile == true else { continue }
            if !extensions.isEmpty {
                let ext = fileURL.pathExtension.lowercased()
                guard extensions.contains(ext) || extensions.contains("*") else { continue }
            }
            guard let text = readText(from: fileURL) else { continue }
            let matches = try FindEngine.findAll(in: text, options: options)
            for match in matches {
                let lineText = lineContent(in: text, line: match.line)
                results.append(FindInFilesResult(
                    fileURL: fileURL,
                    line: match.line,
                    column: match.column,
                    lineText: lineText,
                    matchRange: match.range
                ))
                if results.count >= maxResults { break }
            }
        }
        return results
    }

    /// Search only within explicit file paths (e.g. current project open files).
    public static func search(
        files: [URL],
        pattern: String,
        options: FindOptions,
        maxResults: Int = 5000
    ) throws -> [FindInFilesResult] {
        guard !pattern.isEmpty else { throw FindEngineError.emptyPattern }
        var results: [FindInFilesResult] = []
        for fileURL in files {
            if results.count >= maxResults { break }
            guard FileManager.default.fileExists(atPath: fileURL.path),
                  let text = readText(from: fileURL) else { continue }
            let matches = try FindEngine.findAll(in: text, options: options)
            for match in matches {
                results.append(FindInFilesResult(
                    fileURL: fileURL,
                    line: match.line,
                    column: match.column,
                    lineText: lineContent(in: text, line: match.line),
                    matchRange: match.range
                ))
                if results.count >= maxResults { break }
            }
        }
        return results
    }

    private static func readText(from url: URL) -> String? {
        if let t = try? String(contentsOf: url, encoding: .utf8) { return t }
        if let t = try? String(contentsOf: url, encoding: .isoLatin1) { return t }
        return nil
    }

    private static func extensionsFromFilter(_ filter: String) -> Set<String> {
        let parts = filter.split(separator: ";").flatMap { $0.split(separator: ",") }
        var exts = Set<String>()
        for part in parts {
            let s = part.trimmingCharacters(in: .whitespaces).lowercased()
            if s == "*.*" || s == "*" { return ["*"] }
            if s.hasPrefix("*.") {
                exts.insert(String(s.dropFirst(2)))
            }
        }
        return exts.isEmpty ? Set(defaultExtensions) : exts
    }

    private static func lineContent(in text: String, line: Int) -> String {
        var lineNum = 1
        var start = text.startIndex
        while start < text.endIndex {
            let end = text[start...].firstIndex(of: "\n") ?? text.endIndex
            if lineNum == line {
                return String(text[start..<end])
            }
            lineNum += 1
            start = end == text.endIndex ? end : text.index(after: end)
        }
        return ""
    }
}
