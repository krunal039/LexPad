import Foundation

public enum UserLanguagePersistence {
    public static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("LexPad/udl", isDirectory: true)
    }

    public static func ensureDirectory() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public static func loadAll() -> [UserDefinedLanguage] {
        ensureDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap { url -> UserDefinedLanguage? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(UserDefinedLanguage.self, from: data)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public static func detect(from url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        guard !ext.isEmpty else { return nil }
        return loadAll().first { lang in
            lang.extensions.map { $0.lowercased() }.contains(ext)
        }?.id
    }

    public static func save(_ language: UserDefinedLanguage) throws {
        ensureDirectory()
        let fileURL = directory.appendingPathComponent("\(language.id).json")
        let data = try JSONEncoder().encode(language)
        try data.write(to: fileURL, options: .atomic)
    }

    public static func delete(id: String) throws {
        let fileURL = directory.appendingPathComponent("\(id).json")
        try FileManager.default.removeItem(at: fileURL)
    }
}
