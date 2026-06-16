import AppKit
import LexPadCore
import SwiftUI

struct FindInFilesPanel: View {
    @Binding var isPresented: Bool
    @Binding var pattern: String
    @Binding var isRegex: Bool
    @Binding var matchCase: Bool
    @Binding var directory: URL?
    @Binding var fileFilter: String
    @Binding var results: [FindInFilesResult]
    @Binding var isSearching: Bool
    let onOpenResult: (FindInFilesResult) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelHeaderView(title: "Find in Files", onClose: { isPresented = false })

            HStack {
                TextField("Find", text: $pattern)
                    .textFieldStyle(.roundedBorder)
                Toggle("Regex", isOn: $isRegex).toggleStyle(.checkbox)
                Toggle("Match case", isOn: $matchCase).toggleStyle(.checkbox)
                Button("Browse…") { pickDirectory() }
                Button(isSearching ? "Searching…" : "Find All") { runSearch() }
                    .disabled(pattern.isEmpty || directory == nil || isSearching)
            }

            HStack {
                TextField("Directory", text: Binding(
                    get: { directory?.path ?? "" },
                    set: { _ in }
                ))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
                TextField("Filter (*.txt;*.swift)", text: $fileFilter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
            }

            List(results) { result in
                Button {
                    onOpenResult(result)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(result.fileURL.lastPathComponent):\(result.line):\(result.column)")
                            .font(.caption.weight(.semibold))
                        Text(result.lineText)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
            .lexPadThemedList()
        }
        .padding(12)
        .lexPadSheetContainer()
        .frame(minWidth: 640, minHeight: 360)
    }

    private func pickDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK else { return }
        directory = panel.url
    }

    private func runSearch() {
        guard let directory, !pattern.isEmpty else { return }
        isSearching = true
        let opts = FindOptions(pattern: pattern, isRegex: isRegex, matchCase: matchCase)
        Task {
            let found = (try? FindInFilesEngine.search(
                directory: directory,
                pattern: pattern,
                options: opts,
                fileFilter: fileFilter
            )) ?? []
            await MainActor.run {
                results = found
                isSearching = false
            }
        }
    }
}

struct ReplaceInFilesPanel: View {
    @Binding var isPresented: Bool
    @Binding var pattern: String
    @Binding var replacement: String
    @Binding var isRegex: Bool
    @Binding var matchCase: Bool
    @Binding var directory: URL?
    @Binding var fileFilter: String
    @Binding var status: String
    @Binding var isSearching: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelHeaderView(title: "Replace in Files", onClose: { isPresented = false })

            HStack {
                TextField("Find", text: $pattern).textFieldStyle(.roundedBorder)
                TextField("Replace with", text: $replacement).textFieldStyle(.roundedBorder)
            }
            HStack {
                Toggle("Regex", isOn: $isRegex).toggleStyle(.checkbox)
                Toggle("Match case", isOn: $matchCase).toggleStyle(.checkbox)
                Button("Browse…") { pickDirectory() }
                Button(isSearching ? "Replacing…" : "Replace All in Files") { runReplace() }
                    .disabled(pattern.isEmpty || directory == nil || isSearching)
            }
            HStack {
                TextField("Directory", text: Binding(get: { directory?.path ?? "" }, set: { _ in }))
                    .textFieldStyle(.roundedBorder).disabled(true)
                TextField("Filter", text: $fileFilter).textFieldStyle(.roundedBorder).frame(width: 180)
            }
            if !status.isEmpty {
                Text(status).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .lexPadSheetContainer()
        .frame(minWidth: 640, minHeight: 280)
    }

    private func pickDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        guard panel.runModal() == .OK else { return }
        directory = panel.url
    }

    private func runReplace() {
        guard let directory, !pattern.isEmpty else { return }
        isSearching = true
        status = ""
        let opts = FindOptions(pattern: pattern, isRegex: isRegex, matchCase: matchCase)
        Task {
            let result = (try? ReplaceInFilesEngine.replace(
                directory: directory,
                pattern: pattern,
                replacement: replacement,
                options: opts,
                fileFilter: fileFilter
            )) ?? ReplaceInFilesResult(filesModified: 0, replacements: 0, skipped: 0)
            await MainActor.run {
                status = "Modified \(result.filesModified) files, \(result.replacements) replacements, \(result.skipped) skipped"
                isSearching = false
            }
        }
    }
}

struct DiffCompareView: View {
    let leftTitle: String
    let rightTitle: String
    let diffLines: [DiffLine]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            PanelHeaderView(title: "Compare: \(leftTitle) ↔ \(rightTitle)", onClose: { dismiss() })

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(diffLines) { line in
                        HStack(spacing: 8) {
                            Text(lineNumberLabel(line))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 72, alignment: .trailing)
                            Text(prefix(for: line.kind) + line.text)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 1)
                        .padding(.horizontal, 8)
                        .background(background(for: line.kind))
                    }
                }
            }
            .lexPadThemedList()
        }
        .lexPadSheetContainer()
        .frame(minWidth: 800, minHeight: 500)
    }

    private func lineNumberLabel(_ line: DiffLine) -> String {
        switch line.kind {
        case .unchanged: return "\(line.leftLineNumber ?? 0)"
        case .removed: return "\(line.leftLineNumber ?? 0)"
        case .added: return "+\(line.rightLineNumber ?? 0)"
        }
    }

    private func prefix(for kind: DiffLineKind) -> String {
        switch kind {
        case .unchanged: return "  "
        case .added: return "+ "
        case .removed: return "- "
        }
    }

    private func background(for kind: DiffLineKind) -> Color {
        switch kind {
        case .unchanged: return .clear
        case .added: return Color.green.opacity(0.15)
        case .removed: return Color.red.opacity(0.15)
        }
    }
}

struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    @State private var query = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            PanelHeaderView(title: "Command Palette", onClose: { isPresented = false })
            TextField("Type a command…", text: $query)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .onSubmit { runFirst() }

            List(filtered) { command in
                Button {
                    execute(command)
                } label: {
                    HStack {
                        Text(command.title)
                        Spacer()
                        Text(command.category).foregroundStyle(.secondary).font(.caption)
                        if let shortcut = command.shortcut {
                            Text(shortcut).foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .lexPadThemedList()
        }
        .lexPadSheetContainer()
        .frame(width: 520, height: 360)
        .onAppear { focused = true }
    }

    private var filtered: [AppCommand] {
        AppCommands.filter(query)
    }

    private func runFirst() {
        if let first = filtered.first { execute(first) }
    }

    private func execute(_ command: AppCommand) {
        isPresented = false
        postMacroCommand(command.notificationName)
    }
}

struct QuickOpenView: View {
    @ObservedObject var collection: DocumentCollection
    @Binding var isPresented: Bool
    @State private var query = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            PanelHeaderView(title: "Quick Open", onClose: { isPresented = false })
            TextField("Open file…", text: $query)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .onSubmit { openFirst() }

            List(filtered) { item in
                Button {
                    open(item.url)
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.url.lastPathComponent)
                        Text(item.url.deletingLastPathComponent().path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .lexPadThemedList()
        }
        .lexPadSheetContainer()
        .frame(width: 520, height: 360)
        .onAppear { focused = true }
    }

    private struct QuickItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private var filtered: [QuickItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        var items: [QuickItem] = collection.recentFileEntries.map { QuickItem(url: $0.url) }
        if !q.isEmpty {
            items = items.filter { $0.url.lastPathComponent.lowercased().contains(q) }
        }
        return items
    }

    private func openFirst() {
        if let first = filtered.first { open(first.url) }
    }

    private func open(_ url: URL) {
        isPresented = false
        try? collection.open(url: url)
    }
}

struct MacroPanelView: View {
    @Binding var isPresented: Bool
    @ObservedObject var recorder: MacroRecorder
    @State private var macroName = "Macro \(Date().formatted(date: .omitted, time: .shortened))"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Macros", onClose: { isPresented = false }) {
                if recorder.isRecording {
                    Text("● Recording").foregroundStyle(.red).font(.caption)
                    TextField("Name", text: $macroName).frame(width: 140)
                    Button("Stop") { recorder.stopRecording(name: macroName) }
                        .font(.caption)
                } else {
                    Button("Record") { recorder.startRecording() }
                        .font(.caption)
                }
            }

            List(recorder.macros) { macro in
                HStack {
                    Text(macro.name)
                    Spacer()
                    Button("Play") { recorder.play(macro) }
                    Button("Delete") { recorder.delete(macro) }
                }
            }
            .lexPadThemedList()
            .padding(.horizontal, 4)
        }
        .lexPadSheetContainer()
        .frame(width: 420, height: 280)
    }
}
