import LexPadCore
import SwiftUI

struct IncrementalSearchBar: View {
    @Binding var pattern: String
    @Binding var matchCase: Bool
    let matchCount: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Incremental").font(.caption).foregroundStyle(.secondary)
            TextField("Search", text: $pattern)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 180)
                .onSubmit(onNext)
            Toggle("Case", isOn: $matchCase).toggleStyle(.checkbox)
            Text(matchCount == 0 ? "—" : "\(matchCount)")
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
            Button("◀", action: onPrevious)
            Button("▶", action: onNext)
            Button("Close", action: onClose)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

struct ColumnEditorSheet: View {
    @Binding var isPresented: Bool
    @State private var start = 1
    @State private var step = 1
    @State private var padWidth = 0
    let onApply: (Int, Int, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeaderView(title: "Column Editor", onClose: { isPresented = false })
            Stepper("Start: \(start)", value: $start)
            Stepper("Step: \(step)", value: $step, in: -100...100)
            Stepper("Pad width: \(padWidth)", value: $padWidth, in: 0...8)
            Text("Appends numbers to the end of each selected line.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Insert") {
                    onApply(start, step, padWidth)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}

struct GitPanel: View {
    let repoRoot: URL?
    let branch: String?
    let statuses: [GitFileStatus]
    let diffText: String
    let blameText: String
    let commitStatus: String
    let onStage: (String) -> Void
    let onCommit: (String) -> Void
    let onRefresh: () -> Void
    var onOpenRepository: (() -> Void)?
    var onInitRepository: (() -> Void)?
    var onClose: (() -> Void)?

    @State private var commitMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Git", onClose: onClose) {
                Button("Refresh", action: onRefresh)
                    .font(.caption)
            }
            if let branch {
                Text("Branch: \(branch)").font(.caption).padding(.horizontal, 8)
            }
            if let repoRoot {
                Text(repoRoot.lastPathComponent)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }
            if repoRoot == nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Not a git repository")
                        .foregroundStyle(.secondary)
                    if let onOpenRepository {
                        Button("Open Repository…", action: onOpenRepository)
                    }
                    if let onInitRepository {
                        Button("Initialize Repository…", action: onInitRepository)
                    }
                    Text("Open a folder with a .git directory, or initialize git in the current file's folder.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Commit message", text: $commitMessage)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Commit") {
                            onCommit(commitMessage)
                        }
                        .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Spacer()
                    }
                    if !commitStatus.isEmpty {
                        Text(commitStatus)
                            .font(.caption)
                            .foregroundStyle(commitStatus.hasPrefix("✓") ? .green : .secondary)
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

                List(statuses) { item in
                    HStack {
                        Text(item.statusCode).font(.caption.monospaced()).frame(width: 20)
                        Text(item.path).lineLimit(1)
                        Spacer()
                        Button("Stage") { onStage(item.path) }
                            .font(.caption)
                    }
                }
                if !diffText.isEmpty {
                    Text("Diff")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                    ScrollView {
                        Text(diffText)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(height: 100)
                }
                if !blameText.isEmpty {
                    Text("Blame")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                    ScrollView {
                        Text(blameText)
                            .font(.system(.caption2, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(height: 80)
                }
            }
        }
        .frame(minWidth: 200)
    }
}

struct SnippetsPanel: View {
    @ObservedObject var store: SnippetStore
    let onInsert: (Snippet) -> Void
    var onClose: (() -> Void)?

    @State private var editingSnippet: Snippet?
    @State private var isAdding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Snippets", onClose: onClose) {
                Button {
                    editingSnippet = Snippet(id: UUID().uuidString, name: "", body: "")
                    isAdding = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add snippet")
            }
            List(store.snippets) { snippet in
                Button {
                    onInsert(snippet)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snippet.name)
                        if let trigger = snippet.trigger {
                            Text(trigger).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Edit") {
                        editingSnippet = snippet
                        isAdding = false
                    }
                    Button("Insert") { onInsert(snippet) }
                    Divider()
                    Button("Delete", role: .destructive) {
                        store.delete(id: snippet.id)
                    }
                }
            }
        }
        .frame(minWidth: 180)
        .sheet(item: $editingSnippet) { snippet in
            SnippetEditorSheet(
                snippet: snippet,
                isNew: isAdding,
                onSave: { saved in
                    store.upsert(saved)
                    editingSnippet = nil
                },
                onCancel: { editingSnippet = nil }
            )
        }
    }
}

struct SnippetEditorSheet: View {
    @State var snippet: Snippet
    let isNew: Bool
    let onSave: (Snippet) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeaderView(title: isNew ? "New Snippet" : "Edit Snippet", onClose: onCancel)
            TextField("Name", text: $snippet.name)
            TextField("Trigger (optional)", text: Binding(
                get: { snippet.trigger ?? "" },
                set: { snippet.trigger = $0.isEmpty ? nil : $0 }
            ))
            Text("Body").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $snippet.body)
                .font(.system(.body, design: .monospaced))
                .frame(height: 140)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
            Text("Placeholders: ${date}, ${time}")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                Button("Save") {
                    let name = snippet.name.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    var saved = snippet
                    saved.name = name
                    onSave(saved)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(snippet.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420, height: 340)
    }
}

struct PluginManagerPanel: View {
    @ObservedObject var manager: PluginRegistry
    var onClose: (() -> Void)?
    var embeddedInSettings: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !embeddedInSettings {
                PanelHeaderView(title: "Plugins", onClose: onClose) {
                    Button("Rescan") { manager.reloadPlugins() }
                        .font(.caption)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if embeddedInSettings {
                        Text("Install script-based plugins by adding a folder to the LexPad Plugins directory. Each plugin needs a `plugin.json` manifest and a shell script.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    GroupBox("How to add a plugin") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Click Open Plugins Folder below")
                            Text("2. Create a folder, e.g. my-plugin/")
                            Text("3. Add plugin.json and your script (e.g. plugin.sh)")
                            Text("4. Click Rescan and enable the plugin")
                            Text("5. Run it from Tools → Plugins")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox("Example plugin.json") {
                        Text("""
                        {
                          "id": "com.example.my-plugin",
                          "name": "My Plugin",
                          "version": "1.0.0",
                          "description": "Transforms selected text",
                          "entryPoint": "plugin.sh",
                          "script": "plugin.sh",
                          "author": "Your Name"
                        }
                        """)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Button("Open Plugins Folder") { manager.openPluginsFolder() }
                        Button("Rescan") { manager.reloadPlugins() }
                    }

                    Text(manager.pluginsDirectoryPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Installed plugins")
                        .font(.headline)

                    if manager.plugins.isEmpty {
                        Text("No plugins found.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.plugins) { plugin in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plugin.name).font(.body.weight(.semibold))
                                    Text("\(plugin.version) — \(plugin.description)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let author = plugin.author {
                                        Text(author)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { manager.enabledPluginIDs.contains(plugin.id) },
                                    set: { _ in manager.togglePlugin(plugin.id) }
                                ))
                                .labelsHidden()
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                .padding(embeddedInSettings ? 20 : 8)
            }
        }
        .frame(minWidth: 360, minHeight: embeddedInSettings ? 400 : 280)
    }
}

struct StyleConfiguratorView: View {
    @ObservedObject var settings: EditorSettings
    var onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let onClose {
                PanelHeaderView(title: "Style Configurator", onClose: onClose)
            }
            Form {
            Section("Color theme") {
                Picker("Built-in theme", selection: $settings.builtInTheme) {
                    ForEach(BuiltInEditorTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .onChange(of: settings.builtInTheme) { _ in settings.persist() }
            }
            Section("Editor chrome") {
                Picker("Appearance", selection: $settings.theme) {
                    ForEach(EditorTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .onChange(of: settings.theme) { _ in settings.persist() }
                Toggle("Change history margin", isOn: $settings.showChangeHistory)
                    .onChange(of: settings.showChangeHistory) { _ in settings.persist() }
            }
            Section("Large files") {
                Toggle("Enable large-file mode", isOn: $settings.enableLargeFileMode)
                Stepper("Threshold: \(settings.largeFileThresholdMB) MB", value: $settings.largeFileThresholdMB, in: 1...100)
            }
            }
            .formStyle(.grouped)
        }
    }
}
