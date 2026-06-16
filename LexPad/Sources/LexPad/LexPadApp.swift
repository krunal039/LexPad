import AppKit
import LexPadCore
import SwiftUI

@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    weak var collection: DocumentCollection?
    weak var settings: EditorSettings?
    weak var tabGroups: TabGroupStore?
    weak var splitState: SplitViewState?
    weak var sidebarState: SidebarState?

    var pendingOpenURLs: [URL] = []
    var pendingOpenLine: Int?
    var pendingOpenLanguage: EditorLanguage?

    func openURLs(_ urls: [URL], line: Int? = nil, language: EditorLanguage? = nil) {
        pendingOpenLine = line
        pendingOpenLanguage = language
        guard let collection else {
            pendingOpenURLs.append(contentsOf: urls)
            return
        }
        for url in urls {
            try? collection.open(url: url)
            if let language { collection.setActiveLanguage(language) }
            if let line, let range = collection.goToLine(line) {
                NotificationCenter.default.post(
                    name: .lexPadGoToLineSelection,
                    object: nil,
                    userInfo: ["range": range]
                )
            }
        }
        pendingOpenLine = nil
        pendingOpenLanguage = nil
    }

    func drainPendingOpenURLs() {
        guard let collection, !pendingOpenURLs.isEmpty else { return }
        let urls = pendingOpenURLs
        pendingOpenURLs = []
        for url in urls {
            try? collection.open(url: url)
        }
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.title = "Open File"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            try? collection?.open(url: url)
        }
    }

    func saveDocument() {
        guard let collection, collection.activeDocument != nil else { return }
        if collection.activeDocument?.url != nil {
            try? collection.saveActive()
            return
        }
        saveDocumentAs()
    }

    func saveDocumentAs() {
        guard let collection else { return }
        let panel = NSSavePanel()
        panel.title = "Save As"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? collection.saveActive(to: url)
    }

    func compareFiles() {
        let panel = NSOpenPanel()
        panel.title = "Select two files to compare"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, panel.urls.count >= 2 else { return }
        NotificationCenter.default.post(
            name: .lexPadCompareFiles,
            object: nil,
            userInfo: ["left": panel.urls[0], "right": panel.urls[1]]
        )
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        openCommandLineFiles()
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
        Task { @MainActor in
            AppController.shared.openURLs(urls)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func openCommandLineFiles() {
        var paths: [String] = []
        var line: Int?
        var language: EditorLanguage?
        var args = Array(CommandLine.arguments.dropFirst())
        while let first = args.first {
            if first == "--help" || first == "-h" {
                let help = """
                LexPad — native macOS text editor

                Usage:
                  LexPad [options] [file...]

                Options:
                  -n <line>       Open file and jump to line number
                  -l <language>   Set syntax language (e.g. swift, python)
                  -h, --help      Show this help

                Examples:
                  LexPad notes.txt
                  LexPad -n 42 src/main.swift
                  LexPad -l json config.json

                Documentation: docs/USER_GUIDE.md in the repository
                """
                fputs(help + "\n", stderr)
                return
            }
            if first == "-n", args.count > 1, let n = Int(args[1]) {
                line = n
                args.removeFirst(2)
                continue
            }
            if first == "-l", args.count > 1 {
                let langName = args[1]
                language = EditorLanguage.allCases.first { $0.rawValue.caseInsensitiveCompare(langName) == .orderedSame }
                    ?? EditorLanguage.allCases.first { $0.rawValue.lowercased().contains(langName.lowercased()) }
                args.removeFirst(2)
                continue
            }
            if first.hasPrefix("-") {
                args.removeFirst()
                continue
            }
            paths.append(first)
            args.removeFirst()
        }
        guard !paths.isEmpty else { return }
        let urls = paths.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
        let capturedLine = line
        let capturedLanguage = language
        Task { @MainActor in
            AppController.shared.openURLs(urls, line: capturedLine, language: capturedLanguage)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard let collection = AppController.shared.collection else { return }
        if AppController.shared.settings?.restoreSession == true {
            SessionStore.save(
                from: collection,
                tabGroups: AppController.shared.tabGroups,
                splitState: AppController.shared.splitState,
                sidebarState: AppController.shared.sidebarState
            )
        }
        SessionStore.clearCrashSnapshot()
    }
}

@main
struct LexPadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var collection = DocumentCollection()
    @StateObject private var settings = EditorSettings()
    @StateObject private var macroRecorder = MacroRecorder()
    @StateObject private var splitState = SplitViewState()
    @StateObject private var sidebarState = SidebarState()
    @StateObject private var workspace = WorkspaceStore()
    @StateObject private var shortcuts = ShortcutSettings()
    @StateObject private var tabGroups = TabGroupStore()
    @StateObject private var pluginRegistry = PluginRegistry()
    @StateObject private var snippetStore = SnippetStore()
    @StateObject private var userLanguageStore = UserLanguageStore.shared

    var body: some Scene {
        WindowGroup(id: "editor") {
            MainEditorContainer(
                collection: collection,
                settings: settings,
                macroRecorder: macroRecorder,
                splitState: splitState,
                sidebarState: sidebarState,
                workspace: workspace,
                shortcuts: shortcuts,
                tabGroups: tabGroups,
                pluginRegistry: pluginRegistry,
                snippetStore: snippetStore,
                userLanguageStore: userLanguageStore
            )
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    AppController.shared.collection = collection
                    AppController.shared.settings = settings
                    AppController.shared.tabGroups = tabGroups
                    AppController.shared.splitState = splitState
                    AppController.shared.sidebarState = sidebarState
                    if settings.restoreSession {
                        var didRecoverCrash = false
                        if SessionStore.hasCrashSnapshot() {
                            let alert = NSAlert()
                            alert.messageText = "Recover previous session?"
                            alert.informativeText = "LexPad saved an automatic recovery snapshot. Would you like to restore it?"
                            alert.addButton(withTitle: "Recover")
                            alert.addButton(withTitle: "Discard")
                            didRecoverCrash = alert.runModal() == .alertFirstButtonReturn &&
                                SessionStore.restoreCrash(
                                    into: collection,
                                    tabGroups: tabGroups,
                                    splitState: splitState,
                                    sidebarState: sidebarState
                                )
                            SessionStore.clearCrashSnapshot()
                        }

                        if !didRecoverCrash {
                            let restored = SessionStore.restore(
                                into: collection,
                                tabGroups: tabGroups,
                                splitState: splitState,
                                sidebarState: sidebarState
                            )
                            if !restored {
                                collection.bootstrapIfEmpty()
                            }
                        }
                        AppController.shared.drainPendingOpenURLs()
                    } else {
                        collection.bootstrapIfEmpty()
                        AppController.shared.drainPendingOpenURLs()
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Window") { postMacroCommand(.lexPadNewWindow) }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .newItem) {
                Button("New Tab") { postMacroCommand(.lexPadNewTab) }
                    .keyboardShortcut("t", modifiers: [.command])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Open…") { AppController.shared.openDocument() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button("Quick Open…") { postMacroCommand(.lexPadQuickOpen) }
                    .keyboardShortcut("p", modifiers: [.command])
                Button("Save") { AppController.shared.saveDocument() }
                    .keyboardShortcut("s", modifiers: [.command])
                Button("Save As…") { AppController.shared.saveDocumentAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                Button("Print…") { postMacroCommand(.lexPadPrint) }
                Button("Reopen with Encoding…") { postMacroCommand(.lexPadSetEncoding) }
                Menu("Open Recent") {
                    if collection.recentFiles.isEmpty {
                        Text("No Recent Files").disabled(true)
                    } else {
                        ForEach(collection.recentFiles, id: \.path) { url in
                            Button(url.lastPathComponent) { try? collection.open(url: url) }
                        }
                    }
                }
            }

            CommandGroup(after: .textEditing) {
                Button("Find…") { postMacroCommand(.lexPadToggleFind) }
                    .keyboardShortcut("f", modifiers: [.command])
                Button("Replace…") { postMacroCommand(.lexPadToggleReplace) }
                    .keyboardShortcut("f", modifiers: [.command, .option])
                Button("Find in Files…") { postMacroCommand(.lexPadFindInFiles) }
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                Button("Replace in Files…") { postMacroCommand(.lexPadReplaceInFiles) }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                Button("Go to Line…") { postMacroCommand(.lexPadGoToLine) }
                    .keyboardShortcut("l", modifiers: [.command])
                Button("Incremental Search") { postMacroCommand(.lexPadIncrementalSearch) }
                    .keyboardShortcut("e", modifiers: [.command])
                Button("Add Next Occurrence") { postMacroCommand(.lexPadSelectNextOccurrence) }
                    .keyboardShortcut("d", modifiers: [.command, .control])
                Button("Show Completions") { postMacroCommand(.lexPadTriggerCompletion) }
                    .keyboardShortcut(" ", modifiers: [.control])
                Divider()
                Button("Toggle Bookmark") { postMacroCommand(.lexPadToggleBookmark) }
                Button("Next Bookmark") { postMacroCommand(.lexPadNextBookmark) }
                Button("Previous Bookmark") { postMacroCommand(.lexPadPreviousBookmark) }
                Button("Bookmark All Matches") { postMacroCommand(.lexPadBookmarkAllMatches) }
                Divider()
                Menu("Mark Style") {
                    ForEach(MarkStyle.allCases) { style in
                        Button(style.menuTitle) {
                            NotificationCenter.default.post(
                                name: .lexPadSetMarkStyle,
                                object: nil,
                                userInfo: ["style": style.rawValue]
                            )
                        }
                    }
                    Divider()
                    ForEach(MarkStyle.allCases) { style in
                        Button("Clear \(style.displayName)") {
                            NotificationCenter.default.post(
                                name: .lexPadClearMarkStyle,
                                object: nil,
                                userInfo: ["style": style.rawValue]
                            )
                        }
                    }
                }
                Divider()
                Button("Toggle Comment") { postMacroCommand(.lexPadToggleComment) }
                    .keyboardShortcut("/", modifiers: [.command])
                Button("Command Palette…") { postMacroCommand(.lexPadCommandPalette) }
                    .keyboardShortcut("p", modifiers: [.command, .shift])
            }

            CommandMenu("Edit") {
                lineOpButton("Toggle Comment", .lexPadToggleComment)
                Divider()
                lineOpButton("Duplicate Line", .lexPadDuplicateLine)
                lineOpButton("Move Line Up", .lexPadMoveLineUp, "⌥↑")
                lineOpButton("Move Line Down", .lexPadMoveLineDown, "⌥↓")
                Divider()
                Menu("Sort Lines") {
                    lineOpButton("Ascending", .lexPadSortLinesAsc)
                    lineOpButton("Descending", .lexPadSortLinesDesc)
                }
                lineOpButton("Remove Duplicate Lines", .lexPadRemoveDupLines)
                lineOpButton("Remove Empty Lines", .lexPadRemoveEmptyLines)
                lineOpButton("Reverse Lines", .lexPadReverseLines)
                lineOpButton("Join Lines", .lexPadJoinLines)
                lineOpButton("Split Line", .lexPadSplitLines)
                lineOpButton("Toggle Block Comment", .lexPadToggleBlockComment)
                Divider()
                lineOpButton("Trim Trailing Whitespace", .lexPadTrimTrailing)
                lineOpButton("Trim Leading Whitespace", .lexPadTrimLeading)
                Divider()
                Menu("Convert Case") {
                    lineOpButton("UPPERCASE", .lexPadUpperCase)
                    lineOpButton("lowercase", .lexPadLowerCase)
                    lineOpButton("Proper Case", .lexPadProperCase)
                    lineOpButton("Invert Case", .lexPadInvertCase)
                }
                Divider()
                lineOpButton("Tabs to Spaces", .lexPadTabsToSpaces)
                lineOpButton("Spaces to Tabs", .lexPadSpacesToTabs)
                Divider()
                Menu("EOL Conversion") {
                    lineOpButton("Unix (LF)", .lexPadConvertEOLToLF)
                    lineOpButton("Windows (CR LF)", .lexPadConvertEOLToCRLF)
                    lineOpButton("Macintosh (CR)", .lexPadConvertEOLToCR)
                }
            }

            CommandMenu("View") {
                Toggle("Word Wrap", isOn: $settings.wordWrap)
                    .onChange(of: settings.wordWrap) { _ in settings.persist() }
                Toggle("Line Numbers", isOn: $settings.showLineNumbers)
                    .onChange(of: settings.showLineNumbers) { _ in settings.persist() }
                Toggle("Code Folding", isOn: $settings.codeFolding)
                    .onChange(of: settings.codeFolding) { _ in settings.persist() }
                Divider()
                lineOpButton("Fold All", .lexPadFoldAll)
                lineOpButton("Unfold All", .lexPadUnfoldAll)
                Divider()
                lineOpButton("Split Horizontal", .lexPadSplitHorizontal)
                lineOpButton("Split Vertical", .lexPadSplitVertical)
                lineOpButton("Clone Document", .lexPadCloneDocument)
                lineOpButton("Close Split", .lexPadCloseSplit)
                lineOpButton("Sync Scroll", .lexPadToggleSyncScroll)
                lineOpButton("Move to Other View", .lexPadMoveToOtherView)
                Divider()
                lineOpButton("Duplicate Tab", .lexPadDuplicateTab)
                lineOpButton("Pin Tab", .lexPadTogglePinTab)
                lineOpButton("Read Only", .lexPadToggleReadOnly)
                Divider()
                Menu("Tab Bar") {
                    ForEach(TabBarStyle.allCases) { style in
                        Button(style.displayName) {
                            settings.tabBarStyle = style
                            settings.persist()
                        }
                    }
                }
                Divider()
                lineOpButton("Document List", .lexPadToggleDocumentList)
                lineOpButton("Document Map", .lexPadToggleDocumentMap)
                lineOpButton("Workspace Panel", .lexPadToggleWorkspace)
                lineOpButton("Function List", .lexPadToggleFunctionList)
                lineOpButton("Open Folder as Workspace", .lexPadOpenFolder)
                Divider()
                lineOpButton("Group Tabs by Folder", .lexPadGroupTabsByFolder)
                lineOpButton("New Tab Group", .lexPadNewTabGroup)
                lineOpButton("Git Panel", .lexPadToggleGitPanel)
                lineOpButton("Snippets Panel", .lexPadToggleSnippets)
                lineOpButton("Character Panel", .lexPadToggleCharacterPanel)
                lineOpButton("Hex View", .lexPadToggleHexView)
                lineOpButton("Project Panel", .lexPadToggleProjectPanel)
                lineOpButton("Recent Files", .lexPadToggleRecentFiles)
                Divider()
                lineOpButton("Toggle Overwrite Mode", .lexPadToggleOverwrite)
                Divider()
                Menu("Appearance") {
                    lineOpButton("Style Configurator…", .lexPadShowStyleConfigurator)
                }
                Menu("Language") {
                    ForEach(EditorLanguage.allCases, id: \.self) { language in
                        Button(language.rawValue) { collection.setActiveLanguage(language) }
                    }
                    if !userLanguageStore.languages.isEmpty {
                        Divider()
                        Menu("User Defined") {
                            ForEach(userLanguageStore.languages) { udl in
                                Button(udl.name) { collection.setActiveUserLanguage(udl.id) }
                            }
                            Divider()
                            Button("Clear UDL") { collection.setActiveUserLanguage(nil) }
                        }
                    }
                }
            }

            CommandMenu("Tools") {
                Button("Compare Files…") { AppController.shared.compareFiles() }
                Button("Column Editor…") { postMacroCommand(.lexPadColumnEditor) }
                Button("Snippets Panel") { postMacroCommand(.lexPadToggleSnippets) }
                Divider()
                Button("Format JSON") { postMacroCommand(.lexPadFormatJSON) }
                Button("Format XML") { postMacroCommand(.lexPadFormatXML) }
                Menu("Plugins") {
                    ForEach(PluginManager.commands(), id: \.command.id) { entry in
                        Button(entry.command.title) {
                            NotificationCenter.default.post(
                                name: .lexPadRunPlugin,
                                object: nil,
                                userInfo: ["pluginID": entry.plugin.id, "action": entry.command.action]
                            )
                        }
                    }
                }
                Divider()
                Button("Save Project…") { postMacroCommand(.lexPadSaveProject) }
                Button("Open Project…") { postMacroCommand(.lexPadOpenProject) }
                Divider()
                Button("Plugin Manager…") { postMacroCommand(.lexPadPluginManager) }
                Button("User Defined Languages…") { postMacroCommand(.lexPadOpenUDLEditor) }
                Button("Find in Files…") { postMacroCommand(.lexPadFindInFiles) }
                Button("Find in Project…") { postMacroCommand(.lexPadFindInProject) }
                Button("Replace in Files…") { postMacroCommand(.lexPadReplaceInFiles) }
                Divider()
                Button("Record Macro") { postMacroCommand(.lexPadStartMacroRecording) }
                Button("Stop Macro Recording") { postMacroCommand(.lexPadStopMacroRecording) }
            }

            CommandGroup(replacing: .appInfo) {
                Button("About LexPad") { HelpSupport.showAbout() }
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { postMacroCommand(.lexPadShowPreferences) }
                    .keyboardShortcut(",", modifiers: [.command])
            }

            CommandGroup(replacing: .help) {
                Button("Getting Started Guide") { HelpSupport.showHelp(.gettingStarted) }
                Button("User Guide") { HelpSupport.showHelp(.userGuide) }
                Button("Keyboard Shortcuts") { HelpSupport.showHelp(.shortcuts) }
                Button("What's New in LexPad") { HelpSupport.showHelp(.changelog) }
                Divider()
                Button("Open Source Licenses") { HelpSupport.showHelp(.licenses) }
                Divider()
                Button("View Documentation on GitHub") { HelpSupport.openOnlineDocs() }
                Button("Report an Issue…") { HelpSupport.openIssues() }
            }
        }

        Window("Settings", id: "settings") {
            PreferencesView(
                settings: settings,
                shortcuts: shortcuts,
                userLanguageStore: userLanguageStore,
                pluginRegistry: pluginRegistry
            )
        }
        .defaultSize(width: 780, height: 540)
        .windowResizability(.contentMinSize)
    }

    private var colorScheme: ColorScheme? {
        switch settings.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    @ViewBuilder
    private func lineOpButton(_ title: String, _ name: Notification.Name, _ shortcut: String? = nil) -> some View {
        Button(title) { postMacroCommand(name) }
    }
}

struct MainEditorContainer: View {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var settings: EditorSettings
    @ObservedObject var macroRecorder: MacroRecorder
    @ObservedObject var splitState: SplitViewState
    @ObservedObject var sidebarState: SidebarState
    @ObservedObject var workspace: WorkspaceStore
    @ObservedObject var shortcuts: ShortcutSettings
    @ObservedObject var tabGroups: TabGroupStore
    @ObservedObject var pluginRegistry: PluginRegistry
    @ObservedObject var snippetStore: SnippetStore
    @ObservedObject var userLanguageStore: UserLanguageStore

    @State private var showIncrementalSearch = false
    @State private var incrementalPattern = ""
    @State private var incrementalMatchCase = false
    @State private var incrementalIndex = 0
    @State private var showColumnEditor = false
    @State private var showStyleConfigurator = false
    @State private var showPluginManager = false
    @State private var showUDLEditor = false
    @State private var gitBranch: String?
    @State private var gitStatuses: [GitFileStatus] = []
    @State private var gitDiff = ""
    @State private var gitBlame = ""
    @State private var gitCommitStatus = ""
    @State private var gitRepoRoot: URL?
    @State private var gitRepoOverride: URL?
    @State private var showFindBar = false
    @State private var showGoToLine = false
    @StateObject private var beginEndSelect = BeginEndSelectStore()
    @State private var showEncodingPicker = false
    @State private var showFindInFiles = false
    @State private var showFindInProject = false
    @State private var showCommandPalette = false
    @State private var showQuickOpen = false
    @State private var showMacros = false
    @State private var showDiff = false
    @State private var diffLeftTitle = ""
    @State private var diffRightTitle = ""
    @State private var diffLines: [DiffLine] = []
    @State private var findPattern = ""
    @State private var replacePattern = ""
    @State private var findRegex = false
    @State private var findExtended = false
    @State private var findMatchCase = false
    @State private var findWholeWord = false
    @State private var findMatches: [FindMatch] = []
    @State private var currentMatchIndex = 0
    @State private var selectedRange = NSRange(location: NSNotFound, length: 0)
    @State private var secondarySelectedRange = NSRange(location: NSNotFound, length: 0)
    @State private var fifDirectory: URL?
    @State private var fifFilter = "*.*"
    @State private var fifResults: [FindInFilesResult] = []
    @State private var fifSearching = false
    @State private var showReplaceInFiles = false
    @State private var rifReplacePattern = ""
    @State private var rifStatus = ""
    @StateObject private var fileMonitor = FileChangeMonitor()

    var body: some View {
        editorStack
            .background(WindowOpenBridge())
            .background(WindowFocusTracker(collection: collection))
            .modifier(editorSplitModifier)
            .modifier(editorSheetsModifier)
            .modifier(editorNavModifier)
            .modifier(EditorLineOpNotificationsModifierA(collection: collection, refreshFind: refreshFind))
            .modifier(EditorLineOpNotificationsModifierB(
                collection: collection,
                settings: settings,
                refreshFind: refreshFind,
                performEOL: performEOL
            ))
            .modifier(EditorFindChangeModifier(
                collection: collection,
                findPattern: $findPattern,
                findRegex: $findRegex,
                findExtended: $findExtended,
                findMatchCase: $findMatchCase,
                findWholeWord: $findWholeWord,
                refreshFind: refreshFind
            ))
            .modifier(editorExtensionModifier)
            .modifier(editorCompletionModifier)
            .modifier(phaseFeatureModifier)
            .modifier(TierFeatureNotificationsModifier(collection: collection, selectedRange: $selectedRange))
            .modifier(editorSheetsOverlay)
            .helpNotifications()
            .settingsNotifications()
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in handleDrop(providers) }
            .onChange(of: collection.documents.count) { _ in fileMonitor.sync(documents: collection.documents) }
            .onAppear {
                collection.enableLargeFileMode = settings.enableLargeFileMode
                collection.largeFileThresholdBytes = settings.largeFileThresholdMB * 1024 * 1024
                fileMonitor.sync(documents: collection.documents)
                AppController.shared.collection = collection
                WindowFocusRegistry.shared.focus(collection)
                AppController.shared.drainPendingOpenURLs()
            }
            .onChange(of: settings.largeFileThresholdMB) { value in
                collection.largeFileThresholdBytes = value * 1024 * 1024
            }
            .onChange(of: settings.enableLargeFileMode) { value in
                collection.enableLargeFileMode = value
            }
            .onChange(of: fileMonitor.changedURL) { url in
                guard let url,
                      collection.documents.contains(where: { $0.url == url }) else { return }
                promptReload(changedURL: url)
            }
    }

    private var editorStack: some View {
        EditorMainStack(
            collection: collection,
            settings: settings,
            splitState: splitState,
            sidebarState: sidebarState,
            workspace: workspace,
            tabGroups: tabGroups,
            userLanguageStore: userLanguageStore,
            showFindBar: $showFindBar,
            showIncrementalSearch: $showIncrementalSearch,
            incrementalPattern: $incrementalPattern,
            incrementalMatchCase: $incrementalMatchCase,
            incrementalMatchCount: incrementalMatches.count,
            gitBranch: gitBranch,
            gitRepoRoot: gitRepoRoot,
            gitStatuses: gitStatuses,
            gitDiff: gitDiff,
            gitBlame: gitBlame,
            gitCommitStatus: gitCommitStatus,
            onIncrementalNext: incrementalNext,
            onIncrementalPrevious: incrementalPrevious,
            onGitRefresh: refreshGit,
            onGitStage: stageGitFile,
            onGitCommit: commitGit,
            onGitOpenRepository: openGitRepository,
            onGitInitRepository: initGitRepository,
            snippetStore: snippetStore,
            onInsertSnippet: insertSnippet,
            onInsertFunctionStub: insertFunctionStub,
            onInsertCharacter: insertCharacter,
            onSaveProject: { postMacroCommand(.lexPadSaveProject) },
            onOpenProject: { postMacroCommand(.lexPadOpenProject) },
            findPattern: $findPattern,
            replacePattern: $replacePattern,
            findRegex: $findRegex,
            findExtended: $findExtended,
            findMatchCase: $findMatchCase,
            findWholeWord: $findWholeWord,
            findMatches: findMatches,
            selectedRange: $selectedRange,
            secondarySelectedRange: $secondarySelectedRange,
            onCloseTab: closeTab,
            onFindNext: findNext,
            onFindPrevious: findPrevious,
            onReplace: replaceCurrent,
            onReplaceAll: replaceAll,
            onBookmarkAll: bookmarkAllMatches,
            onOpenWorkspaceFile: { url in try? collection.open(url: url) },
            onGoToSymbol: { line in
                if let id = collection.activeDocumentID,
                   let range = collection.goToLine(in: id, line: line) {
                    selectedRange = range
                }
            }
        )
    }

    private var editorSplitModifier: some ViewModifier {
        EditorSplitNotificationsModifier(
            collection: collection,
            splitState: splitState,
            sidebarState: sidebarState,
            workspace: workspace,
            tabGroups: tabGroups,
            secondarySelectedRange: $secondarySelectedRange
        )
    }

    private var editorSheetsModifier: some ViewModifier {
        EditorSheetsModifier(
            showGoToLine: $showGoToLine,
            showFindInFiles: $showFindInFiles,
            showReplaceInFiles: $showReplaceInFiles,
            showCommandPalette: $showCommandPalette,
            showQuickOpen: $showQuickOpen,
            showMacros: $showMacros,
            showDiff: $showDiff,
            collection: collection,
            macroRecorder: macroRecorder,
            findPattern: $findPattern,
            replacePattern: $rifReplacePattern,
            findRegex: $findRegex,
            findMatchCase: $findMatchCase,
            fifDirectory: $fifDirectory,
            fifFilter: $fifFilter,
            fifResults: $fifResults,
            fifSearching: $fifSearching,
            rifStatus: $rifStatus,
            diffLeftTitle: diffLeftTitle,
            diffRightTitle: diffRightTitle,
            diffLines: diffLines,
            onGoToLine: { line in
                if let range = collection.goToLine(line) { selectedRange = range }
            },
            onOpenFindResult: openFindResult
        )
    }

    private var editorNavModifier: some ViewModifier {
        EditorNavNotificationsModifier(
            collection: collection,
            macroRecorder: macroRecorder,
            settings: settings,
            showFindBar: $showFindBar,
            showGoToLine: $showGoToLine,
            showFindInFiles: $showFindInFiles,
            showReplaceInFiles: $showReplaceInFiles,
            showCommandPalette: $showCommandPalette,
            showQuickOpen: $showQuickOpen,
            showMacros: $showMacros,
            showDiff: $showDiff,
            diffLeftTitle: $diffLeftTitle,
            diffRightTitle: $diffRightTitle,
            diffLines: $diffLines,
            selectedRange: $selectedRange,
            refreshFind: refreshFind,
            reloadFile: reloadFileFromDisk,
            onBookmarkAllMatches: bookmarkAllMatches
        )
    }

    private var editorExtensionModifier: some ViewModifier {
        EditorExtensionModifier(
            collection: collection,
            settings: settings,
            workspace: workspace,
            tabGroups: tabGroups,
            sidebarState: sidebarState,
            showIncrementalSearch: $showIncrementalSearch,
            incrementalPattern: $incrementalPattern,
            incrementalMatchCase: $incrementalMatchCase,
            incrementalIndex: $incrementalIndex,
            selectedRange: $selectedRange,
            showColumnEditor: $showColumnEditor,
            showStyleConfigurator: $showStyleConfigurator,
            showPluginManager: $showPluginManager,
            gitBranch: $gitBranch,
            gitStatuses: $gitStatuses,
            gitDiff: $gitDiff,
            gitBlame: $gitBlame,
            gitRepoRoot: $gitRepoRoot
        )
    }

    private var editorCompletionModifier: some ViewModifier {
        EditorCompletionNotificationsModifier(
            selectNextOccurrence: selectNextOccurrence,
            triggerCompletion: triggerCompletion,
            openUDLEditor: { showUDLEditor = true },
            insertSnippetFromNotification: { note in
                guard let id = note.userInfo?["id"] as? String,
                      let snippet = snippetStore.snippet(id: id) else { return }
                insertSnippet(snippet)
            }
        )
    }

    private var phaseFeatureModifier: some ViewModifier {
        PhaseFeatureNotificationsModifier(
            collection: collection,
            settings: settings,
            sidebarState: sidebarState,
            tabGroups: tabGroups,
            splitState: splitState,
            snippetStore: snippetStore,
            beginEndSelect: beginEndSelect,
            selectedRange: $selectedRange,
            showEncodingPicker: $showEncodingPicker,
            showFindInFiles: $showFindInFiles,
            fifResults: $fifResults,
            findPattern: $findPattern,
            findOptions: findOptions,
            insertSnippet: insertSnippet,
            printDocument: printDocument,
            runFindInProject: runFindInProject
        )
    }

    private var editorSheetsOverlay: some ViewModifier {
        EditorLocalSheetsModifier(
            showEncodingPicker: $showEncodingPicker,
            showColumnEditor: $showColumnEditor,
            showStyleConfigurator: $showStyleConfigurator,
            showPluginManager: $showPluginManager,
            showUDLEditor: $showUDLEditor,
            collection: collection,
            settings: settings,
            pluginRegistry: pluginRegistry,
            userLanguageStore: userLanguageStore,
            selectedRange: selectedRange
        )
    }

    private var incrementalMatches: [FindMatch] {
        guard let text = collection.activeDocument?.text else { return [] }
        let state = IncrementalSearchState(
            pattern: incrementalPattern,
            matchCase: incrementalMatchCase,
            currentIndex: incrementalIndex
        )
        return IncrementalSearchEngine.matches(in: text, state: state)
    }

    private func incrementalNext() {
        let count = incrementalMatches.count
        guard count > 0 else { return }
        incrementalIndex = IncrementalSearchEngine.nextIndex(matchCount: count, current: incrementalIndex)
        applyIncrementalSelection()
    }

    private func incrementalPrevious() {
        let count = incrementalMatches.count
        guard count > 0 else { return }
        incrementalIndex = IncrementalSearchEngine.previousIndex(matchCount: count, current: incrementalIndex)
        applyIncrementalSelection()
    }

    private func applyIncrementalSelection() {
        guard let text = collection.activeDocument?.text else { return }
        let state = IncrementalSearchState(
            pattern: incrementalPattern,
            matchCase: incrementalMatchCase,
            currentIndex: incrementalIndex
        )
        guard let match = IncrementalSearchEngine.currentMatch(in: text, state: state) else { return }
        selectedRange = NSRange(match.range, in: text)
    }

    private func refreshGit() {
        if let override = gitRepoOverride {
            applyGitState(for: override)
            return
        }
        guard let url = collection.activeDocument?.url else {
            gitRepoRoot = nil
            gitBranch = nil
            gitStatuses = []
            gitDiff = ""
            gitBlame = ""
            return
        }
        let root = GitService.repositoryRoot(for: url)
        guard let root else {
            gitRepoRoot = nil
            gitBranch = nil
            gitStatuses = []
            gitDiff = ""
            gitBlame = ""
            return
        }
        applyGitState(for: root, activeFile: url)
    }

    private func applyGitState(for root: URL, activeFile: URL? = nil) {
        gitRepoRoot = root
        gitBranch = GitService.currentBranch(at: root)
        gitStatuses = GitService.status(at: root)
        let fileURL = activeFile ?? collection.activeDocument?.url
        if let fileURL {
            let relative = relativeGitPath(for: fileURL, root: root)
            gitDiff = GitService.diff(for: relative, at: root)
            gitBlame = GitService.blame(for: relative, at: root)
        } else {
            gitDiff = ""
            gitBlame = ""
        }
    }

    private func openGitRepository() {
        let panel = NSOpenPanel()
        panel.title = "Open Git Repository"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        gitRepoOverride = url
        refreshGit()
    }

    private func initGitRepository() {
        let directory: URL?
        if let url = collection.activeDocument?.url {
            directory = url.deletingLastPathComponent()
        } else {
            let panel = NSOpenPanel()
            panel.title = "Initialize Git Repository"
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            guard panel.runModal() == .OK, let url = panel.url else { return }
            directory = url
        }
        guard let directory else { return }
        if GitService.initRepository(at: directory) {
            gitRepoOverride = directory
            gitCommitStatus = "✓ Repository initialized"
            refreshGit()
        } else {
            gitCommitStatus = "Failed to initialize repository"
        }
    }

    private func relativeGitPath(for file: URL, root: URL) -> String {
        let filePath = file.standardized.path
        let rootPath = root.standardized.path
        if filePath.hasPrefix(rootPath + "/") {
            return String(filePath.dropFirst(rootPath.count + 1))
        }
        return file.lastPathComponent
    }

    private func stageGitFile(_ path: String) {
        guard let root = gitRepoRoot else { return }
        _ = GitService.stage(filePath: path, at: root)
        refreshGit()
    }

    private func commitGit(_ message: String) {
        guard let root = gitRepoRoot else { return }
        let result = GitService.commit(message: message, at: root)
        gitCommitStatus = result.succeeded ? "✓ \(result.output)" : result.output
        refreshGit()
    }

    private func insertSnippet(_ snippet: Snippet) {
        guard let id = collection.activeDocumentID else { return }
        let text = collection.document(for: id)?.text ?? ""
        let result = SnippetEngine.insert(snippet.body, into: text, replacing: selectedRange)
        collection.updateDocument(id, text: result.text)
        selectedRange = result.selection
    }

    private func insertFunctionStub() {
        guard let id = collection.activeDocumentID,
              let doc = collection.document(for: id) else { return }
        let stub = FunctionStubEngine.stub(for: doc.language)
        let result = SnippetEngine.insert(stub, into: doc.text, replacing: selectedRange)
        collection.updateDocument(id, text: result.text)
        selectedRange = result.selection
    }

    private func insertCharacter(_ character: String) {
        guard let id = collection.activeDocumentID else { return }
        let text = collection.document(for: id)?.text ?? ""
        let result = SnippetEngine.insert(character, into: text, replacing: selectedRange)
        collection.updateDocument(id, text: result.text)
        selectedRange = result.selection
    }

    private func printDocument() {
        guard let doc = collection.activeDocument else { return }
        PrintSupport.print(document: doc, fontSize: CGFloat(settings.fontSize), showLineNumbers: settings.showLineNumbers)
    }

    private func runFindInProject() {
        let files = collection.projectFileURLs()
        guard !files.isEmpty, !findPattern.isEmpty else {
            showFindInFiles = true
            return
        }
        let opts = findOptions()
        Task {
            let found = (try? FindInFilesEngine.search(files: files, pattern: findPattern, options: opts)) ?? []
            await MainActor.run {
                fifResults = found
                showFindInFiles = true
            }
        }
    }

    private func selectNextOccurrence() {
        #if LEXPAD_HAS_SCINTILLA
        if ScintillaEditorSupport.isAvailable {
            NotificationCenter.default.post(
                name: .lexPadEditorAction,
                object: nil,
                userInfo: [
                    "action": "selectNext",
                    "matchCase": findMatchCase,
                    "wholeWord": findWholeWord,
                ]
            )
            return
        }
        #endif
        guard let text = collection.activeDocument?.text else { return }
        var sel = selectedRange
        if sel.location == NSNotFound { sel = NSRange(location: 0, length: 0) }
        if sel.length == 0, let word = SelectNextEngine.wordRange(at: sel.location, in: text) {
            sel = word
            selectedRange = sel
        }
        guard sel.length > 0 else { return }
        let needle = (text as NSString).substring(with: sel)
        guard let found = SelectNextEngine.nextOccurrence(
            of: needle,
            in: text,
            after: NSMaxRange(sel),
            matchCase: findMatchCase,
            wholeWord: findWholeWord
        ) else { return }
        selectedRange = found
    }

    private func triggerCompletion() {
        guard let doc = collection.activeDocument else { return }
        let text = doc.text
        let pos = selectedRange.location == NSNotFound ? (text as NSString).length : selectedRange.location
        let items = CompletionEngine.candidates(
            in: text,
            language: doc.language,
            userLanguage: userLanguageStore.language(id: doc.userLanguageID),
            caretPosition: pos
        ).map(\.label)
        #if LEXPAD_HAS_SCINTILLA
        if ScintillaEditorSupport.isAvailable {
            NotificationCenter.default.post(
                name: .lexPadEditorAction,
                object: nil,
                userInfo: ["action": "showCompletion", "items": items]
            )
            return
        }
        #endif
    }

    private func promptReload(changedURL: URL) {
        let alert = NSAlert()
        alert.messageText = "File changed on disk"
        alert.informativeText = "\"\(changedURL.lastPathComponent)\" was modified by another application."
        alert.addButton(withTitle: "Reload")
        alert.addButton(withTitle: "Keep Editor Version")
        if alert.runModal() == .alertFirstButtonReturn {
            reloadFileFromDisk()
        }
        fileMonitor.clearChange()
    }

    private func reloadFileFromDisk() {
        try? collection.reloadActiveFromDisk()
        fileMonitor.clearChange()
    }

    private func closeTab(_ id: UUID) {
        guard let doc = collection.documents.first(where: { $0.id == id }) else { return }
        if doc.isDirty {
            let alert = NSAlert()
            alert.messageText = "Save changes to \"\(doc.displayName)\"?"
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if doc.url != nil { try? collection.saveActive() }
                else { AppController.shared.saveDocumentAs() }
            } else if response == .alertThirdButtonReturn {
                return
            }
        }
        _ = collection.close(documentID: id)
        tabGroups.removeDocument(id)
        if settings.restoreSession {
            SessionStore.save(
                from: collection,
                tabGroups: tabGroups,
                splitState: splitState,
                sidebarState: sidebarState
            )
        }
    }

    private func openFindResult(_ result: FindInFilesResult) {
        showFindInFiles = false
        try? collection.open(url: result.fileURL)
        if let range = collection.goToLine(result.line) {
            selectedRange = range
        }
    }

    private func performEOL(_ eol: EndOfLine) {
        guard let doc = collection.activeDocument else { return }
        collection.replaceActiveText(LineOperations.convertEndOfLine(in: doc.text, to: eol), endOfLine: eol)
    }

    private func findOptions() -> FindOptions {
        FindOptions(
            pattern: findPattern,
            isRegex: findRegex,
            isExtended: findExtended,
            matchCase: findMatchCase,
            wholeWord: findWholeWord
        )
    }

    private func refreshFind() {
        guard showFindBar, let text = collection.activeDocument?.text, !findPattern.isEmpty else {
            findMatches = showFindBar ? [] : findMatches
            return
        }
        let options = findOptions()
        if text.utf8.count > 8 * 1024 * 1024 {
            findMatches = (try? FindEngine.findAllLineWise(in: text, options: options)) ?? []
        } else {
            findMatches = (try? FindEngine.findAll(in: text, options: options)) ?? []
        }
        if !findMatches.isEmpty {
            currentMatchIndex = min(currentMatchIndex, findMatches.count - 1)
        } else {
            currentMatchIndex = 0
        }
        updateSelectionForCurrentMatch()
    }

    private func findNext() {
        guard let text = collection.activeDocument?.text, !findPattern.isEmpty else { return }
        let cursor: Range<String.Index>?
        if selectedRange.location != NSNotFound {
            cursor = Range(NSRange(location: selectedRange.location, length: 0), in: text)
        } else {
            cursor = nil
        }
        if let match = try? FindEngine.findNext(in: text, from: cursor, options: findOptions()) {
            if let idx = findMatches.firstIndex(where: { $0.range == match.range }) {
                currentMatchIndex = idx
            }
            selectedRange = NSRange(match.range, in: text)
        } else if !findMatches.isEmpty {
            currentMatchIndex = (currentMatchIndex + 1) % findMatches.count
            updateSelectionForCurrentMatch()
        }
    }

    private func findPrevious() {
        guard !findMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + findMatches.count) % findMatches.count
        updateSelectionForCurrentMatch()
    }

    private func replaceCurrent() {
        guard findMatches.indices.contains(currentMatchIndex),
              var doc = collection.activeDocument else { return }
        let match = findMatches[currentMatchIndex]
        doc.text.replaceSubrange(match.range, with: replacePattern)
        collection.replaceActiveText(doc.text)
        refreshFind()
    }

    private func replaceAll() {
        guard let doc = collection.activeDocument else { return }
        guard let result = try? FindEngine.replaceAll(in: doc.text, options: findOptions(), replacement: replacePattern) else { return }
        collection.replaceActiveText(result.text)
        refreshFind()
    }

    private func bookmarkAllMatches() {
        guard let text = collection.activeDocument?.text else { return }
        let lines = findMatches.map { match -> Int in
            let prefix = String(text[..<match.range.lowerBound])
            return prefix.filter { $0 == "\n" }.count + 1
        }
        collection.bookmarkLines(lines, style: settings.activeMarkStyle)
    }

    private func updateSelectionForCurrentMatch() {
        guard findMatches.indices.contains(currentMatchIndex),
              let text = collection.activeDocument?.text else {
            selectedRange = NSRange(location: NSNotFound, length: 0)
            return
        }
        selectedRange = NSRange(findMatches[currentMatchIndex].range, in: text)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers where provider.hasItemConformingToTypeIdentifier("public.file-url") {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in try? collection.open(url: url) }
            }
        }
        return true
    }
}
