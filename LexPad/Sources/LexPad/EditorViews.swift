import LexPadCore
import SwiftUI

struct FindReplaceBarView: View {
    @Binding var findPattern: String
    @Binding var replacePattern: String
    @Binding var isRegex: Bool
    @Binding var isExtended: Bool
    @Binding var matchCase: Bool
    @Binding var wholeWord: Bool
    let matchCount: Int
    let onFindNext: () -> Void
    let onFindPrevious: () -> Void
    let onReplace: () -> Void
    let onReplaceAll: () -> Void
    let onBookmarkAll: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField("Find", text: $findPattern)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200)
                    .onSubmit(onFindNext)

                Toggle("Regex", isOn: $isRegex).toggleStyle(.checkbox)
                Toggle("Extended", isOn: $isExtended).toggleStyle(.checkbox)
                Toggle("Match case", isOn: $matchCase).toggleStyle(.checkbox)
                Toggle("Whole word", isOn: $wholeWord).toggleStyle(.checkbox)

                Text(matchCount == 0 ? "No matches" : "\(matchCount) matches")
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 90, alignment: .leading)

                Button("Previous", action: onFindPrevious)
                Button("Next", action: onFindNext)
                Button("Close", action: onClose)
            }

            HStack(spacing: 8) {
                TextField("Replace with", text: $replacePattern)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200)
                Button("Replace", action: onReplace)
                Button("Replace All", action: onReplaceAll)
                Button("Bookmark All", action: onBookmarkAll)
                    .disabled(matchCount == 0)
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct SplitPaneHeaderView: View {
    let pane: EditorPane
    let documentName: String
    let isClone: Bool
    @Binding var syncScroll: Bool
    let onClosePane: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(pane == .primary ? "Pane 1" : "Pane 2")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            Text(documentName)
                .font(.caption)
                .lineLimit(1)

            if isClone {
                Text("Clone")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            if isClone {
                Toggle("Sync Scroll", isOn: $syncScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)
            }

            Button(action: onClosePane) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(isClone ? "Close clone view" : "Close split pane")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}

struct TabStripView: View {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var tabGroups: TabGroupStore
    @ObservedObject var settings: EditorSettings
    @ObservedObject var splitState: SplitViewState
    let onClose: (UUID) -> Void

    @State private var renamingDocumentID: UUID?
    @State private var renameText = ""
    @FocusState private var renameFieldFocused: Bool

    var body: some View {
        Group {
            switch settings.tabBarStyle {
            case .horizontal:
                horizontalStrip
            case .vertical:
                verticalStrip
            case .multiLine:
                multiLineStrip
            }
        }
    }

    private var horizontalStrip: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(collection.sortedDocuments, id: \.id) { document in
                        tabButton(for: document)
                    }
                    tabBarNewTabZone
                }
            }
            tabStripTrailingControls
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.text], delegate: TabSplitDropDelegate(
            collection: collection,
            splitState: splitState
        ))
    }

    private var tabStripTrailingControls: some View {
        HStack(spacing: 0) {
            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)
            openTabsMenu
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var openTabsMenu: some View {
        Menu {
            if collection.sortedDocuments.isEmpty {
                Text("No open files")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(collection.sortedDocuments, id: \.id) { document in
                    Button {
                        collection.activeDocumentID = document.id
                    } label: {
                        openTabMenuRow(for: document)
                    }
                }
            }
            Divider()
            Button("New Tab") {
                collection.newDocument()
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 28, height: 30)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .help("All open files (\(collection.documents.count))")
    }

    private func openTabMenuRow(for document: TextDocument) -> some View {
        let isActive = collection.activeDocumentID == document.id
        let title = document.tabTitle + (document.isDirty ? " •" : "")
        return HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .opacity(isActive ? 1 : 0)
                .frame(width: 12)
            Text(title)
                .lineLimit(1)
        }
    }

    /// Fixed-width trailing zone inside the scroll view (double-click → new tab).
    private var tabBarNewTabZone: some View {
        Color.clear
            .frame(width: 72, height: 30)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                collection.newDocument()
            }
            .help("Double-click to open a new tab")
    }

    private var verticalStrip: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                openTabsMenu
                    .padding(.trailing, 4)
            }
            .frame(height: 26)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(collection.sortedDocuments, id: \.id) { document in
                        tabButton(for: document)
                    }
                }
            }
            tabBarNewTabZone
                .frame(height: 28)
                .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var multiLineStrip: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                openTabsMenu
                    .padding(.trailing, 4)
            }
            .frame(height: 24)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 0)], spacing: 0) {
                    ForEach(collection.sortedDocuments, id: \.id) { document in
                        tabButton(for: document)
                    }
                }
            }
            tabBarNewTabZone
                .frame(height: 24)
                .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: 96)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func tabButton(for document: TextDocument) -> some View {
        let isActive = collection.activeDocumentID == document.id
        let groupID = tabGroups.groupID(for: document.id)
        let group = tabGroups.groups.first { $0.id == groupID }
        return HStack(spacing: 6) {
            if let group {
                Circle()
                    .fill(TabGroupColor.color(at: group.colorIndex))
                    .frame(width: 7, height: 7)
            }
            Button {
                collection.activeDocumentID = document.id
            } label: {
                tabTitleView(for: document)
            }
            .buttonStyle(.plain)
            Button {
                onClose(document.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .padding(4)
            }
            .buttonStyle(.plain)
            .opacity(0.7)
            .help("Close tab")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tabBackground(isActive: isActive, group: group))
        .overlay(alignment: .leading) {
            if let group {
                RoundedRectangle(cornerRadius: 1)
                    .fill(TabGroupColor.color(at: group.colorIndex))
                    .frame(width: 3)
            }
        }
        .overlay(alignment: .bottom) {
            if isActive {
                Rectangle().fill(Color.accentColor).frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Rename Tab") {
                beginRename(document)
            }
            Button("Duplicate Tab") {
                try? collection.openDuplicateTab(for: document.id)
            }
            .disabled(document.url == nil)
            Button(document.isPinned ? "Unpin Tab" : "Pin Tab") {
                collection.togglePinned(documentID: document.id)
            }
            Button(document.isReadOnly ? "Allow Editing" : "Read Only") {
                collection.toggleReadOnly(documentID: document.id)
            }
            Divider()
            Button("New Tab Group with Tab") {
                _ = tabGroups.createGroup(documentIDs: [document.id])
                tabGroups.mode = .byGroup
                tabGroups.persist()
            }
            if !tabGroups.groups.isEmpty {
                Menu("Move to Group") {
                    ForEach(tabGroups.groups) { g in
                        Button(g.name) {
                            tabGroups.addDocument(document.id, to: g.id)
                            tabGroups.mode = .byGroup
                        }
                    }
                    if groupID != nil {
                        Divider()
                        Button("Remove from Group") {
                            tabGroups.removeDocument(document.id)
                        }
                    }
                }
            }
        }
        .onDrag {
            NSItemProvider(object: document.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: TabDropDelegate(
            documentID: document.id,
            collection: collection
        ))
    }

    private func tabBackground(isActive: Bool, group: TabGroup?) -> Color {
        if isActive { return Color.accentColor.opacity(0.15) }
        if let group { return TabGroupColor.color(at: group.colorIndex).opacity(0.1) }
        return Color.clear
    }

    @ViewBuilder
    private func tabTitleView(for document: TextDocument) -> some View {
        if renamingDocumentID == document.id {
            TextField("Tab name", text: $renameText, onCommit: { commitRename(for: document.id) })
                .textFieldStyle(.plain)
                .lineLimit(1)
                .frame(minWidth: 72, maxWidth: 200)
                .focused($renameFieldFocused)
                .onExitCommand { cancelRename() }
                .onAppear {
                    renameFieldFocused = true
                }
        } else {
            Text(document.displayName)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 200, alignment: .leading)
                .onTapGesture(count: 2) {
                    beginRename(document)
                }
        }
    }

    private func beginRename(_ document: TextDocument) {
        renamingDocumentID = document.id
        renameText = document.tabTitle
        renameFieldFocused = true
    }

    private func commitRename(for documentID: UUID) {
        defer { cancelRename() }
        guard renamingDocumentID == documentID else { return }
        do {
            try collection.renameTab(documentID: documentID, to: renameText)
        } catch {
            NSSound.beep()
        }
    }

    private func cancelRename() {
        renamingDocumentID = nil
        renameText = ""
        renameFieldFocused = false
    }
}

private struct TabSplitDropDelegate: DropDelegate {
    let collection: DocumentCollection
    let splitState: SplitViewState

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let str = item as? String, let draggedID = UUID(uuidString: str) else { return }
            Task { @MainActor in
                splitState.openSplit(
                    .vertical,
                    clone: false,
                    activeDocumentID: collection.activeDocumentID,
                    otherDocumentIDs: collection.documents.map(\.id)
                )
                splitState.activate(documentID: draggedID, in: .secondary)
                collection.activateDocument(draggedID, inPane: .secondary, splitState: splitState)
            }
        }
        return true
    }
}

private struct TabDropDelegate: DropDelegate {
    let documentID: UUID
    let collection: DocumentCollection

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let str = item as? String, let draggedID = UUID(uuidString: str) else { return }
            Task { @MainActor in
                guard let from = collection.documents.firstIndex(where: { $0.id == draggedID }),
                      let to = collection.documents.firstIndex(where: { $0.id == documentID }) else { return }
                collection.moveDocument(from: IndexSet(integer: from), to: to > from ? to + 1 : to)
            }
        }
        return true
    }
}

struct PaneTabStrip: View {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var splitState: SplitViewState
    @ObservedObject var tabGroups: TabGroupStore
    let pane: EditorPane
    let activeDocumentID: UUID?
    let onSelect: (UUID) -> Void
    let onClose: (UUID) -> Void
    let onMoveToOtherView: () -> Void
    let onCloseSplit: () -> Void

    @State private var renamingDocumentID: UUID?
    @State private var renameText = ""
    @FocusState private var renameFieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(pane == .primary ? "Pane 1" : "Pane 2")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(collection.documents, id: \.id) { doc in
                        paneTab(for: doc)
                    }
                }
            }

            Menu {
                ForEach(collection.documents, id: \.id) { doc in
                    Button {
                        onSelect(doc.id)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .opacity(activeDocumentID == doc.id ? 1 : 0)
                                .frame(width: 12)
                            Text(doc.tabTitle + (doc.isDirty ? " •" : ""))
                                .lineLimit(1)
                        }
                    }
                }
                Divider()
                Button("Move to Other View", action: onMoveToOtherView)
                Button("Close Split", action: onCloseSplit)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .menuStyle(.borderlessButton)
            .help("All open files in this pane (\(collection.documents.count))")

            Button(action: onCloseSplit) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Close split")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .onDrop(of: [.text], delegate: PaneTabDropDelegate(
            pane: pane,
            splitState: splitState,
            collection: collection
        ))
    }

    private func paneTab(for document: TextDocument) -> some View {
        let isActive = activeDocumentID == document.id
        let group = tabGroups.group(for: document.id)
        return HStack(spacing: 4) {
            if let group {
                Circle()
                    .fill(TabGroupColor.color(at: group.colorIndex))
                    .frame(width: 6, height: 6)
            }
            Button {
                onSelect(document.id)
            } label: {
                paneTabTitle(for: document)
            }
            .buttonStyle(.plain)
            Button {
                onClose(document.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .padding(3)
            }
            .buttonStyle(.plain)
            .opacity(0.7)
            .help("Close tab")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(paneTabBackground(isActive: isActive, group: group))
        .overlay(alignment: .leading) {
            if let group {
                RoundedRectangle(cornerRadius: 1)
                    .fill(TabGroupColor.color(at: group.colorIndex))
                    .frame(width: 3)
            }
        }
        .contentShape(Rectangle())
        .onDrag {
            NSItemProvider(object: document.id.uuidString as NSString)
        }
    }

    private func paneTabBackground(isActive: Bool, group: TabGroup?) -> Color {
        if isActive { return Color.accentColor.opacity(0.2) }
        if let group { return TabGroupColor.color(at: group.colorIndex).opacity(0.1) }
        return Color(nsColor: .windowBackgroundColor).opacity(0.5)
    }

    @ViewBuilder
    private func paneTabTitle(for document: TextDocument) -> some View {
        if renamingDocumentID == document.id {
            TextField("Tab name", text: $renameText, onCommit: { commitPaneRename(for: document.id) })
                .textFieldStyle(.plain)
                .font(.caption)
                .lineLimit(1)
                .frame(minWidth: 56, maxWidth: 160)
                .focused($renameFieldFocused)
                .onExitCommand { cancelPaneRename() }
                .onAppear { renameFieldFocused = true }
        } else {
            Text(document.displayName)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 160, alignment: .leading)
                .font(.caption)
                .onTapGesture(count: 2) {
                    beginPaneRename(document)
                }
        }
    }

    private func beginPaneRename(_ document: TextDocument) {
        renamingDocumentID = document.id
        renameText = document.tabTitle
        renameFieldFocused = true
    }

    private func commitPaneRename(for documentID: UUID) {
        defer { cancelPaneRename() }
        guard renamingDocumentID == documentID else { return }
        do {
            try collection.renameTab(documentID: documentID, to: renameText)
        } catch {
            NSSound.beep()
        }
    }

    private func cancelPaneRename() {
        renamingDocumentID = nil
        renameText = ""
        renameFieldFocused = false
    }
}

private struct PaneTabDropDelegate: DropDelegate {
    let pane: EditorPane
    let splitState: SplitViewState
    let collection: DocumentCollection

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let str = item as? String, let docID = UUID(uuidString: str) else { return }
            Task { @MainActor in
                splitState.activate(documentID: docID, in: pane)
                collection.activateDocument(docID, inPane: pane, splitState: splitState)
            }
        }
        return true
    }
}

struct StatusBarView: View {
    let document: TextDocument?
    var languageLabel: String? = nil
    let matchCount: Int
    let wordWrap: Bool
    let insertMode: Bool
    var gitBranch: String? = nil
    var largeFileMode: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Text("Ln \(document?.caret.line ?? 1), Col \(document?.caret.column ?? 1)")
            if let gitBranch {
                Text("⎇ \(gitBranch)")
                    .foregroundStyle(.secondary)
            }
            if largeFileMode {
                Text("LARGE")
                    .foregroundStyle(.orange)
            }
            if document?.isReadOnly == true {
                Text("READ-ONLY")
                    .foregroundStyle(.secondary)
            }
            if let label = document?.encodingLabel {
                Text(label)
                    .foregroundStyle(.secondary)
            }
            Text(languageLabel ?? document?.language.rawValue ?? "Plain Text")
            Text(document?.endOfLine.displayName ?? "Unix (LF)")
            Text(document?.encoding.displayName ?? "UTF-8")
            Text(insertMode ? "INS" : "OVR")
                .foregroundStyle(.secondary)
            if wordWrap {
                Text("Wrap").foregroundStyle(.secondary)
            }
            Spacer()
            if matchCount > 0 {
                Text("\(matchCount) matches")
            }
            Text("\(document?.lineCount ?? 1) lines")
            Text("\(document?.characterCount ?? 0) chars")
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) { Divider() }
    }
}

struct GoToLineSheet: View {
    @Binding var isPresented: Bool
    @State var lineNumber: String = ""
    let maxLine: Int
    let onGo: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeaderView(title: "Go to Line", onClose: { isPresented = false })
            TextField("Line number (1–\(maxLine))", text: $lineNumber)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Go", action: submit).keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func submit() {
        guard let line = Int(lineNumber), line >= 1, line <= maxLine else { return }
        onGo(line)
        isPresented = false
    }
}
