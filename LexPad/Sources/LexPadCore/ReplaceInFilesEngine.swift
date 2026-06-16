import Foundation

public struct ReplaceInFilesResult: Sendable {
    public let filesModified: Int
    public let replacements: Int
    public let skipped: Int

    public init(filesModified: Int, replacements: Int, skipped: Int) {
        self.filesModified = filesModified
        self.replacements = replacements
        self.skipped = skipped
    }
}

public enum ReplaceInFilesEngine {
    public static func replace(
        directory: URL,
        pattern: String,
        replacement: String,
        options: FindOptions,
        fileFilter: String = "*.*",
        recursive: Bool = true,
        dryRun: Bool = false
    ) throws -> ReplaceInFilesResult {
        guard !pattern.isEmpty else { throw FindEngineError.emptyPattern }

        var filesModified = 0
        var totalReplacements = 0
        var skipped = 0
        let fm = FileManager.default
        let extensions = extensionsFromFilter(fileFilter)

        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: recursive ? [] : [.skipsSubdirectoryDescendants]
        ) else { return ReplaceInFilesResult(filesModified: 0, replacements: 0, skipped: 0) }

        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values?.isRegularFile == true else { continue }
            if !extensions.isEmpty {
                let ext = fileURL.pathExtension.lowercased()
                guard extensions.contains(ext) || extensions.contains("*") else { continue }
            }
            guard let text = readText(from: fileURL) else {
                skipped += 1
                continue
            }
            guard let result = try? FindEngine.replaceAll(in: text, options: options, replacement: replacement),
                  result.count > 0 else { continue }

            totalReplacements += result.count
            if dryRun { continue }

            guard let data = result.text.data(using: .utf8) else {
                skipped += 1
                continue
            }
            do {
                try data.write(to: fileURL, options: .atomic)
                filesModified += 1
            } catch {
                skipped += 1
            }
        }
        return ReplaceInFilesResult(filesModified: filesModified, replacements: totalReplacements, skipped: skipped)
    }

    private static func extensionsFromFilter(_ filter: String) -> Set<String> {
        let parts = filter.split(separator: ";").flatMap { $0.split(separator: ",") }
        var exts = Set<String>()
        for part in parts {
            let s = part.trimmingCharacters(in: .whitespaces).lowercased()
            if s == "*.*" || s == "*" { return ["*"] }
            if s.hasPrefix("*.") { exts.insert(String(s.dropFirst(2))) }
        }
        return exts
    }

    private static func readText(from url: URL) -> String? {
        if let t = try? String(contentsOf: url, encoding: .utf8) { return t }
        if let t = try? String(contentsOf: url, encoding: .isoLatin1) { return t }
        return nil
    }
}
