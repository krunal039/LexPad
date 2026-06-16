import Foundation

public struct RecentFileEntry: Codable, Sendable, Identifiable, Equatable {
    public var id: String { path }
    public let path: String
    public var lastOpened: Date
    public var openCount: Int
    public var pinned: Bool

    public init(path: String, lastOpened: Date = Date(), openCount: Int = 1, pinned: Bool = false) {
        self.path = path
        self.lastOpened = lastOpened
        self.openCount = openCount
        self.pinned = pinned
    }

    public var url: URL { URL(fileURLWithPath: path) }

    private enum CodingKeys: String, CodingKey {
        case path, lastOpened, openCount, pinned
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = try c.decode(String.self, forKey: .path)
        lastOpened = try c.decode(Date.self, forKey: .lastOpened)
        openCount = try c.decode(Int.self, forKey: .openCount)
        pinned = try c.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
    }
}

public enum RecentFilesStore {
    private static let key = "com.codetails.lexpad.recentFiles.v2"
    private static let legacyKey = "com.codetails.lexpad.recentFiles"
    private static let maxCount = 50

    public static func loadEntries() -> [RecentFileEntry] {
        migrateLegacyIfNeeded()
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([RecentFileEntry].self, from: data) else {
            return []
        }
        return entries.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    public static func load() -> [URL] {
        loadEntries().map(\.url)
    }

    public static func remember(_ url: URL, in list: [URL]) -> [URL] {
        _ = rememberEntry(url)
        return load()
    }

    @discardableResult
    public static func rememberEntry(_ url: URL) -> [RecentFileEntry] {
        var entries = loadEntries()
        let path = url.path
        if let index = entries.firstIndex(where: { $0.path == path }) {
            var entry = entries.remove(at: index)
            entry.lastOpened = Date()
            entry.openCount += 1
            entries.insert(entry, at: 0)
        } else {
            entries.insert(RecentFileEntry(path: path), at: 0)
        }
        entries = Array(entries.prefix(maxCount))
        saveEntries(entries)
        return entries
    }

    public static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    public static func remove(path: String) {
        var entries = loadEntries()
        entries.removeAll { $0.path == path }
        saveEntries(entries)
    }

    public static func setPinned(path: String, pinned: Bool) {
        var entries = loadEntries()
        guard let index = entries.firstIndex(where: { $0.path == path }) else { return }
        entries[index].pinned = pinned
        saveEntries(entries)
    }

    public static func togglePinned(path: String) {
        var entries = loadEntries()
        guard let index = entries.firstIndex(where: { $0.path == path }) else { return }
        entries[index].pinned.toggle()
        saveEntries(entries)
    }

    public static func renamePath(from oldURL: URL, to newURL: URL) {
        var entries = loadEntries()
        guard let index = entries.firstIndex(where: { $0.path == oldURL.path }) else { return }
        let entry = entries.remove(at: index)
        entries.insert(
            RecentFileEntry(
                path: newURL.path,
                lastOpened: entry.lastOpened,
                openCount: entry.openCount,
                pinned: entry.pinned
            ),
            at: 0
        )
        saveEntries(entries)
    }

    private static func saveEntries(_ entries: [RecentFileEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func migrateLegacyIfNeeded() {
        guard UserDefaults.standard.data(forKey: key) == nil,
              let paths = UserDefaults.standard.stringArray(forKey: legacyKey) else { return }
        let entries = paths.map { RecentFileEntry(path: $0) }
        saveEntries(entries)
    }
}
