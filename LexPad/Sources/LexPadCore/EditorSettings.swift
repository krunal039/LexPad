import Foundation
import SwiftUI

public enum TabBarStyle: String, CaseIterable, Sendable, Identifiable {
    case horizontal
    case vertical
    case multiLine

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical (left)"
        case .multiLine: return "Multi-line"
        }
    }
}

public enum EditorTheme: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@MainActor
public final class EditorSettings: ObservableObject {
    @Published public var wordWrap = true
    @Published public var showLineNumbers = true
    @Published public var fontSize: Double = 13
    @Published public var tabSize = 4
    @Published public var useSpacesForTab = true
    @Published public var codeFolding = true
    @Published public var theme: EditorTheme = .system
    @Published public var restoreSession = true
    @Published public var activeMarkStyle: MarkStyle = .style3
    @Published public var builtInTheme: BuiltInEditorTheme = .classic
    @Published public var showChangeHistory = true
    @Published public var largeFileThresholdMB: Int = 5
    @Published public var enableLargeFileMode = true
    @Published public var enableAutoCompletion = true
    @Published public var autoCompletionMinLength = 3
    @Published public var enableAutosave = true
    @Published public var autosaveIntervalSeconds = 60
    @Published public var virtualSpace = false
    @Published public var enableSnippetTriggers = true
    @Published public var tabBarStyle: TabBarStyle = .horizontal
    @Published public var enableBraceMatching = true
    @Published public var enableSmartHighlight = true
    @Published public var enableSpellCheck = false
    @Published public var enableCalltips = true
    @Published public var cloudSyncPath: String = ""
    @Published public var customSessionPath: String = ""

    public init() {
        let d = UserDefaults.standard
        wordWrap = d.object(forKey: "wordWrap") as? Bool ?? true
        showLineNumbers = d.object(forKey: "showLineNumbers") as? Bool ?? true
        fontSize = d.object(forKey: "fontSize") as? Double ?? 13
        tabSize = d.object(forKey: "tabSize") as? Int ?? 4
        useSpacesForTab = d.object(forKey: "useSpacesForTab") as? Bool ?? true
        codeFolding = d.object(forKey: "codeFolding") as? Bool ?? true
        restoreSession = d.object(forKey: "restoreSession") as? Bool ?? true
        if let raw = d.string(forKey: "theme"), let t = EditorTheme(rawValue: raw) {
            theme = t
        }
        if let mark = d.object(forKey: "activeMarkStyle") as? Int,
           let style = MarkStyle(rawValue: mark) {
            activeMarkStyle = style
        }
        if let raw = d.string(forKey: "builtInTheme"), let t = BuiltInEditorTheme(rawValue: raw) {
            builtInTheme = t
        }
        showChangeHistory = d.object(forKey: "showChangeHistory") as? Bool ?? true
        largeFileThresholdMB = d.object(forKey: "largeFileThresholdMB") as? Int ?? 5
        enableLargeFileMode = d.object(forKey: "enableLargeFileMode") as? Bool ?? true
        enableAutoCompletion = d.object(forKey: "enableAutoCompletion") as? Bool ?? true
        autoCompletionMinLength = d.object(forKey: "autoCompletionMinLength") as? Int ?? 3
        enableAutosave = d.object(forKey: "enableAutosave") as? Bool ?? true
        autosaveIntervalSeconds = d.object(forKey: "autosaveIntervalSeconds") as? Int ?? 60
        virtualSpace = d.object(forKey: "virtualSpace") as? Bool ?? false
        enableSnippetTriggers = d.object(forKey: "enableSnippetTriggers") as? Bool ?? true
        if let raw = d.string(forKey: "tabBarStyle"), let style = TabBarStyle(rawValue: raw) {
            tabBarStyle = style
        }
        enableBraceMatching = d.object(forKey: "enableBraceMatching") as? Bool ?? true
        enableSmartHighlight = d.object(forKey: "enableSmartHighlight") as? Bool ?? true
        enableSpellCheck = d.object(forKey: "enableSpellCheck") as? Bool ?? false
        enableCalltips = d.object(forKey: "enableCalltips") as? Bool ?? true
        cloudSyncPath = d.string(forKey: "cloudSyncPath") ?? ""
        customSessionPath = d.string(forKey: "customSessionPath") ?? ""
    }

    public func persist() {
        let d = UserDefaults.standard
        d.set(wordWrap, forKey: "wordWrap")
        d.set(showLineNumbers, forKey: "showLineNumbers")
        d.set(fontSize, forKey: "fontSize")
        d.set(tabSize, forKey: "tabSize")
        d.set(useSpacesForTab, forKey: "useSpacesForTab")
        d.set(codeFolding, forKey: "codeFolding")
        d.set(restoreSession, forKey: "restoreSession")
        d.set(theme.rawValue, forKey: "theme")
        d.set(activeMarkStyle.rawValue, forKey: "activeMarkStyle")
        d.set(builtInTheme.rawValue, forKey: "builtInTheme")
        d.set(showChangeHistory, forKey: "showChangeHistory")
        d.set(largeFileThresholdMB, forKey: "largeFileThresholdMB")
        d.set(enableLargeFileMode, forKey: "enableLargeFileMode")
        d.set(enableAutoCompletion, forKey: "enableAutoCompletion")
        d.set(autoCompletionMinLength, forKey: "autoCompletionMinLength")
        d.set(enableAutosave, forKey: "enableAutosave")
        d.set(autosaveIntervalSeconds, forKey: "autosaveIntervalSeconds")
        d.set(virtualSpace, forKey: "virtualSpace")
        d.set(enableSnippetTriggers, forKey: "enableSnippetTriggers")
        d.set(tabBarStyle.rawValue, forKey: "tabBarStyle")
        d.set(enableBraceMatching, forKey: "enableBraceMatching")
        d.set(enableSmartHighlight, forKey: "enableSmartHighlight")
        d.set(enableSpellCheck, forKey: "enableSpellCheck")
        d.set(enableCalltips, forKey: "enableCalltips")
        d.set(cloudSyncPath, forKey: "cloudSyncPath")
        d.set(customSessionPath, forKey: "customSessionPath")
    }

    public var prefersDarkMode: Bool? {
        chromeIsDark
    }

    /// Whether sidebars, toolbars, and sheets use a dark palette.
    public var chromeIsDark: Bool {
        switch theme {
        case .system: return builtInTheme.isDark
        case .light: return false
        case .dark: return true
        }
    }

    /// SwiftUI control appearance; kept in sync with chrome brightness.
    public var resolvedColorScheme: ColorScheme? {
        chromeIsDark ? .dark : .light
    }
}
