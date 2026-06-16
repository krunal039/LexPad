import Foundation
import SwiftUI

public struct SessionDocument: Codable, Sendable {
    public var id: UUID
    public var url: String?
    public var language: String
    public var userLanguageID: String?
    public var caretLine: Int
    public var caretColumn: Int
    public var untitledText: String?
    public var displayName: String?

    public init(
        id: UUID,
        url: String?,
        language: String,
        userLanguageID: String? = nil,
        caretLine: Int,
        caretColumn: Int,
        untitledText: String? = nil,
        displayName: String? = nil
    ) {
        self.id = id
        self.url = url
        self.language = language
        self.userLanguageID = userLanguageID
        self.caretLine = caretLine
        self.caretColumn = caretColumn
        self.untitledText = untitledText
        self.displayName = displayName
    }

    private enum CodingKeys: String, CodingKey {
        case id, url, language, userLanguageID, caretLine, caretColumn, untitledText, displayName
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        url = try c.decodeIfPresent(String.self, forKey: .url)
        language = try c.decode(String.self, forKey: .language)
        userLanguageID = try c.decodeIfPresent(String.self, forKey: .userLanguageID)
        caretLine = try c.decode(Int.self, forKey: .caretLine)
        caretColumn = try c.decode(Int.self, forKey: .caretColumn)
        untitledText = try c.decodeIfPresent(String.self, forKey: .untitledText)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
    }
}

public struct SessionSplitState: Codable, Sendable {
    public var orientation: SplitOrientation
    public var isClone: Bool
    public var primaryDocumentID: UUID?
    public var secondaryDocumentID: UUID?
    public var syncScroll: Bool
    public var splitRatio: Double

    public init(
        orientation: SplitOrientation = .none,
        isClone: Bool = false,
        primaryDocumentID: UUID? = nil,
        secondaryDocumentID: UUID? = nil,
        syncScroll: Bool = false,
        splitRatio: Double = 0.5
    ) {
        self.orientation = orientation
        self.isClone = isClone
        self.primaryDocumentID = primaryDocumentID
        self.secondaryDocumentID = secondaryDocumentID
        self.syncScroll = syncScroll
        self.splitRatio = splitRatio
    }
}

public struct SidebarSnapshot: Codable, Sendable {
    public var showWorkspace: Bool
    public var showFunctionList: Bool
    public var showDocumentList: Bool
    public var showDocumentMap: Bool
    public var showGitPanel: Bool
    public var showSnippets: Bool
    public var showCharacterPanel: Bool
    public var showHexView: Bool
    public var showProjectPanel: Bool
    public var showRecentFiles: Bool

    public var workspaceWidth: Double
    public var functionListWidth: Double
    public var documentListWidth: Double
    public var documentMapWidth: Double
    public var gitPanelWidth: Double
    public var snippetsWidth: Double
    public var characterPanelWidth: Double
    public var hexViewWidth: Double
    public var projectPanelWidth: Double
    public var recentFilesWidth: Double

    public init(
        showWorkspace: Bool,
        showFunctionList: Bool,
        showDocumentList: Bool,
        showDocumentMap: Bool,
        showGitPanel: Bool,
        showSnippets: Bool,
        showCharacterPanel: Bool,
        showHexView: Bool,
        showProjectPanel: Bool,
        showRecentFiles: Bool,
        workspaceWidth: Double,
        functionListWidth: Double,
        documentListWidth: Double,
        documentMapWidth: Double,
        gitPanelWidth: Double,
        snippetsWidth: Double,
        characterPanelWidth: Double,
        hexViewWidth: Double,
        projectPanelWidth: Double,
        recentFilesWidth: Double
    ) {
        self.showWorkspace = showWorkspace
        self.showFunctionList = showFunctionList
        self.showDocumentList = showDocumentList
        self.showDocumentMap = showDocumentMap
        self.showGitPanel = showGitPanel
        self.showSnippets = showSnippets
        self.showCharacterPanel = showCharacterPanel
        self.showHexView = showHexView
        self.showProjectPanel = showProjectPanel
        self.showRecentFiles = showRecentFiles
        self.workspaceWidth = workspaceWidth
        self.functionListWidth = functionListWidth
        self.documentListWidth = documentListWidth
        self.documentMapWidth = documentMapWidth
        self.gitPanelWidth = gitPanelWidth
        self.snippetsWidth = snippetsWidth
        self.characterPanelWidth = characterPanelWidth
        self.hexViewWidth = hexViewWidth
        self.projectPanelWidth = projectPanelWidth
        self.recentFilesWidth = recentFilesWidth
    }

    @MainActor
    init(_ sidebarState: SidebarState) {
        self.showWorkspace = sidebarState.showWorkspace
        self.showFunctionList = sidebarState.showFunctionList
        self.showDocumentList = sidebarState.showDocumentList
        self.showDocumentMap = sidebarState.showDocumentMap
        self.showGitPanel = sidebarState.showGitPanel
        self.showSnippets = sidebarState.showSnippets
        self.showCharacterPanel = sidebarState.showCharacterPanel
        self.showHexView = sidebarState.showHexView
        self.showProjectPanel = sidebarState.showProjectPanel
        self.showRecentFiles = sidebarState.showRecentFiles
        self.workspaceWidth = Double(sidebarState.workspaceWidth)
        self.functionListWidth = Double(sidebarState.functionListWidth)
        self.documentListWidth = Double(sidebarState.documentListWidth)
        self.documentMapWidth = Double(sidebarState.documentMapWidth)
        self.gitPanelWidth = Double(sidebarState.gitPanelWidth)
        self.snippetsWidth = Double(sidebarState.snippetsWidth)
        self.characterPanelWidth = Double(sidebarState.characterPanelWidth)
        self.hexViewWidth = Double(sidebarState.hexViewWidth)
        self.projectPanelWidth = Double(sidebarState.projectPanelWidth)
        self.recentFilesWidth = Double(sidebarState.recentFilesWidth)
    }
}

public struct EditorSession: Codable, Sendable {
    public var documents: [SessionDocument]
    public var activeDocumentID: UUID?
    public var activeIndex: Int
    public var tabGroups: [TabGroup]
    public var tabGroupingMode: TabGroupingMode
    public var split: SessionSplitState?
    public var sidebar: SidebarSnapshot?
    public var savedAt: Date?

    public init(
        documents: [SessionDocument],
        activeDocumentID: UUID?,
        activeIndex: Int,
        tabGroups: [TabGroup] = [],
        tabGroupingMode: TabGroupingMode = .flat,
        split: SessionSplitState? = nil,
        sidebar: SidebarSnapshot? = nil,
        savedAt: Date? = nil
    ) {
        self.documents = documents
        self.activeDocumentID = activeDocumentID
        self.activeIndex = activeIndex
        self.tabGroups = tabGroups
        self.tabGroupingMode = tabGroupingMode
        self.split = split
        self.sidebar = sidebar
        self.savedAt = savedAt
    }

    private enum CodingKeys: String, CodingKey {
        case documents, activeDocumentID, activeIndex, tabGroups, tabGroupingMode, split, sidebar, savedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        documents = try c.decode([SessionDocument].self, forKey: .documents)
        activeDocumentID = try c.decodeIfPresent(UUID.self, forKey: .activeDocumentID)
        activeIndex = try c.decodeIfPresent(Int.self, forKey: .activeIndex) ?? 0
        tabGroups = try c.decodeIfPresent([TabGroup].self, forKey: .tabGroups) ?? []
        tabGroupingMode = try c.decodeIfPresent(TabGroupingMode.self, forKey: .tabGroupingMode) ?? .flat
        split = try c.decodeIfPresent(SessionSplitState.self, forKey: .split)
        sidebar = try c.decodeIfPresent(SidebarSnapshot.self, forKey: .sidebar)
        savedAt = try c.decodeIfPresent(Date.self, forKey: .savedAt)
    }
}

public enum SessionStore {
    private static let maxUntitledBytes = 512 * 1024

    private static var sessionURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("LexPad", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session.json")
    }

    private static var crashSessionURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("LexPad", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session_crash.json")
    }

    @MainActor
    public static func save(
        from collection: DocumentCollection,
        tabGroups: TabGroupStore? = nil,
        splitState: SplitViewState? = nil,
        sidebarState: SidebarState? = nil
    ) {
        let docs = collection.documents.map { doc -> SessionDocument in
            var untitledText: String?
            if doc.url == nil, !doc.text.isEmpty {
                let capped = String(doc.text.prefix(maxUntitledBytes))
                untitledText = capped
            }
            return SessionDocument(
                id: doc.id,
                url: doc.url?.path,
                language: doc.language.rawValue,
                userLanguageID: doc.userLanguageID,
                caretLine: doc.caret.line,
                caretColumn: doc.caret.column,
                untitledText: untitledText,
                displayName: doc.url == nil ? doc.untitledName : nil
            )
        }
        let activeIndex = collection.documents.firstIndex { $0.id == collection.activeDocumentID } ?? 0
        var split: SessionSplitState?
        if let splitState, splitState.orientation != .none {
            split = SessionSplitState(
                orientation: splitState.orientation,
                isClone: splitState.isClone,
                primaryDocumentID: splitState.primaryDocumentID,
                secondaryDocumentID: splitState.secondaryDocumentID,
                syncScroll: splitState.syncScroll,
                splitRatio: Double(splitState.splitRatio)
            )
        }
        let session = EditorSession(
            documents: docs,
            activeDocumentID: collection.activeDocumentID,
            activeIndex: activeIndex,
            tabGroups: tabGroups?.groups ?? [],
            tabGroupingMode: tabGroups?.mode ?? .flat,
            split: split,
            sidebar: sidebarState.map { SidebarSnapshot($0) },
            savedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(session) else { return }
        try? data.write(to: sessionURL, options: .atomic)
    }

    public static func hasCrashSnapshot() -> Bool {
        FileManager.default.fileExists(atPath: crashSessionURL.path)
    }

    public static func clearCrashSnapshot() {
        try? FileManager.default.removeItem(at: crashSessionURL)
    }

    @MainActor
    public static func saveCrash(
        from collection: DocumentCollection,
        tabGroups: TabGroupStore? = nil,
        splitState: SplitViewState? = nil,
        sidebarState: SidebarState? = nil
    ) {
        let docs = collection.documents.map { doc -> SessionDocument in
            var untitledText: String?
            if doc.url == nil, !doc.text.isEmpty {
                let capped = String(doc.text.prefix(maxUntitledBytes))
                untitledText = capped
            }
            return SessionDocument(
                id: doc.id,
                url: doc.url?.path,
                language: doc.language.rawValue,
                userLanguageID: doc.userLanguageID,
                caretLine: doc.caret.line,
                caretColumn: doc.caret.column,
                untitledText: untitledText,
                displayName: doc.url == nil ? doc.untitledName : nil
            )
        }
        let activeIndex = collection.documents.firstIndex { $0.id == collection.activeDocumentID } ?? 0
        var split: SessionSplitState?
        if let splitState, splitState.orientation != .none {
            split = SessionSplitState(
                orientation: splitState.orientation,
                isClone: splitState.isClone,
                primaryDocumentID: splitState.primaryDocumentID,
                secondaryDocumentID: splitState.secondaryDocumentID,
                syncScroll: splitState.syncScroll,
                splitRatio: Double(splitState.splitRatio)
            )
        }
        let session = EditorSession(
            documents: docs,
            activeDocumentID: collection.activeDocumentID,
            activeIndex: activeIndex,
            tabGroups: tabGroups?.groups ?? [],
            tabGroupingMode: tabGroups?.mode ?? .flat,
            split: split,
            sidebar: sidebarState.map { SidebarSnapshot($0) },
            savedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(session) else { return }
        try? data.write(to: crashSessionURL, options: .atomic)
    }

    @MainActor
    @discardableResult
    public static func restoreCrash(
        into collection: DocumentCollection,
        tabGroups: TabGroupStore? = nil,
        splitState: SplitViewState? = nil,
        sidebarState: SidebarState? = nil
    ) -> Bool {
        guard let data = try? Data(contentsOf: crashSessionURL),
              let session = try? JSONDecoder().decode(EditorSession.self, from: data),
              !session.documents.isEmpty else { return false }

        collection.clearAll()
        for doc in session.documents {
            if let path = doc.url, FileManager.default.fileExists(atPath: path) {
                let url = URL(fileURLWithPath: path)
                try? collection.open(url: url, documentID: doc.id)
                applySessionMetadata(doc, in: collection)
                RecentFilesStore.rememberEntry(url)
            } else if doc.url == nil, let text = doc.untitledText {
                collection.restoreUntitled(
                    id: doc.id,
                    text: text,
                    language: EditorLanguage(rawValue: doc.language) ?? .normal_lang,
                    userLanguageID: doc.userLanguageID,
                    caret: CaretPosition(line: doc.caretLine, column: doc.caretColumn),
                    untitledName: doc.displayName
                )
            }
        }

        if collection.documents.isEmpty { return false }

        if let activeID = session.activeDocumentID,
           collection.documents.contains(where: { $0.id == activeID }) {
            collection.activeDocumentID = activeID
        } else if session.activeIndex < collection.documents.count {
            collection.activeDocumentID = collection.documents[session.activeIndex].id
        } else {
            collection.activeDocumentID = collection.documents.first?.id
        }

        if let tabGroups {
            tabGroups.groups = session.tabGroups
            tabGroups.mode = session.tabGroupingMode
            tabGroups.persist()
        }

        if let splitState, let split = session.split {
            splitState.orientation = split.orientation
            splitState.isClone = split.isClone
            splitState.primaryDocumentID = split.primaryDocumentID
            splitState.secondaryDocumentID = split.secondaryDocumentID
            splitState.syncScroll = split.syncScroll
            splitState.splitRatio = CGFloat(split.splitRatio)
        }

        if let sidebarState, let sidebar = session.sidebar {
            sidebarState.showWorkspace = sidebar.showWorkspace
            sidebarState.showFunctionList = sidebar.showFunctionList
            sidebarState.showDocumentList = sidebar.showDocumentList
            sidebarState.showDocumentMap = sidebar.showDocumentMap
            sidebarState.showGitPanel = sidebar.showGitPanel
            sidebarState.showSnippets = sidebar.showSnippets
            sidebarState.showCharacterPanel = sidebar.showCharacterPanel
            sidebarState.showHexView = sidebar.showHexView
            sidebarState.showProjectPanel = sidebar.showProjectPanel
            sidebarState.showRecentFiles = sidebar.showRecentFiles

            sidebarState.workspaceWidth = CGFloat(sidebar.workspaceWidth)
            sidebarState.functionListWidth = CGFloat(sidebar.functionListWidth)
            sidebarState.documentListWidth = CGFloat(sidebar.documentListWidth)
            sidebarState.documentMapWidth = CGFloat(sidebar.documentMapWidth)
            sidebarState.gitPanelWidth = CGFloat(sidebar.gitPanelWidth)
            sidebarState.snippetsWidth = CGFloat(sidebar.snippetsWidth)
            sidebarState.characterPanelWidth = CGFloat(sidebar.characterPanelWidth)
            sidebarState.hexViewWidth = CGFloat(sidebar.hexViewWidth)
            sidebarState.projectPanelWidth = CGFloat(sidebar.projectPanelWidth)
            sidebarState.recentFilesWidth = CGFloat(sidebar.recentFilesWidth)
        }

        collection.recentFiles = RecentFilesStore.load()
        return true
    }

    @MainActor
    @discardableResult
    public static func restore(
        into collection: DocumentCollection,
        tabGroups: TabGroupStore? = nil,
        splitState: SplitViewState? = nil,
        sidebarState: SidebarState? = nil
    ) -> Bool {
        guard let data = try? Data(contentsOf: sessionURL),
              let session = try? JSONDecoder().decode(EditorSession.self, from: data),
              !session.documents.isEmpty else { return false }

        collection.clearAll()
        for doc in session.documents {
            if let path = doc.url, FileManager.default.fileExists(atPath: path) {
                let url = URL(fileURLWithPath: path)
                try? collection.open(url: url, documentID: doc.id)
                applySessionMetadata(doc, in: collection)
                RecentFilesStore.rememberEntry(url)
            } else if doc.url == nil, let text = doc.untitledText {
                collection.restoreUntitled(
                    id: doc.id,
                    text: text,
                    language: EditorLanguage(rawValue: doc.language) ?? .normal_lang,
                    userLanguageID: doc.userLanguageID,
                    caret: CaretPosition(line: doc.caretLine, column: doc.caretColumn),
                    untitledName: doc.displayName
                )
            }
        }

        if collection.documents.isEmpty { return false }

        if let activeID = session.activeDocumentID,
           collection.documents.contains(where: { $0.id == activeID }) {
            collection.activeDocumentID = activeID
        } else if session.activeIndex < collection.documents.count {
            collection.activeDocumentID = collection.documents[session.activeIndex].id
        } else {
            collection.activeDocumentID = collection.documents.first?.id
        }

        if let tabGroups {
            tabGroups.groups = session.tabGroups
            tabGroups.mode = session.tabGroupingMode
            tabGroups.persist()
        }

        if let splitState, let split = session.split {
            splitState.orientation = split.orientation
            splitState.isClone = split.isClone
            splitState.primaryDocumentID = split.primaryDocumentID
            splitState.secondaryDocumentID = split.secondaryDocumentID
            splitState.syncScroll = split.syncScroll
            splitState.splitRatio = CGFloat(split.splitRatio)
        }

        if let sidebarState, let sidebar = session.sidebar {
            sidebarState.showWorkspace = sidebar.showWorkspace
            sidebarState.showFunctionList = sidebar.showFunctionList
            sidebarState.showDocumentList = sidebar.showDocumentList
            sidebarState.showDocumentMap = sidebar.showDocumentMap
            sidebarState.showGitPanel = sidebar.showGitPanel
            sidebarState.showSnippets = sidebar.showSnippets
            sidebarState.showCharacterPanel = sidebar.showCharacterPanel
            sidebarState.showHexView = sidebar.showHexView
            sidebarState.showProjectPanel = sidebar.showProjectPanel
            sidebarState.showRecentFiles = sidebar.showRecentFiles

            sidebarState.workspaceWidth = CGFloat(sidebar.workspaceWidth)
            sidebarState.functionListWidth = CGFloat(sidebar.functionListWidth)
            sidebarState.documentListWidth = CGFloat(sidebar.documentListWidth)
            sidebarState.documentMapWidth = CGFloat(sidebar.documentMapWidth)
            sidebarState.gitPanelWidth = CGFloat(sidebar.gitPanelWidth)
            sidebarState.snippetsWidth = CGFloat(sidebar.snippetsWidth)
            sidebarState.characterPanelWidth = CGFloat(sidebar.characterPanelWidth)
            sidebarState.hexViewWidth = CGFloat(sidebar.hexViewWidth)
            sidebarState.projectPanelWidth = CGFloat(sidebar.projectPanelWidth)
            sidebarState.recentFilesWidth = CGFloat(sidebar.recentFilesWidth)
        }

        collection.recentFiles = RecentFilesStore.load()
        return true
    }

    @MainActor
    private static func applySessionMetadata(_ sessionDoc: SessionDocument, in collection: DocumentCollection) {
        guard var doc = collection.document(for: sessionDoc.id) else { return }
        doc.language = EditorLanguage(rawValue: sessionDoc.language) ?? doc.language
        doc.userLanguageID = sessionDoc.userLanguageID
        doc.caret = CaretPosition(line: sessionDoc.caretLine, column: sessionDoc.caretColumn)
        collection.replaceDocument(doc)
    }
}
