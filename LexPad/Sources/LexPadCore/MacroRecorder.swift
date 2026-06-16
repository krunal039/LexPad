import Combine
import Foundation

public struct RecordedMacro: Codable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var commandNames: [String]

    public init(id: UUID = UUID(), name: String, commandNames: [String]) {
        self.id = id
        self.name = name
        self.commandNames = commandNames
    }
}

@MainActor
public final class MacroRecorder: ObservableObject {
    @Published public private(set) var isRecording = false
    @Published public private(set) var macros: [RecordedMacro] = []

    private var recordedCommands: [String] = []
    private var observer: NSObjectProtocol?

    public init() {
        macros = Self.loadMacros()
    }

    public func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        recordedCommands = []
        observer = NotificationCenter.default.addObserver(
            forName: .lexPadMacroCommand,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, self.isRecording, let name = note.userInfo?["command"] as? String else { return }
            self.recordedCommands.append(name)
        }
    }

    public func stopRecording(name: String) {
        guard isRecording else { return }
        isRecording = false
        if let observer { NotificationCenter.default.removeObserver(observer) }
        self.observer = nil
        if !recordedCommands.isEmpty {
            let macro = RecordedMacro(name: name, commandNames: recordedCommands)
            macros.append(macro)
            Self.saveMacros(macros)
        }
        recordedCommands = []
    }

    public func play(_ macro: RecordedMacro) {
        for command in macro.commandNames {
            NotificationCenter.default.post(
                name: Notification.Name(command),
                object: nil
            )
        }
    }

    public func delete(_ macro: RecordedMacro) {
        macros.removeAll { $0.id == macro.id }
        Self.saveMacros(macros)
    }

    public func rename(_ macro: RecordedMacro, to newName: String) {
        guard let index = macros.firstIndex(where: { $0.id == macro.id }) else { return }
        macros[index].name = newName
        Self.saveMacros(macros)
    }

    public func exportMacros(to url: URL) throws {
        let data = try JSONEncoder().encode(macros)
        try data.write(to: url, options: .atomic)
    }

    public func importMacros(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let imported = try JSONDecoder().decode([RecordedMacro].self, from: data)
        macros.append(contentsOf: imported)
        Self.saveMacros(macros)
    }

    private static var macrosURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("LexPad", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("macros.json")
    }

    private static func loadMacros() -> [RecordedMacro] {
        guard let data = try? Data(contentsOf: macrosURL),
              let macros = try? JSONDecoder().decode([RecordedMacro].self, from: data) else { return [] }
        return macros
    }

    private static func saveMacros(_ macros: [RecordedMacro]) {
        guard let data = try? JSONEncoder().encode(macros) else { return }
        try? data.write(to: macrosURL, options: .atomic)
    }
}

public extension Notification.Name {
    static let lexPadMacroCommand = Notification.Name("LexPadMacroCommand")
}
