import Foundation

public struct LexPadPluginCommand: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let action: String

    public init(id: String, title: String, action: String) {
        self.id = id
        self.title = title
        self.action = action
    }
}

public protocol LexPadPlugin: Sendable {
    var id: String { get }
    var name: String { get }
    var version: String { get }
    var description: String { get }
    func activate()
    func deactivate()
    func commands() -> [LexPadPluginCommand]
    func run(action: String, text: String, selection: NSRange) -> String?
}

@MainActor
public enum PluginManager {
    private static var plugins: [String: any LexPadPlugin] = [:]
    private static var enabledIDs: Set<String> = []

    public static func register(_ plugin: any LexPadPlugin) {
        plugins[plugin.id] = plugin
    }

    public static func setEnabled(_ ids: Set<String>) {
        for (id, plugin) in plugins where enabledIDs.contains(id) && !ids.contains(id) {
            plugin.deactivate()
        }
        enabledIDs = ids
        for id in ids {
            plugins[id]?.activate()
        }
    }

    public static var installed: [any LexPadPlugin] {
        Array(plugins.values).sorted { $0.name < $1.name }
    }

    public static func commands() -> [(plugin: any LexPadPlugin, command: LexPadPluginCommand)] {
        installed.flatMap { plugin in
            guard enabledIDs.contains(plugin.id) else { return [(any LexPadPlugin, LexPadPluginCommand)]() }
            return plugin.commands().map { (plugin, $0) }
        }
    }

    public static func run(pluginID: String, action: String, text: String, selection: NSRange) -> String? {
        guard enabledIDs.contains(pluginID), let plugin = plugins[pluginID] else { return nil }
        return plugin.run(action: action, text: text, selection: selection)
    }

    public static func loadBundledPlugins() {
        register(JSONFormatterPlugin())
        register(XMLFormatterPlugin())
        register(CSVLintPlugin())
        ExternalPluginLoader.load()
    }
}

@MainActor
public enum ExternalPluginLoader {
    public static func load() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LexPad/Plugins", isDirectory: true)
        guard let entries = try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil) else { return }
        for folder in entries where folder.hasDirectoryPath {
            let manifest = folder.appendingPathComponent("plugin.json")
            guard let data = try? Data(contentsOf: manifest),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = json["id"] as? String,
                  let name = json["name"] as? String else { continue }
            let scriptName = json["script"] as? String ?? json["entryPoint"] as? String ?? "plugin.sh"
            let script = folder.appendingPathComponent(scriptName)
            PluginManager.register(ScriptPlugin(id: id, name: name, scriptURL: script))
        }
    }
}

public struct ScriptPlugin: LexPadPlugin {
    public let id: String
    public let name: String
    public let scriptURL: URL
    public let version = "1.0.0"
    public let description = "External script plugin"

    public func activate() {}
    public func deactivate() {}

    public func commands() -> [LexPadPluginCommand] {
        [LexPadPluginCommand(id: "run", title: "Run \(name)", action: "run")]
    }

    public func run(action: String, text: String, selection: NSRange) -> String? {
        guard action == "run", FileManager.default.fileExists(atPath: scriptURL.path) else { return nil }
        let proc = Process()
        proc.executableURL = scriptURL
        let pipe = Pipe()
        proc.standardInput = pipe
        let out = Pipe()
        proc.standardOutput = out
        let slice: String
        if selection.length > 0, NSMaxRange(selection) <= (text as NSString).length {
            slice = (text as NSString).substring(with: selection)
        } else {
            slice = text
        }
        try? proc.run()
        pipe.fileHandleForWriting.write(slice.data(using: .utf8) ?? Data())
        try? pipe.fileHandleForWriting.close()
        proc.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else { return nil }
        if selection.length > 0 {
            return (text as NSString).replacingCharacters(in: selection, with: output)
        }
        return output
    }
}

public struct XMLFormatterPlugin: LexPadPlugin {
    public let id = "com.lexpad.xml-formatter"
    public let name = "XML Formatter"
    public let version = "1.0.0"
    public let description = "Pretty-print XML in selection or whole document."

    public func activate() {}
    public func deactivate() {}

    public func commands() -> [LexPadPluginCommand] {
        [LexPadPluginCommand(id: "format", title: "Format XML", action: "format")]
    }

    public func run(action: String, text: String, selection: NSRange) -> String? {
        guard action == "format" else { return nil }
        let ns = text as NSString
        let slice: String
        if selection.length > 0, NSMaxRange(selection) <= ns.length {
            slice = ns.substring(with: selection)
        } else {
            slice = text
        }
        guard let data = slice.data(using: .utf8),
              let doc = try? XMLDocument(data: data, options: []) else { return nil }
        let output = doc.xmlString(options: [.nodePrettyPrint]).trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        if selection.length > 0 {
            return ns.replacingCharacters(in: selection, with: output)
        }
        return output
    }
}

// MARK: - Bundled plugins

public struct JSONFormatterPlugin: LexPadPlugin {
    public let id = "com.lexpad.json-formatter"
    public let name = "JSON Formatter"
    public let version = "1.0.0"
    public let description = "Pretty-print JSON in selection or whole document."

    public func activate() {}
    public func deactivate() {}

    public func commands() -> [LexPadPluginCommand] {
        [LexPadPluginCommand(id: "format", title: "Format JSON", action: "format")]
    }

    public func run(action: String, text: String, selection: NSRange) -> String? {
        guard action == "format" else { return nil }
        let ns = text as NSString
        let slice: String
        if selection.length > 0, NSMaxRange(selection) <= ns.length {
            slice = ns.substring(with: selection)
        } else {
            slice = text
        }
        guard let data = slice.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let output = String(data: pretty, encoding: .utf8) else { return nil }
        if selection.length > 0 {
            return ns.replacingCharacters(in: selection, with: output)
        }
        return output
    }
}

public struct CSVLintPlugin: LexPadPlugin {
    public let id = "com.lexpad.csv-lint"
    public let name = "CSV Lint"
    public let version = "1.0.0"
    public let description = "Validate CSV row column counts."

    public func activate() {}
    public func deactivate() {}

    public func commands() -> [LexPadPluginCommand] {
        [LexPadPluginCommand(id: "lint", title: "Lint CSV", action: "lint")]
    }

    public func run(action: String, text: String, selection: NSRange) -> String? {
        guard action == "lint" else { return nil }
        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let first = lines.first else { return "// CSV Lint: empty file\n" }
        let expected = first.split(separator: ",", omittingEmptySubsequences: false).count
        var issues: [String] = []
        for (index, line) in lines.enumerated() {
            let cols = line.split(separator: ",", omittingEmptySubsequences: false).count
            if cols != expected {
                issues.append("Line \(index + 1): expected \(expected) columns, found \(cols)")
            }
        }
        let report = issues.isEmpty
            ? "// CSV Lint: OK (\(lines.count) rows, \(expected) columns)\n"
            : "// CSV Lint issues:\n" + issues.map { "// \($0)" }.joined(separator: "\n") + "\n"
        return text + (text.hasSuffix("\n") ? "" : "\n") + report
    }
}
