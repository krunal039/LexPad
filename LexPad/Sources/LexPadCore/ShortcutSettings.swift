import AppKit
import Foundation
import SwiftUI

public enum ShortcutPreset: String, CaseIterable, Sendable {
    case macOS
    case notepadPlusPlus

    public var displayName: String {
        switch self {
        case .macOS: return "macOS Standard"
        case .notepadPlusPlus: return "Notepad++ Compatible"
        }
    }
}

public struct ShortcutBinding: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let category: String
    public let notificationName: String
    public let macModifiers: [String]
    public let macKey: String
    public let nppModifiers: [String]
    public let nppKey: String

    public func label(for preset: ShortcutPreset) -> String {
        let mods = preset == .macOS ? macModifiers : nppModifiers
        let key = preset == .macOS ? macKey : nppKey
        let modStr = mods.map { $0 }.joined()
        return modStr.isEmpty ? key : modStr + key
    }

    public var notification: Notification.Name {
        Notification.Name(notificationName)
    }
}

public struct ShortcutKeySpec: Codable, Sendable, Hashable {
    public var keyCode: UInt16
    public var modifiers: UInt

    public init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers.rawValue
    }

    public var eventModifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    public var displayLabel: String {
        var parts: [String] = []
        let flags = eventModifiers
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        if let char = KeyCodeTranslator.character(for: keyCode, modifiers: flags) {
            parts.append(char)
        } else {
            parts.append("Key\(keyCode)")
        }
        return parts.joined()
    }
}

enum KeyCodeTranslator {
    static func character(for keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String? {
        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: keyCode
        ) else { return nil }
        let chars = event.charactersIgnoringModifiers?.uppercased()
        return chars?.isEmpty == false ? chars : nil
    }
}

@MainActor
public final class ShortcutSettings: ObservableObject {
    @Published public var preset: ShortcutPreset = .macOS
    @Published public var enableNPPKeyMonitor = true
    @Published public var overrides: [String: ShortcutKeySpec] = [:]
    @Published public var recordingBindingID: String?

    private var monitor: Any?

    public static let bindings: [ShortcutBinding] = [
        ShortcutBinding(id: "find", title: "Find", category: "Search", notificationName: "LexPadToggleFind", macModifiers: ["⌘"], macKey: "F", nppModifiers: ["⌃"], nppKey: "F"),
        ShortcutBinding(id: "replace", title: "Replace", category: "Search", notificationName: "LexPadToggleReplace", macModifiers: ["⌘⌥"], macKey: "F", nppModifiers: ["⌃"], nppKey: "H"),
        ShortcutBinding(id: "findInFiles", title: "Find in Files", category: "Search", notificationName: "LexPadFindInFiles", macModifiers: ["⌘⇧"], macKey: "F", nppModifiers: ["⌃⇧"], nppKey: "F"),
        ShortcutBinding(id: "gotoLine", title: "Go to Line", category: "Navigation", notificationName: "LexPadGoToLine", macModifiers: ["⌘"], macKey: "L", nppModifiers: ["⌃"], nppKey: "G"),
        ShortcutBinding(id: "quickOpen", title: "Quick Open", category: "Navigation", notificationName: "LexPadQuickOpen", macModifiers: ["⌘"], macKey: "P", nppModifiers: ["⌃"], nppKey: "P"),
        ShortcutBinding(id: "newTab", title: "New Tab", category: "File", notificationName: "LexPadNewTab", macModifiers: ["⌘"], macKey: "T", nppModifiers: ["⌃"], nppKey: "N"),
        ShortcutBinding(id: "save", title: "Save", category: "File", notificationName: "LexPadSave", macModifiers: ["⌘"], macKey: "S", nppModifiers: ["⌃"], nppKey: "S"),
        ShortcutBinding(id: "palette", title: "Command Palette", category: "LexPad", notificationName: "LexPadCommandPalette", macModifiers: ["⌘⇧"], macKey: "P", nppModifiers: ["⌃⇧"], nppKey: "P"),
        ShortcutBinding(id: "toggleComment", title: "Toggle Comment", category: "Editing", notificationName: "LexPadToggleComment", macModifiers: ["⌘"], macKey: "/", nppModifiers: ["⌃"], nppKey: "Q"),
        ShortcutBinding(id: "toggleBookmark", title: "Toggle Bookmark", category: "Navigation", notificationName: "LexPadToggleBookmark", macModifiers: [], macKey: "F2", nppModifiers: [], nppKey: "F2"),
        ShortcutBinding(id: "selectNext", title: "Add Next Occurrence", category: "Editing", notificationName: "LexPadSelectNextOccurrence", macModifiers: ["⌘⌃"], macKey: "D", nppModifiers: ["⌃"], nppKey: "D"),
        ShortcutBinding(id: "incremental", title: "Incremental Search", category: "Search", notificationName: "LexPadIncrementalSearch", macModifiers: ["⌘"], macKey: "E", nppModifiers: ["⌃"], nppKey: "E"),
        ShortcutBinding(id: "completion", title: "Show Completions", category: "Editing", notificationName: "LexPadTriggerCompletion", macModifiers: ["⌃"], macKey: "Space", nppModifiers: ["⌃"], nppKey: "Space"),
    ]

    public init() {
        if let raw = UserDefaults.standard.string(forKey: "shortcutPreset"),
           let p = ShortcutPreset(rawValue: raw) {
            preset = p
        }
        enableNPPKeyMonitor = UserDefaults.standard.object(forKey: "enableNPPKeyMonitor") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: "shortcutOverrides"),
           let decoded = try? JSONDecoder().decode([String: ShortcutKeySpec].self, from: data) {
            overrides = decoded
        }
        installMonitorIfNeeded()
    }

    public func persist() {
        UserDefaults.standard.set(preset.rawValue, forKey: "shortcutPreset")
        UserDefaults.standard.set(enableNPPKeyMonitor, forKey: "enableNPPKeyMonitor")
        if let data = try? JSONEncoder().encode(overrides) {
            UserDefaults.standard.set(data, forKey: "shortcutOverrides")
        }
        installMonitorIfNeeded()
    }

    public func label(for binding: ShortcutBinding) -> String {
        if let override = overrides[binding.id] {
            return override.displayLabel
        }
        return binding.label(for: preset)
    }

    public func label(for notification: Notification.Name) -> String? {
        guard let binding = Self.bindings.first(where: { $0.notification == notification }) else { return nil }
        return label(for: binding)
    }

    public func setOverride(_ spec: ShortcutKeySpec?, for bindingID: String) {
        if let spec {
            overrides[bindingID] = spec
        } else {
            overrides.removeValue(forKey: bindingID)
        }
        persist()
    }

    private func installMonitorIfNeeded() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        self.monitor = nil
        guard enableNPPKeyMonitor || !overrides.isEmpty || preset == .notepadPlusPlus else { return }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if self.handleCustomOverride(event) { return nil }
            if self.preset == .notepadPlusPlus, self.handleNPPKey(event) { return nil }
            return event
        }
    }

    private func handleCustomOverride(_ event: NSEvent) -> Bool {
        for binding in Self.bindings {
            guard let spec = overrides[binding.id] else { continue }
            if event.keyCode == spec.keyCode
                && event.modifierFlags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask)
                    == spec.eventModifiers.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask) {
                postMacroCommand(binding.notification)
                return true
            }
        }
        return false
    }

    private func handleNPPKey(_ event: NSEvent) -> Bool {
        guard preset == .notepadPlusPlus else { return false }
        guard event.modifierFlags.contains(.control),
              !event.modifierFlags.contains(.command) else { return false }
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        let shift = event.modifierFlags.contains(.shift)

        for binding in Self.bindings where overrides[binding.id] == nil {
            let nppKey = binding.nppKey.lowercased()
            let needsShift = binding.nppModifiers.contains("⇧")
            if key == nppKey.lowercased() && shift == needsShift {
                postMacroCommand(binding.notification)
                return true
            }
        }
        return false
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }
}
