import LexPadCore
import SwiftUI

struct EditorLineOpNotificationsModifierA: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    var refreshFind: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadDuplicateLine)) { _ in
                apply { LineOperations.duplicateLine(in: $0.text, line: $0.caret.line) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadMoveLineUp)) { _ in
                apply { LineOperations.moveLineUp(in: $0.text, line: $0.caret.line) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadMoveLineDown)) { _ in
                apply { LineOperations.moveLineDown(in: $0.text, line: $0.caret.line) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSortLinesAsc)) { _ in
                apply { LineOperations.sortLines(in: $0.text, ascending: true, caseInsensitive: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSortLinesDesc)) { _ in
                apply { LineOperations.sortLines(in: $0.text, ascending: false, caseInsensitive: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadRemoveDupLines)) { _ in
                apply { LineOperations.removeDuplicateLines(in: $0.text, consecutiveOnly: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadRemoveEmptyLines)) { _ in
                apply { LineOperations.removeEmptyLines(in: $0.text, includingWhitespace: true) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadJoinLines)) { _ in
                apply { LineOperations.joinLines(in: $0.text, range: $0.caret.line...($0.caret.line + 1)) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSplitLines)) { _ in
                apply { LineOperations.splitLine(in: $0.text, line: $0.caret.line, column: $0.caret.column) }
            }
    }

    private func apply(_ transform: (TextDocument) -> String) {
        guard let doc = collection.activeDocument else { return }
        collection.replaceActiveText(transform(doc))
        refreshFind()
    }
}

struct EditorLineOpNotificationsModifierB: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var settings: EditorSettings
    var refreshFind: () -> Void
    var performEOL: (EndOfLine) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadReverseLines)) { _ in
                apply { LineOperations.reverseLines(in: $0.text) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadTrimTrailing)) { _ in
                apply { LineOperations.trimLines(in: $0.text, leading: false, trailing: true) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadTrimLeading)) { _ in
                apply { LineOperations.trimLines(in: $0.text, leading: true, trailing: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadUpperCase)) { _ in
                apply { LineOperations.convertCase(in: $0.text, mode: .upper) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadLowerCase)) { _ in
                apply { LineOperations.convertCase(in: $0.text, mode: .lower) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadProperCase)) { _ in
                apply { LineOperations.convertCase(in: $0.text, mode: .proper) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadInvertCase)) { _ in
                apply { LineOperations.convertCase(in: $0.text, mode: .invert) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadTabsToSpaces)) { _ in
                apply { LineOperations.tabsToSpaces(in: $0.text, tabSize: settings.tabSize) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSpacesToTabs)) { _ in
                apply { LineOperations.spacesToTabs(in: $0.text, tabSize: settings.tabSize) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadConvertEOLToLF)) { _ in performEOL(.lf) }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadConvertEOLToCRLF)) { _ in performEOL(.crlf) }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadConvertEOLToCR)) { _ in performEOL(.cr) }
    }

    private func apply(_ transform: (TextDocument) -> String) {
        guard let doc = collection.activeDocument else { return }
        collection.replaceActiveText(transform(doc))
        refreshFind()
    }
}

struct EditorFindChangeModifier: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    @Binding var findPattern: String
    @Binding var findRegex: Bool
    @Binding var findExtended: Bool
    @Binding var findMatchCase: Bool
    @Binding var findWholeWord: Bool
    var refreshFind: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: findPattern) { _ in refreshFind() }
            .onChange(of: findRegex) { _ in refreshFind() }
            .onChange(of: findExtended) { _ in refreshFind() }
            .onChange(of: findMatchCase) { _ in refreshFind() }
            .onChange(of: findWholeWord) { _ in refreshFind() }
            .onChange(of: collection.activeDocumentID) { _ in refreshFind() }
    }
}

struct EditorNavNotificationsModifier: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var macroRecorder: MacroRecorder
    @ObservedObject var settings: EditorSettings
    @Binding var showFindBar: Bool
    @Binding var showGoToLine: Bool
    @Binding var showFindInFiles: Bool
    @Binding var showReplaceInFiles: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showQuickOpen: Bool
    @Binding var showMacros: Bool
    @Binding var showDiff: Bool
    @Binding var diffLeftTitle: String
    @Binding var diffRightTitle: String
    @Binding var diffLines: [DiffLine]
    @Binding var selectedRange: NSRange
    var refreshFind: () -> Void
    var reloadFile: () -> Void
    var onBookmarkAllMatches: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadNewTab)) { _ in collection.newDocument() }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleFind)) { _ in showFindBar = true; refreshFind() }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleReplace)) { _ in showFindBar = true; refreshFind() }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadGoToLine)) { _ in showGoToLine = true }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadFindInFiles)) { _ in showFindInFiles = true }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadReplaceInFiles)) { _ in showReplaceInFiles = true }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadCommandPalette)) { _ in showCommandPalette = true }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadQuickOpen)) { _ in showQuickOpen = true }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadStartMacroRecording)) { _ in
                showMacros = true; macroRecorder.startRecording()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadStopMacroRecording)) { _ in
                macroRecorder.stopRecording(name: "Recorded Macro")
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadCompareFiles)) { note in
                handleCompare(note)
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadFoldAll)) { _ in
                #if LEXPAD_HAS_SCINTILLA
                ScintillaEditorSupport.foldAll()
                #endif
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadUnfoldAll)) { _ in
                #if LEXPAD_HAS_SCINTILLA
                ScintillaEditorSupport.unfoldAll()
                #endif
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleOverwrite)) { _ in
                toggleOverwrite()
            }
            .modifier(EditorBookmarkNotificationsModifier(
                collection: collection,
                settings: settings,
                selectedRange: $selectedRange,
                refreshFind: refreshFind,
                onBookmarkAllMatches: onBookmarkAllMatches
            ))
            .onReceive(NotificationCenter.default.publisher(for: .lexPadReloadFile)) { _ in reloadFile() }
    }

    private func toggleOverwrite() {
        let next = !(collection.activeDocument?.isOverwriteMode ?? false)
        collection.setActiveOverwriteMode(next)
    }

    private func handleCompare(_ note: Notification) {
        guard let left = note.userInfo?["left"] as? URL,
              let right = note.userInfo?["right"] as? URL,
              let leftText = try? String(contentsOf: left, encoding: .utf8),
              let rightText = try? String(contentsOf: right, encoding: .utf8) else { return }
        diffLeftTitle = left.lastPathComponent
        diffRightTitle = right.lastPathComponent
        diffLines = DiffEngine.compare(left: leftText, right: rightText)
        showDiff = true
    }
}

struct EditorBookmarkNotificationsModifier: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var settings: EditorSettings
    @Binding var selectedRange: NSRange
    var refreshFind: () -> Void
    var onBookmarkAllMatches: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleBookmark)) { _ in
                collection.toggleBookmark(style: settings.activeMarkStyle)
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadNextBookmark)) { _ in
                goToNext()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadPreviousBookmark)) { _ in
                goToPrevious()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadClearBookmarks)) { _ in
                clearBookmarks()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadBookmarkAllMatches)) { _ in
                onBookmarkAllMatches()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleComment)) { _ in
                collection.toggleLineComments(selectedRange: selectedRange, tabSize: settings.tabSize)
                refreshFind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSetMarkStyle)) { note in
                guard let raw = note.userInfo?["style"] as? Int,
                      let style = MarkStyle(rawValue: raw) else { return }
                settings.activeMarkStyle = style
                settings.persist()
                collection.setMark(style: style)
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadClearMarkStyle)) { note in
                guard let raw = note.userInfo?["style"] as? Int,
                      let style = MarkStyle(rawValue: raw) else { return }
                collection.clearMarkStyle(style)
            }
    }

    private func goToNext() {
        guard let range = collection.goToNextBookmark() else { return }
        selectedRange = range
    }

    private func goToPrevious() {
        guard let range = collection.goToPreviousBookmark() else { return }
        selectedRange = range
    }

    private func clearBookmarks() {
        guard var doc = collection.activeDocument else { return }
        doc.bookmarks.removeAll()
        collection.activeDocument = doc
    }
}
