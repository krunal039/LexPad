import LexPadCore
import SwiftUI

struct EditorSplitNotificationsModifier: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var splitState: SplitViewState
    @ObservedObject var sidebarState: SidebarState
    @ObservedObject var workspace: WorkspaceStore
    @ObservedObject var tabGroups: TabGroupStore
    @Binding var secondarySelectedRange: NSRange

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSplitHorizontal)) { _ in
                splitState.openSplit(
                    .horizontal,
                    clone: false,
                    activeDocumentID: collection.activeDocumentID,
                    otherDocumentIDs: collection.documents.map(\.id)
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSplitVertical)) { _ in
                splitState.openSplit(
                    .vertical,
                    clone: false,
                    activeDocumentID: collection.activeDocumentID,
                    otherDocumentIDs: collection.documents.map(\.id)
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadCloneDocument)) { _ in
                splitState.openSplit(
                    .vertical,
                    clone: true,
                    activeDocumentID: collection.activeDocumentID,
                    otherDocumentIDs: collection.documents.map(\.id)
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadCloseSplit)) { _ in
                splitState.closeSplit()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleWorkspace)) { _ in
                sidebarState.showWorkspace.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleFunctionList)) { _ in
                sidebarState.showFunctionList.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadOpenFolder)) { _ in
                openFolder()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSave)) { _ in
                AppController.shared.saveDocument()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleSyncScroll)) { _ in
                splitState.syncScroll.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleDocumentList)) { _ in
                sidebarState.showDocumentList.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleDocumentMap)) { _ in
                sidebarState.showDocumentMap.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadGroupTabsByFolder)) { _ in
                tabGroups.mode = .byFolder
                tabGroups.persist()
                sidebarState.showDocumentList = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadNewTabGroup)) { _ in
                if let id = collection.activeDocumentID {
                    _ = tabGroups.createGroup(documentIDs: [id])
                } else {
                    _ = tabGroups.createGroup()
                }
                tabGroups.mode = .byGroup
                sidebarState.showDocumentList = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadMoveToOtherView)) { _ in
                moveToOtherView()
            }
    }

    private func moveToOtherView() {
        guard splitState.orientation != .none, !splitState.isClone else { return }
        let pane = splitState.focusedPane
        let sourceID = splitState.documentID(for: pane, activeDocumentID: collection.activeDocumentID)
        let otherPane: EditorPane = pane == .primary ? .secondary : .primary
        let otherID = splitState.documentID(for: otherPane, activeDocumentID: collection.activeDocumentID)
        guard let sourceID else { return }
        splitState.activate(documentID: otherID ?? sourceID, in: pane)
        splitState.activate(documentID: sourceID, in: otherPane)
        collection.activateDocument(sourceID, inPane: otherPane, splitState: splitState)
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        workspace.openFolder(url)
        sidebarState.showWorkspace = true
    }
}
