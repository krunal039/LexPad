import LexPadCore
import SwiftUI

struct PanelHeaderView<Trailing: View>: View {
    let title: String
    var onClose: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, onClose: (() -> Void)? = nil, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.onClose = onClose
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.headline)
            Spacer()
            trailing()
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Close panel")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

struct WorkspacePanel: View {
    @ObservedObject var workspace: WorkspaceStore
    let onOpenFile: (URL) -> Void
    var onClose: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Workspace", onClose: onClose) {
                Button("Open Folder") { openFolder() }
                    .font(.caption)
            }

            TextField("Filter files", text: $workspace.filter)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)

            if let root = workspace.rootURL {
                Text(root.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .lineLimit(1)
            }

            List {
                ForEach(workspace.filteredTree) { node in
                    WorkspaceNodeView(node: node, onOpenFile: onOpenFile)
                }
            }
        }
        .frame(minWidth: 180)
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        workspace.openFolder(url)
    }
}

private struct WorkspaceNodeView: View {
    let node: WorkspaceNode
    let onOpenFile: (URL) -> Void
    @State private var expanded = true

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: $expanded) {
                ForEach(node.children ?? []) { child in
                    WorkspaceNodeView(node: child, onOpenFile: onOpenFile)
                }
            } label: {
                Label(node.name, systemImage: "folder")
            }
        } else {
            Button {
                onOpenFile(node.url)
            } label: {
                Label(node.name, systemImage: "doc.text")
            }
            .buttonStyle(.plain)
        }
    }
}

struct FunctionListPanel: View {
    let document: TextDocument?
    let onGoToSymbol: (Int) -> Void
    var onInsertStub: (() -> Void)?
    var onClose: (() -> Void)?

    private var symbols: [DocumentSymbol] {
        guard let document else { return [] }
        return SymbolParser.parse(in: document.text, language: document.language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Function List", onClose: onClose) {
                if let onInsertStub {
                    Button("Add") { onInsertStub() }
                        .font(.caption)
                }
            }
            if symbols.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No symbols found")
                        .foregroundStyle(.secondary)
                    Text("Type code with functions/classes, or use Add to insert a stub.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                Spacer()
            } else {
                List(symbols) { symbol in
                    Button {
                        onGoToSymbol(symbol.line)
                    } label: {
                        HStack {
                            Image(systemName: icon(for: symbol.kind))
                                .foregroundStyle(.secondary)
                            Text(symbol.name)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text("\(symbol.line)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(minWidth: 180)
    }

    private func icon(for kind: SymbolKind) -> String {
        switch kind {
        case .function, .method: return "f.cursive"
        case .class: return "c.square"
        case .structKind: return "s.square"
        case .interface: return "i.square"
        default: return "chevron.left.forwardslash.chevron.right"
        }
    }
}

struct ShortcutMapperView: View {
    @ObservedObject var shortcuts: ShortcutSettings
    @State private var captureMonitor: Any?

    var body: some View {
        Form {
            Section("Preset") {
                Picker("Keyboard scheme", selection: $shortcuts.preset) {
                    ForEach(ShortcutPreset.allCases, id: \.self) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .onChange(of: shortcuts.preset) { _ in shortcuts.persist() }
                if shortcuts.preset == .notepadPlusPlus {
                    Toggle("Map Ctrl shortcuts to LexPad commands", isOn: $shortcuts.enableNPPKeyMonitor)
                        .onChange(of: shortcuts.enableNPPKeyMonitor) { _ in shortcuts.persist() }
                    Text("Uses Ctrl instead of Cmd for common editing shortcuts (Find, Replace, Go to Line, etc.).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Shortcuts") {
                ForEach(ShortcutSettings.bindings) { binding in
                    HStack {
                        Text(binding.title)
                        Spacer()
                        if shortcuts.recordingBindingID == binding.id {
                            Text("Press new shortcut…")
                                .foregroundStyle(.orange)
                        } else {
                            Text(shortcuts.label(for: binding))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Button(shortcuts.overrides[binding.id] == nil ? "Change" : "Reset") {
                            if shortcuts.overrides[binding.id] != nil {
                                shortcuts.setOverride(nil, for: binding.id)
                            } else {
                                startRecording(bindingID: binding.id)
                            }
                        }
                    }
                }
            }
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording(bindingID: String) {
        stopRecording()
        shortcuts.recordingBindingID = bindingID
        captureMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                stopRecording()
                return nil
            }
            let spec = ShortcutKeySpec(keyCode: event.keyCode, modifiers: event.modifierFlags)
            shortcuts.setOverride(spec, for: bindingID)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let captureMonitor { NSEvent.removeMonitor(captureMonitor) }
        captureMonitor = nil
        shortcuts.recordingBindingID = nil
    }
}

struct DocumentListPanel: View {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var tabGroups: TabGroupStore
    let onActivate: (UUID) -> Void
    let onClose: (UUID) -> Void
    var onClosePanel: (() -> Void)?

    @State private var editingGroup: TabGroup?

    private var sections: [TabGroupSection] {
        tabGroups.sections(for: collection.documents)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Document List", onClose: onClosePanel) {
                Menu {
                    Picker("Group by", selection: $tabGroups.mode) {
                        ForEach(TabGroupingMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    Divider()
                    Button("New Tab Group") { createGroup() }
                    if tabGroups.mode == .byGroup, !tabGroups.groups.isEmpty {
                        Divider()
                        Menu("Edit Groups") {
                            ForEach(tabGroups.groups) { group in
                                Button(group.name) { editingGroup = group }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }
            .onChange(of: tabGroups.mode) { _ in tabGroups.persist() }

            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.documentIDs, id: \.self) { docID in
                            if let doc = collection.document(for: docID) {
                                DocumentListRow(
                                    document: doc,
                                    isActive: collection.activeDocumentID == docID,
                                    groupColorIndex: section.colorIndex ?? tabGroups.group(for: docID)?.colorIndex,
                                    onActivate: { onActivate(docID) },
                                    onClose: { onClose(docID) },
                                    tabGroups: tabGroups,
                                    documentID: docID
                                )
                            }
                        }
                    } header: {
                        if let groupID = UUID(uuidString: section.id), let group = tabGroups.groups.first(where: { $0.id == groupID }) {
                            Button {
                                editingGroup = group
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(TabGroupColor.color(at: group.colorIndex))
                                        .frame(width: 8, height: 8)
                                    Text(section.title)
                                    Spacer()
                                    Image(systemName: "pencil")
                                        .font(.caption2)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(section.title)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 180)
        .sheet(item: $editingGroup) { group in
            TabGroupEditorSheet(group: group, tabGroups: tabGroups)
        }
    }

    private func createGroup() {
        if let id = collection.activeDocumentID {
            _ = tabGroups.createGroup(documentIDs: [id])
        } else {
            _ = tabGroups.createGroup()
        }
        tabGroups.mode = .byGroup
        tabGroups.persist()
    }
}

struct TabGroupEditorSheet: View {
    @State var group: TabGroup
    @ObservedObject var tabGroups: TabGroupStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeaderView(title: "Edit Tab Group", onClose: { dismiss() })
            TextField("Name", text: $group.name)
            Text("Color").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(0..<TabGroup.palette.count, id: \.self) { index in
                    Circle()
                        .fill(TabGroupColor.color(at: index))
                        .frame(width: 22, height: 22)
                        .overlay {
                            if group.colorIndex == index {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture { group.colorIndex = index }
                }
            }
            HStack {
                Button("Delete Group", role: .destructive) {
                    tabGroups.deleteGroup(id: group.id)
                    dismiss()
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    tabGroups.updateGroup(id: group.id, name: group.name, colorIndex: group.colorIndex)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

private struct DocumentListRow: View {
    let document: TextDocument
    let isActive: Bool
    let groupColorIndex: Int?
    let onActivate: () -> Void
    let onClose: () -> Void
    @ObservedObject var tabGroups: TabGroupStore
    let documentID: UUID

    var body: some View {
        HStack(spacing: 6) {
            if let groupColorIndex {
                RoundedRectangle(cornerRadius: 2)
                    .fill(TabGroupColor.color(at: groupColorIndex))
                    .frame(width: 4, height: 18)
            }
            Button(action: onActivate) {
                Text(document.displayName)
                    .lineLimit(1)
                    .fontWeight(isActive ? .semibold : .regular)
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .contextMenu {
            if !tabGroups.groups.isEmpty {
                Menu("Assign to Group") {
                    ForEach(tabGroups.groups) { group in
                        Button {
                            tabGroups.addDocument(documentID, to: group.id)
                            tabGroups.mode = .byGroup
                            tabGroups.persist()
                        } label: {
                            Label(group.name, systemImage: "circle.fill")
                        }
                    }
                    Divider()
                    Button("Remove from Group") {
                        tabGroups.removeDocument(documentID)
                    }
                }
            }
            Button("New Group with Tab") {
                _ = tabGroups.createGroup(documentIDs: [documentID])
                tabGroups.mode = .byGroup
                tabGroups.persist()
            }
        }
    }
}

enum TabGroupColor {
    static func color(at index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
        return colors[index % colors.count]
    }
}

struct DocumentMapPanel: View {
    let document: TextDocument?
    let visibleLine: Int
    let onGoToLine: (Int) -> Void
    var onClose: (() -> Void)?

    private var lines: [String] {
        guard let document else { return [] }
        return document.text.components(separatedBy: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Document Map", onClose: onClose)
            GeometryReader { geo in
                Canvas { context, size in
                    let count = max(lines.count, 1)
                    let lineHeight = size.height / CGFloat(count)
                    let maxLen = max(lines.map(\.count).max() ?? 1, 1)
                    for (index, line) in lines.enumerated() {
                        let width = size.width * CGFloat(line.count) / CGFloat(maxLen)
                        let rect = CGRect(x: 0, y: CGFloat(index) * lineHeight, width: max(width, 1), height: max(lineHeight, 0.5))
                        context.fill(Path(rect), with: .color(.secondary.opacity(0.45)))
                    }
                    let viewportLines = 24.0
                    let top = CGFloat(max(visibleLine - 1, 0)) / CGFloat(count) * size.height
                    let viewRect = CGRect(x: 0, y: top, width: size.width, height: size.height * viewportLines / CGFloat(count))
                    context.stroke(Path(viewRect), with: .color(.accentColor), lineWidth: 1)
                }
                .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let count = max(lines.count, 1)
                            let line = min(max(Int(value.location.y / geo.size.height * CGFloat(count)) + 1, 1), count)
                            onGoToLine(line)
                        }
                )
            }
        }
        .frame(minWidth: 60)
    }
}
