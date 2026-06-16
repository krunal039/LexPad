import Foundation

public struct Snippet: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public var name: String
    public var body: String
    public var trigger: String?

    public init(id: String, name: String, body: String, trigger: String? = nil) {
        self.id = id
        self.name = name
        self.body = body
        self.trigger = trigger
    }
}

public enum SnippetEngine {
    /// Inserts snippet text at `range`, returning the new selection covering the inserted text.
    public static func insert(_ snippet: String, into text: String, replacing range: NSRange) -> (text: String, selection: NSRange) {
        let ns = text as NSString
        let safeRange: NSRange
        if range.location == NSNotFound || range.location > ns.length {
            safeRange = NSRange(location: ns.length, length: 0)
        } else {
            let end = min(NSMaxRange(range), ns.length)
            safeRange = NSRange(location: range.location, length: end - range.location)
        }
        let expanded = expandPlaceholders(snippet)
        let result = ns.replacingCharacters(in: safeRange, with: expanded)
        let selection = NSRange(location: safeRange.location, length: (expanded as NSString).length)
        return (result, selection)
    }

    private static func expandPlaceholders(_ body: String) -> String {
        body.replacingOccurrences(of: "${date}", with: Self.today)
            .replacingOccurrences(of: "${time}", with: Self.now)
    }

    private static var today: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private static var now: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }
}

@MainActor
public final class SnippetStore: ObservableObject {
    @Published public private(set) var snippets: [Snippet]

    public init() {
        if let data = UserDefaults.standard.data(forKey: "lexpad.snippets"),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = decoded
        } else {
            snippets = Self.builtIn
        }
    }

    public func save() {
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: "lexpad.snippets")
        }
    }

    public func snippet(id: String) -> Snippet? {
        snippets.first { $0.id == id }
    }

    public func upsert(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
        } else {
            snippets.append(snippet)
        }
        save()
    }

    public func delete(id: String) {
        snippets.removeAll { $0.id == id }
        save()
    }

    private static let builtIn: [Snippet] = [
        Snippet(id: "mit", name: "MIT License Header", body: "// Copyright (c) ${date}\n// SPDX-License-Identifier: MIT\n\n"),
        Snippet(id: "todo", name: "TODO comment", body: "// TODO: ", trigger: "todo"),
        Snippet(id: "fixme", name: "FIXME comment", body: "// FIXME: ", trigger: "fixme"),
        Snippet(id: "main-swift", name: "Swift main", body: "@main\nstruct App {\n    static func main() {\n        \n    }\n}\n"),
        Snippet(id: "func-swift", name: "Swift function", body: "func name() {\n    \n}\n"),
        Snippet(id: "if-swift", name: "Swift if", body: "if condition {\n    \n}\n"),
    ]
}
