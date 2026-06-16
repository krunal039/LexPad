import LexPadCore
import SwiftUI

struct EditorPaneView: View {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var settings: EditorSettings
    @ObservedObject var userLanguageStore: UserLanguageStore
    let snippets: [Snippet]
    let documentID: UUID
    @Binding var selectedRange: NSRange
    var highlightRanges: [NSRange]
    var bookmarks: [Bookmark]
    var isFocused: Bool
    var scrollToLine: Int?
    var onFocus: () -> Void
    var onTextChange: (String) -> Void
    var onSelectionChange: (Int, Int) -> Void
    var onScroll: ((Int) -> Void)?

    private var document: TextDocument? {
        collection.document(for: documentID)
    }

    var body: some View {
        Group {
            if let document {
                EditorSurfaceView(
                    text: Binding(
                        get: { collection.document(for: documentID)?.text ?? "" },
                        set: { collection.updateDocument(documentID, text: $0) }
                    ),
                    language: document.language,
                    userLanguage: userLanguageStore.language(id: document.userLanguageID),
                    snippets: snippets,
                    enableSnippetTriggers: settings.enableSnippetTriggers,
                    virtualSpaceEnabled: settings.virtualSpace,
                    enableAutoCompletion: settings.enableAutoCompletion,
                    autoCompletionMinLength: settings.autoCompletionMinLength,
                    buildCompletionItems: {
                        let text = collection.document(for: documentID)?.text ?? ""
                        let doc = collection.document(for: documentID)
                        let pos = selectedRange.location == NSNotFound
                            ? (text as NSString).length
                            : selectedRange.location
                        return CompletionEngine.candidates(
                            in: text,
                            language: doc?.language ?? .normal_lang,
                            userLanguage: userLanguageStore.language(id: doc?.userLanguageID),
                            caretPosition: pos
                        ).map(\.label)
                    },
                    selectedRange: selectedRange,
                    highlightRanges: highlightRanges,
                    bookmarks: bookmarks,
                    changeHistory: document.lineChangeHistory,
                    showChangeHistory: settings.showChangeHistory,
                    builtInTheme: settings.builtInTheme.rawValue,
                    disableHighlighting: document.isLargeFileMode,
                    wordWrap: settings.wordWrap,
                    showLineNumbers: settings.showLineNumbers,
                    fontSize: settings.fontSize,
                    tabSize: settings.tabSize,
                    useSpacesForTab: settings.useSpacesForTab,
                    codeFolding: settings.codeFolding,
                    isOverwriteMode: document.isOverwriteMode,
                    isReadOnly: document.isReadOnly,
                    enableBraceMatching: settings.enableBraceMatching,
                    enableSmartHighlight: settings.enableSmartHighlight,
                    enableSpellCheck: settings.enableSpellCheck,
                    enableCalltips: settings.enableCalltips,
                    prefersDarkMode: settings.prefersDarkMode,
                    scrollToLine: scrollToLine,
                    onTextChange: onTextChange,
                    onSelectionChange: onSelectionChange,
                    onScroll: onScroll
                )
            } else {
                Text("No document").foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture { onFocus() }
    }
}

struct EditorMainStack: View {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var settings: EditorSettings
    @ObservedObject var splitState: SplitViewState
    @ObservedObject var sidebarState: SidebarState
    @ObservedObject var workspace: WorkspaceStore
    @ObservedObject var tabGroups: TabGroupStore
    @ObservedObject var userLanguageStore: UserLanguageStore
    @Binding var showFindBar: Bool
    @Binding var showIncrementalSearch: Bool
    @Binding var incrementalPattern: String
    @Binding var incrementalMatchCase: Bool
    let incrementalMatchCount: Int
    let gitBranch: String?
    let gitRepoRoot: URL?
    let gitStatuses: [GitFileStatus]
    let gitDiff: String
    let gitBlame: String
    let gitCommitStatus: String
    var onIncrementalNext: () -> Void
    var onIncrementalPrevious: () -> Void
    var onGitRefresh: () -> Void
    var onGitStage: (String) -> Void
    var onGitCommit: (String) -> Void
    var onGitOpenRepository: (() -> Void)?
    var onGitInitRepository: (() -> Void)?
    @ObservedObject var snippetStore: SnippetStore
    var onInsertSnippet: (Snippet) -> Void
    var onInsertFunctionStub: (() -> Void)?
    var onInsertCharacter: ((String) -> Void)?
    var onSaveProject: (() -> Void)?
    var onOpenProject: (() -> Void)?
    @Binding var findPattern: String
    @Binding var replacePattern: String
    @Binding var findRegex: Bool
    @Binding var findExtended: Bool
    @Binding var findMatchCase: Bool
    @Binding var findWholeWord: Bool
    var findMatches: [FindMatch]
    @Binding var selectedRange: NSRange
    @Binding var secondarySelectedRange: NSRange
    var onCloseTab: (UUID) -> Void
    var onFindNext: () -> Void
    var onFindPrevious: () -> Void
    var onReplace: () -> Void
    var onReplaceAll: () -> Void
    var onBookmarkAll: () -> Void
    var onOpenWorkspaceFile: (URL) -> Void
    var onGoToSymbol: (Int) -> Void

    @State private var primaryScrollTarget: Int?
    @State private var secondaryScrollTarget: Int?
    @State private var isSyncingScroll = false

    @State private var mapVisibleLine = 1

    private var insertMode: Bool {
        !(collection.activeDocument?.isOverwriteMode ?? false)
    }

    var body: some View {
        HStack(spacing: 0) {
            if sidebarState.showDocumentList {
                ResizableSidePanel(
                    width: $sidebarState.documentListWidth,
                    minWidth: 140,
                    handleEdge: .trailing
                ) {
                    DocumentListPanel(
                        collection: collection,
                        tabGroups: tabGroups,
                        onActivate: { id in collection.activateDocument(id) },
                        onClose: onCloseTab,
                        onClosePanel: { sidebarState.showDocumentList = false }
                    )
                }
            }

            if sidebarState.showWorkspace {
                ResizableSidePanel(
                    width: $sidebarState.workspaceWidth,
                    minWidth: 140,
                    handleEdge: .trailing
                ) {
                    WorkspacePanel(
                        workspace: workspace,
                        onOpenFile: onOpenWorkspaceFile,
                        onClose: { sidebarState.showWorkspace = false }
                    )
                }
            }

            if settings.tabBarStyle == .vertical {
                ResizableSidePanel(
                    width: $sidebarState.verticalTabBarWidth,
                    minWidth: 100,
                    maxWidth: 320,
                    handleEdge: .trailing
                ) {
                    TabStripView(
                        collection: collection,
                        tabGroups: tabGroups,
                        settings: settings,
                        splitState: splitState,
                        onClose: onCloseTab
                    )
                }
            }

            VStack(spacing: 0) {
                if settings.tabBarStyle != .vertical {
                    TabStripView(
                        collection: collection,
                        tabGroups: tabGroups,
                        settings: settings,
                        splitState: splitState,
                        onClose: onCloseTab
                    )
                }

                if showFindBar {
                    FindReplaceBarView(
                        findPattern: $findPattern,
                        replacePattern: $replacePattern,
                        isRegex: $findRegex,
                        isExtended: $findExtended,
                        matchCase: $findMatchCase,
                        wholeWord: $findWholeWord,
                        matchCount: findMatches.count,
                        onFindNext: onFindNext,
                        onFindPrevious: onFindPrevious,
                        onReplace: onReplace,
                        onReplaceAll: onReplaceAll,
                        onBookmarkAll: onBookmarkAll,
                        onClose: { showFindBar = false }
                    )
                }

                if showIncrementalSearch {
                    IncrementalSearchBar(
                        pattern: $incrementalPattern,
                        matchCase: $incrementalMatchCase,
                        matchCount: incrementalMatchCount,
                        onNext: onIncrementalNext,
                        onPrevious: onIncrementalPrevious,
                        onClose: { showIncrementalSearch = false }
                    )
                }

                editorArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)

                StatusBarView(
                    document: collection.activeDocument,
                    languageLabel: collection.activeDocument.map {
                        LanguageDisplay.name(for: $0, userLanguages: userLanguageStore.languages)
                    },
                    matchCount: findMatches.count,
                    wordWrap: settings.wordWrap,
                    insertMode: insertMode,
                    gitBranch: gitBranch,
                    largeFileMode: collection.activeDocument?.isLargeFileMode ?? false
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if sidebarState.showDocumentMap {
                ResizableSidePanel(
                    width: $sidebarState.documentMapWidth,
                    minWidth: 56,
                    maxWidth: 200,
                    handleEdge: .leading
                ) {
                    DocumentMapPanel(
                        document: collection.activeDocument,
                        visibleLine: mapVisibleLine,
                        onGoToLine: { line in
                            if let id = collection.activeDocumentID,
                               let range = collection.goToLine(in: id, line: line) {
                                selectedRange = range
                            }
                        },
                        onClose: { sidebarState.showDocumentMap = false }
                    )
                }
            }

            if sidebarState.showGitPanel {
                ResizableSidePanel(
                    width: $sidebarState.gitPanelWidth,
                    minWidth: 200,
                    handleEdge: .leading
                ) {
                    GitPanel(
                        repoRoot: gitRepoRoot,
                        branch: gitBranch,
                        statuses: gitStatuses,
                        diffText: gitDiff,
                        blameText: gitBlame,
                        commitStatus: gitCommitStatus,
                        onStage: onGitStage,
                        onCommit: onGitCommit,
                        onRefresh: onGitRefresh,
                        onOpenRepository: onGitOpenRepository,
                        onInitRepository: onGitInitRepository,
                        onClose: { sidebarState.showGitPanel = false }
                    )
                }
            }

            if sidebarState.showSnippets {
                ResizableSidePanel(
                    width: $sidebarState.snippetsWidth,
                    handleEdge: .leading
                ) {
                    SnippetsPanel(
                        store: snippetStore,
                        onInsert: onInsertSnippet,
                        onClose: { sidebarState.showSnippets = false }
                    )
                }
            }

            if sidebarState.showRecentFiles {
                ResizableSidePanel(
                    width: $sidebarState.recentFilesWidth,
                    handleEdge: .leading
                ) {
                    RecentFilesPanel(
                        collection: collection,
                        onOpen: { url in try? collection.open(url: url) },
                        onClose: { sidebarState.showRecentFiles = false }
                    )
                }
            }

            if sidebarState.showCharacterPanel {
                ResizableSidePanel(
                    width: $sidebarState.characterPanelWidth,
                    handleEdge: .leading
                ) {
                    CharacterInsertPanel(
                        onInsert: { onInsertCharacter?($0) },
                        onClose: { sidebarState.showCharacterPanel = false }
                    )
                }
            }

            if sidebarState.showHexView {
                ResizableSidePanel(
                    width: $sidebarState.hexViewWidth,
                    minWidth: 200,
                    handleEdge: .leading
                ) {
                    HexViewPanel(
                        fileURL: collection.activeDocument?.url,
                        onClose: { sidebarState.showHexView = false }
                    )
                }
            }

            if sidebarState.showProjectPanel {
                ResizableSidePanel(
                    width: $sidebarState.projectPanelWidth,
                    handleEdge: .leading
                ) {
                    ProjectPanel(
                        collection: collection,
                        tabGroups: tabGroups,
                        workspace: workspace,
                        onSaveProject: { onSaveProject?() },
                        onOpenProject: { onOpenProject?() },
                        onActivateFile: { url in try? collection.open(url: url) },
                        onClose: { sidebarState.showProjectPanel = false }
                    )
                }
            }

            if sidebarState.showFunctionList {
                ResizableSidePanel(
                    width: $sidebarState.functionListWidth,
                    handleEdge: .leading
                ) {
                    FunctionListPanel(
                        document: collection.activeDocument,
                        onGoToSymbol: onGoToSymbol,
                        onInsertStub: onInsertFunctionStub,
                        onClose: { sidebarState.showFunctionList = false }
                    )
                }
            }
        }
    }

    private func handleSelectionChange(documentID: UUID, pane: EditorPane, line: Int, column: Int) {
        if splitState.focusedPane != pane {
            splitState.focusedPane = pane
        }
        if collection.activeDocumentID != documentID {
            collection.activateDocument(documentID, inPane: pane, splitState: splitState)
        }
        collection.updateCaret(in: documentID, line: line, column: column)
        mapVisibleLine = line
    }

    private func handleScroll(from pane: EditorPane, line: Int) {
        guard splitState.syncScroll, splitState.isClone, !isSyncingScroll else { return }
        isSyncingScroll = true
        if pane == .primary {
            secondaryScrollTarget = line
        } else {
            primaryScrollTarget = line
        }
        isSyncingScroll = false
    }

    private func bookmarks(for documentID: UUID) -> [Bookmark] {
        collection.document(for: documentID)?.bookmarks ?? []
    }

    @ViewBuilder
    private var editorArea: some View {
        let primaryID = splitState.documentID(for: .primary, activeDocumentID: collection.activeDocumentID)
        let secondaryID = splitState.documentID(for: .secondary, activeDocumentID: collection.activeDocumentID)
        let highlights = findMatches.compactMap { match -> NSRange? in
            guard let text = collection.activeDocument?.text else { return nil }
            return NSRange(match.range, in: text)
        }

        switch splitState.orientation {
        case .none:
            if let primaryID {
                EditorPaneView(
                    collection: collection,
                    settings: settings,
                    userLanguageStore: userLanguageStore,
                    snippets: snippetStore.snippets,
                    documentID: primaryID,
                    selectedRange: $selectedRange,
                    highlightRanges: highlights,
                    bookmarks: bookmarks(for: primaryID),
                    isFocused: splitState.focusedPane == .primary,
                    scrollToLine: nil,
                    onFocus: { splitState.focusedPane = .primary },
                    onTextChange: { collection.updateDocument(primaryID, text: $0) },
                    onSelectionChange: { line, col in
                        handleSelectionChange(documentID: primaryID, pane: .primary, line: line, column: col)
                    },
                    onScroll: nil
                )
            } else {
                Spacer()
            }
        case .horizontal:
            ResizableVSplit(ratio: $splitState.splitRatio) {
                paneView(
                    id: primaryID,
                    range: $selectedRange,
                    pane: .primary,
                    highlights: highlights,
                    scrollToLine: primaryScrollTarget
                )
            } bottom: {
                paneView(
                    id: secondaryID,
                    range: $secondarySelectedRange,
                    pane: .secondary,
                    highlights: highlights,
                    scrollToLine: secondaryScrollTarget
                )
            }
        case .vertical:
            ResizableHSplit(ratio: $splitState.splitRatio) {
                paneView(
                    id: primaryID,
                    range: $selectedRange,
                    pane: .primary,
                    highlights: highlights,
                    scrollToLine: primaryScrollTarget
                )
            } trailing: {
                paneView(
                    id: secondaryID,
                    range: $secondarySelectedRange,
                    pane: .secondary,
                    highlights: highlights,
                    scrollToLine: secondaryScrollTarget
                )
            }
        }
    }

    @ViewBuilder
    private func paneView(
        id: UUID?,
        range: Binding<NSRange>,
        pane: EditorPane,
        highlights: [NSRange],
        scrollToLine: Int?
    ) -> some View {
        if let id {
            VStack(spacing: 0) {
                if splitState.orientation != .none {
                    if splitState.isClone {
                        SplitPaneHeaderView(
                            pane: pane,
                            documentName: collection.document(for: id)?.displayName ?? "Untitled",
                            isClone: true,
                            syncScroll: $splitState.syncScroll,
                            onClosePane: { splitState.closeSplit() }
                        )
                    } else {
                        PaneTabStrip(
                            collection: collection,
                            splitState: splitState,
                            tabGroups: tabGroups,
                            pane: pane,
                            activeDocumentID: id,
                            onSelect: { docID in
                                splitState.activate(documentID: docID, in: pane)
                                collection.activateDocument(docID, inPane: pane, splitState: splitState)
                            },
                            onClose: onCloseTab,
                            onMoveToOtherView: { moveToOtherView(from: pane) },
                            onCloseSplit: { splitState.closeSplit() }
                        )
                    }
                }
                EditorPaneView(
                collection: collection,
                settings: settings,
                userLanguageStore: userLanguageStore,
                snippets: snippetStore.snippets,
                documentID: id,
                selectedRange: range,
                highlightRanges: highlights,
                bookmarks: bookmarks(for: id),
                isFocused: splitState.focusedPane == pane,
                scrollToLine: scrollToLine,
                onFocus: { splitState.focusedPane = pane },
                onTextChange: { collection.updateDocument(id, text: $0) },
                onSelectionChange: { line, col in
                    handleSelectionChange(documentID: id, pane: pane, line: line, column: col)
                },
                onScroll: splitState.syncScroll ? { handleScroll(from: pane, line: $0) } : nil
            )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Spacer()
        }
    }

    private func moveToOtherView(from pane: EditorPane) {
        guard splitState.orientation != .none, !splitState.isClone else { return }
        let sourceID = splitState.documentID(for: pane, activeDocumentID: collection.activeDocumentID)
        let otherPane: EditorPane = pane == .primary ? .secondary : .primary
        let otherID = splitState.documentID(for: otherPane, activeDocumentID: collection.activeDocumentID)
        guard let sourceID else { return }
        splitState.activate(documentID: otherID ?? sourceID, in: pane)
        splitState.activate(documentID: sourceID, in: otherPane)
        collection.activateDocument(sourceID, inPane: otherPane, splitState: splitState)
    }
}
