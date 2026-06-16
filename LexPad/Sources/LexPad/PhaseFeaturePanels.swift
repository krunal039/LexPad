import LexPadCore
import SwiftUI

struct RecentFilesPanel: View {
    @ObservedObject var collection: DocumentCollection
    let onOpen: (URL) -> Void
    var onClose: (() -> Void)?

    private var entries: [RecentFileEntry] {
        collection.recentFileEntries.sorted {
            if $0.pinned != $1.pinned { return $0.pinned }
            return $0.lastOpened > $1.lastOpened
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Recent Files", onClose: onClose) {
                Button("Clear") { collection.clearRecentFiles() }
                    .font(.caption)
            }
            if entries.isEmpty {
                Text("No recent files yet.")
                    .foregroundStyle(.secondary)
                    .padding(8)
                Spacer()
            } else {
                List(entries) { entry in
                    Button {
                        onOpen(entry.url)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.url.lastPathComponent)
                                .lineLimit(1)
                            HStack {
                                Text(entry.url.deletingLastPathComponent().path)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(entry.lastOpened, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Open") { onOpen(entry.url) }
                        Button("Remove from History", role: .destructive) {
                            collection.removeFromRecentFiles(path: entry.path)
                        }
                        Button(entry.pinned ? "Unpin" : "Pin") {
                            collection.togglePinRecentFile(path: entry.path)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 200)
        .accessibilityLabel("Recent files history")
    }
}

struct CharacterInsertPanel: View {
    let onInsert: (String) -> Void
    var onClose: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Character Panel", onClose: onClose)
            List {
                ForEach(CharacterInsertCatalog.categories, id: \.name) { category in
                    Section(category.name) {
                        ForEach(category.entries) { entry in
                            Button {
                                onInsert(entry.character)
                            } label: {
                                HStack {
                                    Text(entry.label)
                                    Spacer()
                                    Text(entry.character)
                                        .font(.title3.monospaced())
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 180)
        .accessibilityLabel("Character insert panel")
    }
}

struct HexViewPanel: View {
    let fileURL: URL?
    var onClose: (() -> Void)?

    private var lines: [HexLine] {
        guard let fileURL, let data = HexViewEngine.data(for: fileURL) else { return [] }
        return HexViewEngine.lines(from: data)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Hex View", onClose: onClose)
            if fileURL == nil {
                Text("Save the file to view hex dump.")
                    .foregroundStyle(.secondary)
                    .padding(8)
                Spacer()
            } else if lines.isEmpty {
                Text("No binary data to display.")
                    .foregroundStyle(.secondary)
                    .padding(8)
                Spacer()
            } else {
                Text(fileURL!.lastPathComponent)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(lines) { line in
                            HStack(spacing: 8) {
                                Text(String(format: "%08X", line.offset))
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 72, alignment: .trailing)
                                Text(line.hex)
                                    .font(.system(.caption2, design: .monospaced))
                                Text(line.ascii)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(8)
                }
            }
        }
        .frame(minWidth: 280)
        .accessibilityLabel("Hex view panel")
    }
}

struct ProjectPanel: View {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var tabGroups: TabGroupStore
    @ObservedObject var workspace: WorkspaceStore
    var onSaveProject: () -> Void
    var onOpenProject: () -> Void
    var onActivateFile: (URL) -> Void
    var onClose: (() -> Void)?

    private var projectFiles: [URL] {
        collection.documents.compactMap(\.url)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeaderView(title: "Project", onClose: onClose) {
                Button("Save", action: onSaveProject).font(.caption)
                Button("Open", action: onOpenProject).font(.caption)
            }
            if let root = workspace.rootURL {
                Text(root.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }
            Text("\(projectFiles.count) open files")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            List(projectFiles, id: \.path) { url in
                Button(url.lastPathComponent) {
                    onActivateFile(url)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(minWidth: 200)
        .accessibilityLabel("Project panel")
    }
}

struct EncodingPickerSheet: View {
    @Binding var isPresented: Bool
    let currentEncoding: String.Encoding
    let onSelect: (String.Encoding) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeaderView(title: "Reopen with Encoding", onClose: { isPresented = false })
            List(EncodingCatalog.common) { option in
                Button {
                    onSelect(option.encoding)
                    isPresented = false
                } label: {
                    HStack {
                        Text(option.displayName)
                        Spacer()
                        if option.encoding == currentEncoding {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
            }
        }
        .padding(16)
        .frame(width: 360, height: 320)
    }
}
