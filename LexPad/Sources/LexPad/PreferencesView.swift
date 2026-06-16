import LexPadCore
import SwiftUI

private enum PreferencesPane: String, CaseIterable, Identifiable {
    case editor
    case appearance
    case shortcuts
    case languages
    case plugins

    var id: String { rawValue }

    var title: String {
        switch self {
        case .editor: return "Editor"
        case .appearance: return "Appearance"
        case .shortcuts: return "Shortcuts"
        case .languages: return "Languages"
        case .plugins: return "Plugins"
        }
    }

    var systemImage: String {
        switch self {
        case .editor: return "textformat"
        case .appearance: return "paintpalette"
        case .shortcuts: return "keyboard"
        case .languages: return "curlybraces"
        case .plugins: return "puzzlepiece.extension"
        }
    }
}

/// Consistent padding and width for every settings detail pane.
private struct SettingsPaneLayout<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
    }
}

struct PreferencesView: View {
    @ObservedObject var settings: EditorSettings
    @ObservedObject var shortcuts: ShortcutSettings
    @ObservedObject var userLanguageStore: UserLanguageStore
    var pluginRegistry: PluginRegistry?
    @State private var pane: PreferencesPane? = .editor

    private var visiblePanes: [PreferencesPane] {
        PreferencesPane.allCases.filter { $0 != .plugins || pluginRegistry != nil }
    }

    var body: some View {
        NavigationSplitView {
            List(visiblePanes, selection: $pane) { item in
                Label(item.title, systemImage: item.systemImage)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .lexPadThemedList()
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .lexPadPanelBackground()
                .navigationTitle(pane?.title ?? "Settings")
        }
        .lexPadWindowBackground()
        .frame(minWidth: 780, minHeight: 540)
        .onDisappear {
            settings.persist()
            shortcuts.persist()
        }
        .onAppear {
            if pane == .plugins && pluginRegistry == nil {
                pane = .editor
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch pane ?? .editor {
        case .editor:
            SettingsPaneLayout { editorTab }
        case .appearance:
            SettingsPaneLayout {
                StyleConfiguratorView(settings: settings)
            }
        case .shortcuts:
            SettingsPaneLayout {
                ShortcutMapperView(shortcuts: shortcuts)
            }
        case .languages:
            SettingsPaneLayout {
                UserLanguagesPreferencesView(store: userLanguageStore)
            }
        case .plugins:
            if let pluginRegistry {
                PluginManagerPanel(manager: pluginRegistry, embeddedInSettings: true)
            } else {
                Text("Plugins unavailable")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var editorTab: some View {
        Form {
            Section("Editor") {
                HStack {
                    Text("Font size")
                    Slider(value: $settings.fontSize, in: 9...28, step: 1)
                    Text("\(Int(settings.fontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }
                Stepper("Tab size: \(settings.tabSize)", value: $settings.tabSize, in: 2...8)
                Toggle("Use spaces for tab", isOn: $settings.useSpacesForTab)
                Toggle("Word wrap", isOn: $settings.wordWrap)
                Toggle("Line numbers", isOn: $settings.showLineNumbers)
                Toggle("Code folding", isOn: $settings.codeFolding)
                Toggle("Auto-completion", isOn: $settings.enableAutoCompletion)
                Stepper("Auto-complete after \(settings.autoCompletionMinLength) chars", value: $settings.autoCompletionMinLength, in: 2...8)
                Toggle("Virtual space (click/type beyond line end)", isOn: $settings.virtualSpace)
                Toggle("Snippet auto-expand on type", isOn: $settings.enableSnippetTriggers)
                Toggle("Brace matching", isOn: $settings.enableBraceMatching)
                Toggle("Smart highlight (word under caret)", isOn: $settings.enableSmartHighlight)
                Toggle("Spell check", isOn: $settings.enableSpellCheck)
                Toggle("Function calltips", isOn: $settings.enableCalltips)
                Picker("Tab bar", selection: $settings.tabBarStyle) {
                    ForEach(TabBarStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            }
            Section("Paths") {
                TextField("Cloud sync folder (optional)", text: $settings.cloudSyncPath)
                TextField("Custom session file path (optional)", text: $settings.customSessionPath)
                Text("Leave blank to use default Application Support locations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Appearance") {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(EditorTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }
            Section("Session") {
                Toggle("Restore tabs on launch", isOn: $settings.restoreSession)
                Text("Saves open tabs, untitled drafts, caret positions, tab groups, and split layout.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Autosave open files", isOn: $settings.enableAutosave)
            }
            Section("History") {
                Text("\(RecentFilesStore.loadEntries().count) files in open history (max 50)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Clear Open History") {
                    RecentFilesStore.clear()
                }
            }
        }
        .formStyle(.grouped)
        .lexPadThemedForm()
    }
}

struct SettingsNotificationsModifier: ViewModifier {
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadShowPreferences)) { _ in
                openWindow(id: "settings")
            }
    }
}

extension View {
    func settingsNotifications() -> some View {
        modifier(SettingsNotificationsModifier())
    }
}
