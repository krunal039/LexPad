import Foundation
import SwiftUI

public enum SplitOrientation: String, Sendable, CaseIterable, Codable {
    case none
    case horizontal
    case vertical

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical"
        }
    }
}

public enum EditorPane: String, Sendable {
    case primary
    case secondary
}

@MainActor
public final class SplitViewState: ObservableObject {
    @Published public var orientation: SplitOrientation = .none
    @Published public var isClone = false
    @Published public var secondaryDocumentID: UUID?
    @Published public var primaryDocumentID: UUID?
    @Published public var focusedPane: EditorPane = .primary
    @Published public var syncScroll = false
    @Published public var splitRatio: CGFloat = 0.5

    public init() {}

    public func openSplit(_ orientation: SplitOrientation, clone: Bool, activeDocumentID: UUID?, otherDocumentIDs: [UUID] = []) {
        self.orientation = orientation
        isClone = clone
        syncScroll = clone
        splitRatio = 0.5
        primaryDocumentID = activeDocumentID
        if clone {
            secondaryDocumentID = activeDocumentID
        } else if secondaryDocumentID == nil || secondaryDocumentID == activeDocumentID {
            secondaryDocumentID = otherDocumentIDs.first { $0 != activeDocumentID } ?? activeDocumentID
        }
        focusedPane = .primary
    }

    public func closeSplit() {
        orientation = .none
        isClone = false
        secondaryDocumentID = nil
        primaryDocumentID = nil
        focusedPane = .primary
    }

    public func documentID(for pane: EditorPane, activeDocumentID: UUID?) -> UUID? {
        switch pane {
        case .primary:
            if isClone { return activeDocumentID }
            return primaryDocumentID ?? activeDocumentID
        case .secondary:
            if isClone { return activeDocumentID }
            return secondaryDocumentID ?? activeDocumentID
        }
    }

    public func activate(documentID: UUID, in pane: EditorPane) {
        switch pane {
        case .primary:
            primaryDocumentID = documentID
        case .secondary:
            secondaryDocumentID = documentID
        }
        focusedPane = pane
    }
}

@MainActor
public final class SidebarState: ObservableObject {
    @Published public var showWorkspace = false
    @Published public var showFunctionList = false
    @Published public var showDocumentList = false
    @Published public var showDocumentMap = false
    @Published public var showGitPanel = false
    @Published public var showSnippets = false
    @Published public var showCharacterPanel = false
    @Published public var showHexView = false
    @Published public var showProjectPanel = false
    @Published public var showRecentFiles = false
    @Published public var workspaceWidth: CGFloat = 220
    @Published public var functionListWidth: CGFloat = 240
    @Published public var documentListWidth: CGFloat = 220
    @Published public var documentMapWidth: CGFloat = 80
    @Published public var gitPanelWidth: CGFloat = 280
    @Published public var snippetsWidth: CGFloat = 200
    @Published public var characterPanelWidth: CGFloat = 200
    @Published public var hexViewWidth: CGFloat = 320
    @Published public var projectPanelWidth: CGFloat = 240
    @Published public var recentFilesWidth: CGFloat = 240
    @Published public var verticalTabBarWidth: CGFloat = 160

    public init() {}
}
