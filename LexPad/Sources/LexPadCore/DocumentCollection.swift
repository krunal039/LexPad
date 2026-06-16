import Foundation

@MainActor
public final class DocumentCollection: ObservableObject {
    @Published public private(set) var documents: [TextDocument] = []
    @Published public var activeDocumentID: UUID?
    @Published public var recentFiles: [URL] = []
    public var largeFileThresholdBytes: Int = LargeFilePolicy.defaultThresholdBytes
    public var enableLargeFileMode: Bool = true

    public init() {
        recentFiles = RecentFilesStore.load()
    }

    /// Pinned tabs first, then others in list order.
    public var sortedDocuments: [TextDocument] {
        let pinned = documents.filter(\.isPinned)
        let rest = documents.filter { !$0.isPinned }
        return pinned + rest
    }

    public func bootstrapIfEmpty() {
        if documents.isEmpty {
            newDocument()
        }
    }

    public func clearAll() {
        documents.removeAll()
        activeDocumentID = nil
    }

    public var activeDocument: TextDocument? {
        get {
            guard let id = activeDocumentID else { return nil }
            return documents.first { $0.id == id }
        }
        set {
            guard let newValue, let index = documents.firstIndex(where: { $0.id == newValue.id }) else { return }
            documents[index] = newValue
        }
    }

    public func newDocument() {
        let doc = TextDocument()
        documents.append(doc)
        activeDocumentID = doc.id
    }

    public func open(url: URL, documentID: UUID? = nil, allowDuplicate: Bool = false) throws {
        if !allowDuplicate, let existing = documents.first(where: { $0.url == url }) {
            activeDocumentID = existing.id
            recentFiles = RecentFilesStore.remember(url, in: recentFiles)
            return
        }
        var doc = try DocumentStore.load(
            from: url,
            largeFileThresholdBytes: enableLargeFileMode ? largeFileThresholdBytes : Int.max
        )
        if let documentID { doc = reidentify(doc, id: documentID) }
        documents.append(doc)
        activeDocumentID = doc.id
        recentFiles = RecentFilesStore.remember(url, in: recentFiles)
    }

    /// Opens a second tab for the same file (Notepad++ duplicate tab).
    public func openDuplicateTab(for documentID: UUID) throws {
        guard let source = document(for: documentID), let url = source.url else { return }
        try open(url: url, allowDuplicate: true)
    }

    public func togglePinned(documentID: UUID) {
        guard var doc = document(for: documentID),
              let index = documents.firstIndex(where: { $0.id == documentID }) else { return }
        doc.isPinned.toggle()
        documents[index] = doc
    }

    public func toggleReadOnly(documentID: UUID? = nil) {
        let id = documentID ?? activeDocumentID
        guard let id, var doc = document(for: id),
              let index = documents.firstIndex(where: { $0.id == id }) else { return }
        doc.isReadOnly.toggle()
        documents[index] = doc
    }

    public func restoreUntitled(
        id: UUID,
        text: String,
        language: EditorLanguage = .normal_lang,
        userLanguageID: String? = nil,
        caret: CaretPosition = CaretPosition(),
        untitledName: String? = nil
    ) {
        guard !documents.contains(where: { $0.id == id }) else { return }
        let doc = TextDocument(
            id: id,
            text: text,
            isDirty: true,
            language: language,
            userLanguageID: userLanguageID,
            caret: caret,
            untitledName: untitledName
        )
        documents.append(doc)
    }

    /// Inline tab rename: renames on disk for saved files, or sets untitled tab label.
    public func renameTab(documentID: UUID, to rawName: String) throws {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("/") else {
            throw DocumentRenameError.invalidName
        }

        guard var doc = document(for: documentID),
              let index = documents.firstIndex(where: { $0.id == documentID }) else { return }

        if let url = doc.url {
            let directory = url.deletingLastPathComponent()
            let newFileName: String
            if (trimmed as NSString).pathExtension.isEmpty, !url.pathExtension.isEmpty {
                newFileName = "\(trimmed).\(url.pathExtension)"
            } else {
                newFileName = trimmed
            }
            let newURL = directory.appendingPathComponent(newFileName)
            if newURL.standardizedFileURL == url.standardizedFileURL { return }
            if FileManager.default.fileExists(atPath: newURL.path) {
                throw DocumentRenameError.fileExists
            }
            do {
                try FileManager.default.moveItem(at: url, to: newURL)
            } catch {
                throw DocumentRenameError.renameFailed(error.localizedDescription)
            }
            doc.url = newURL
            doc.language = EditorLanguage.detect(from: newURL)
            doc.userLanguageID = UserLanguagePersistence.detect(from: newURL)
            doc.isReadOnly = !FileManager.default.isWritableFile(atPath: newURL.path)
            RecentFilesStore.renamePath(from: url, to: newURL)
            recentFiles = RecentFilesStore.load()
        } else {
            let normalized = trimmed == "Untitled" ? nil : trimmed
            if doc.untitledName == normalized { return }
            doc.untitledName = normalized
        }

        documents[index] = doc
    }

    private func reidentify(_ doc: TextDocument, id: UUID) -> TextDocument {
        TextDocument(
            id: id,
            url: doc.url,
            text: doc.text,
            isDirty: doc.isDirty,
            encoding: doc.encoding,
            endOfLine: doc.endOfLine,
            language: doc.language,
            userLanguageID: doc.userLanguageID,
            caret: doc.caret,
            bookmarks: doc.bookmarks,
            isOverwriteMode: doc.isOverwriteMode,
            lineChangeHistory: doc.lineChangeHistory,
            isLargeFileMode: doc.isLargeFileMode,
            isReadOnly: doc.isReadOnly,
            isPinned: doc.isPinned,
            encodingLabel: doc.encodingLabel,
            untitledName: doc.untitledName
        )
    }

    public func close(documentID: UUID) -> TextDocument? {
        guard let doc = documents.first(where: { $0.id == documentID }) else { return nil }
        if doc.isPinned {
            // Allow close but user was warned via UI — pinned is a sort hint only.
        }
        documents.removeAll { $0.id == documentID }
        if activeDocumentID == documentID {
            activeDocumentID = documents.last?.id
        }
        if documents.isEmpty {
            newDocument()
        }
        return doc
    }

    public func activateDocument(_ id: UUID, inPane pane: EditorPane? = nil, splitState: SplitViewState? = nil) {
        guard documents.contains(where: { $0.id == id }) else { return }
        activeDocumentID = id
        if let pane, let splitState, splitState.orientation != .none {
            splitState.activate(documentID: id, in: pane)
        }
    }

    public func updateActiveText(_ text: String) {
        guard var doc = activeDocument else { return }
        doc.text = text
        doc.isDirty = true
        activeDocument = doc
    }

    public func replaceActiveText(_ text: String, endOfLine: EndOfLine? = nil) {
        guard var doc = activeDocument else { return }
        doc.text = text
        doc.isDirty = true
        if let endOfLine { doc.endOfLine = endOfLine }
        activeDocument = doc
    }

    public func updateActiveCaret(line: Int, column: Int) {
        guard var doc = activeDocument else { return }
        doc.caret = CaretPosition(line: line, column: column)
        activeDocument = doc
    }

    public func setActiveLanguage(_ language: EditorLanguage) {
        guard var doc = activeDocument else { return }
        doc.language = language
        doc.userLanguageID = nil
        activeDocument = doc
    }

    public func setActiveUserLanguage(_ id: String?) {
        guard var doc = activeDocument else { return }
        doc.userLanguageID = id
        activeDocument = doc
    }

    public func saveActive(to url: URL? = nil) throws {
        guard let doc = activeDocument else { return }
        if doc.isReadOnly {
            throw DocumentLoadError.readFailed("Document is read-only.")
        }
        let saved = try DocumentStore.save(doc, to: url)
        if let index = documents.firstIndex(where: { $0.id == saved.id }) {
            documents[index] = saved
        }
        if let savedURL = saved.url {
            recentFiles = RecentFilesStore.remember(savedURL, in: recentFiles)
        }
    }

    public func setActiveOverwriteMode(_ enabled: Bool) {
        guard var doc = activeDocument else { return }
        doc.isOverwriteMode = enabled
        activeDocument = doc
    }

    public func toggleBookmark(on line: Int? = nil, style: MarkStyle? = nil) {
        guard var doc = activeDocument else { return }
        let target = line ?? doc.caret.line
        let markStyle = style ?? .style3
        _ = BookmarkStore.toggle(bookmarks: &doc.bookmarks, line: target, style: markStyle)
        activeDocument = doc
    }

    public func setMark(style: MarkStyle, on line: Int? = nil) {
        guard var doc = activeDocument else { return }
        let target = line ?? doc.caret.line
        BookmarkStore.setMark(on: target, style: style, in: &doc.bookmarks)
        activeDocument = doc
    }

    public func clearMarkStyle(_ style: MarkStyle) {
        guard var doc = activeDocument else { return }
        BookmarkStore.clearStyle(style, in: &doc.bookmarks)
        activeDocument = doc
    }

    public func bookmarkLines(_ lines: [Int], style: MarkStyle = .style3) {
        guard var doc = activeDocument else { return }
        BookmarkStore.bookmarkAll(lines: lines, in: &doc.bookmarks, style: style)
        activeDocument = doc
    }

    public func toggleLineComments(selectedRange: NSRange, tabSize: Int) {
        guard let doc = activeDocument,
              let result = CommentEngine.toggleLineComments(
                in: doc.text,
                language: doc.language,
                selectedRange: selectedRange,
                tabSize: tabSize,
                userLanguage: UserLanguagePersistence.loadAll().first { $0.id == doc.userLanguageID }
              ) else { return }
        replaceActiveText(result)
    }

    public func goToNextBookmark() -> NSRange? {
        guard let doc = activeDocument,
              let bookmark = BookmarkStore.next(from: doc.caret.line, in: doc.bookmarks) else { return nil }
        return goToLine(bookmark.line)
    }

    public func goToPreviousBookmark() -> NSRange? {
        guard let doc = activeDocument,
              let bookmark = BookmarkStore.previous(from: doc.caret.line, in: doc.bookmarks) else { return nil }
        return goToLine(bookmark.line)
    }

    public func reloadActiveFromDisk() throws {
        guard let doc = activeDocument, let url = doc.url else { return }
        let reloaded = try DocumentStore.load(from: url)
        var updated = reloaded
        updated.bookmarks = doc.bookmarks
        if let index = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[index] = updated
        }
    }

    public func reloadActive(with encoding: String.Encoding) throws {
        guard let doc = activeDocument, let url = doc.url else { return }
        let reloaded = try EncodingConverter.reload(from: url, using: encoding)
        var updated = reloaded
        updated.bookmarks = doc.bookmarks
        if let index = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[index] = updated
        }
    }

    public func toggleBlockComments(selectedRange: NSRange) {
        guard let doc = activeDocument,
              let result = CommentEngine.toggleBlockComments(
                in: doc.text,
                language: doc.language,
                selectedRange: selectedRange
              ) else { return }
        replaceActiveText(result)
    }

    public func projectFileURLs() -> [URL] {
        documents.compactMap(\.url)
    }

    public func autosaveDirtyDocuments() {
        for doc in documents where doc.isDirty && doc.url != nil {
            guard let url = doc.url else { continue }
            try? {
                let saved = try DocumentStore.save(doc, to: url)
                if let index = documents.firstIndex(where: { $0.id == doc.id }) {
                    documents[index] = saved
                }
            }()
        }
    }

    public func document(for id: UUID) -> TextDocument? {
        documents.first { $0.id == id }
    }

    public func replaceDocument(_ doc: TextDocument) {
        guard let index = documents.firstIndex(where: { $0.id == doc.id }) else { return }
        documents[index] = doc
    }

    public var recentFileEntries: [RecentFileEntry] {
        RecentFilesStore.loadEntries()
    }

    public func clearRecentFiles() {
        RecentFilesStore.clear()
        recentFiles = []
    }

    public func removeFromRecentFiles(path: String) {
        RecentFilesStore.remove(path: path)
        recentFiles = RecentFilesStore.load()
    }

    public func togglePinRecentFile(path: String) {
        RecentFilesStore.togglePinned(path: path)
        recentFiles = RecentFilesStore.load()
    }

    public func activateDocument(_ id: UUID) {
        activateDocument(id, inPane: nil, splitState: nil)
    }

    public func updateDocument(_ id: UUID, text: String) {
        guard var doc = document(for: id) else { return }
        if doc.isReadOnly { return }
        let affected = ChangeHistoryEngine.linesAffected(oldText: doc.text, newText: text)
        ChangeHistoryEngine.markEdited(lines: affected, in: &doc.lineChangeHistory)
        doc.text = text
        doc.isDirty = true
        if let index = documents.firstIndex(where: { $0.id == id }) {
            documents[index] = doc
        }
    }

    public func moveDocument(from source: IndexSet, to destination: Int) {
        documents.move(fromOffsets: source, toOffset: destination)
    }

    public func moveDocument(_ id: UUID, toIndex index: Int) {
        guard let from = documents.firstIndex(where: { $0.id == id }) else { return }
        let doc = documents.remove(at: from)
        let dest = min(max(index, 0), documents.count)
        documents.insert(doc, at: dest)
    }

    public func applyColumnNumbers(start: Int, step: Int, padWidth: Int, selectedRange: NSRange) {
        guard let doc = activeDocument else { return }
        let result = ColumnEditorEngine.insertNumbers(
            in: doc.text,
            selectedRange: selectedRange,
            start: start,
            step: step,
            padWidth: padWidth
        )
        replaceActiveText(result)
    }

    public func updateCaret(in documentID: UUID, line: Int, column: Int) {
        guard var doc = document(for: documentID) else { return }
        guard doc.caret.line != line || doc.caret.column != column else { return }
        doc.caret = CaretPosition(line: line, column: column)
        if let index = documents.firstIndex(where: { $0.id == documentID }) {
            documents[index] = doc
        }
    }

    public func goToLine(in documentID: UUID, line: Int) -> NSRange? {
        guard line >= 1, var doc = document(for: documentID) else { return nil }
        let ns = doc.text as NSString
        var lineNum = 1
        var i = 0
        while i < ns.length {
            if lineNum == line {
                let lineRange = ns.lineRange(for: NSRange(location: i, length: 0))
                doc.caret = CaretPosition(line: line, column: 1)
                if let index = documents.firstIndex(where: { $0.id == documentID }) {
                    documents[index] = doc
                }
                return NSRange(location: lineRange.location, length: 0)
            }
            if ns.character(at: i) == 10 { lineNum += 1 }
            i += 1
        }
        if lineNum == line {
            doc.caret = CaretPosition(line: line, column: 1)
            if let index = documents.firstIndex(where: { $0.id == documentID }) {
                documents[index] = doc
            }
            return NSRange(location: ns.length, length: 0)
        }
        return nil
    }

    public func goToLine(_ line: Int) -> NSRange? {
        guard line >= 1, let doc = activeDocument else { return nil }
        let ns = doc.text as NSString
        var lineNum = 1
        var i = 0
        while i < ns.length {
            if lineNum == line {
                let lineRange = ns.lineRange(for: NSRange(location: i, length: 0))
                updateActiveCaret(line: line, column: 1)
                return NSRange(location: lineRange.location, length: 0)
            }
            if ns.character(at: i) == 10 { lineNum += 1 }
            i += 1
        }
        if lineNum == line {
            updateActiveCaret(line: line, column: 1)
            return NSRange(location: ns.length, length: 0)
        }
        return nil
    }
}
