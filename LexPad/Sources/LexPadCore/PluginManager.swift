import Combine
import AppKit
import Foundation

public struct PluginManifest: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public let entryPoint: String
    public let author: String?

    public init(id: String, name: String, version: String, description: String, entryPoint: String, author: String? = nil) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.entryPoint = entryPoint
        self.author = author
    }
}

@MainActor
public final class PluginRegistry: ObservableObject {
    @Published public private(set) var plugins: [PluginManifest] = []
    @Published public private(set) var enabledPluginIDs: Set<String> = []

    private static var pluginsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("LexPad/Plugins", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public init() {
        if let data = UserDefaults.standard.data(forKey: "enabledPlugins"),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            enabledPluginIDs = ids
        }
        PluginManager.loadBundledPlugins()
        PluginManager.setEnabled(enabledPluginIDs)
        scan()
    }

    public func scan() {
        let dir = Self.pluginsDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            plugins = bundledSamples()
            return
        }
        var found: [PluginManifest] = bundledSamples()
        for folder in contents where folder.hasDirectoryPath {
            let manifestURL = folder.appendingPathComponent("plugin.json")
            guard let data = try? Data(contentsOf: manifestURL),
                  let manifest = try? JSONDecoder().decode(PluginManifest.self, from: data) else { continue }
            found.append(manifest)
        }
        plugins = found
    }

    public func reloadPlugins() {
        ExternalPluginLoader.load()
        scan()
    }

    public func openPluginsFolder() {
        NSWorkspace.shared.open(Self.pluginsDirectory)
    }

    public func togglePlugin(_ id: String) {
        if enabledPluginIDs.contains(id) {
            enabledPluginIDs.remove(id)
        } else {
            enabledPluginIDs.insert(id)
        }
        persist()
        PluginManager.setEnabled(enabledPluginIDs)
    }

    public func persist() {
        if let data = try? JSONEncoder().encode(enabledPluginIDs) {
            UserDefaults.standard.set(data, forKey: "enabledPlugins")
        }
    }

    public var pluginsDirectoryPath: String {
        Self.pluginsDirectory.path
    }

    private func bundledSamples() -> [PluginManifest] {
        [
            PluginManifest(
                id: JSONFormatterPlugin().id,
                name: JSONFormatterPlugin().name,
                version: JSONFormatterPlugin().version,
                description: JSONFormatterPlugin().description,
                entryPoint: "builtin",
                author: "LexPad"
            ),
            PluginManifest(
                id: CSVLintPlugin().id,
                name: CSVLintPlugin().name,
                version: CSVLintPlugin().version,
                description: CSVLintPlugin().description,
                entryPoint: "builtin",
                author: "LexPad"
            ),
        ]
    }
}
