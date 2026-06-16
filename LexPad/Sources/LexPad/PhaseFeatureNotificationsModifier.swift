import LexPadCore
import SwiftUI

struct PhaseFeatureNotificationsModifier: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var settings: EditorSettings
    @ObservedObject var sidebarState: SidebarState
    @ObservedObject var tabGroups: TabGroupStore
    @ObservedObject var splitState: SplitViewState
    @ObservedObject var snippetStore: SnippetStore
    @ObservedObject var beginEndSelect: BeginEndSelectStore
    @Binding var selectedRange: NSRange
    @Binding var showEncodingPicker: Bool
    @Binding var showFindInFiles: Bool
    @Binding var fifResults: [FindInFilesResult]
    @Binding var findPattern: String
    var findOptions: () -> FindOptions
    var insertSnippet: (Snippet) -> Void
    var printDocument: () -> Void
    var runFindInProject: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadPrint)) { _ in printDocument() }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleCharacterPanel)) { _ in
                sidebarState.showCharacterPanel.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleHexView)) { _ in
                sidebarState.showHexView.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleProjectPanel)) { _ in
                sidebarState.showProjectPanel.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSetEncoding)) { _ in
                showEncodingPicker = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleBlockComment)) { _ in
                collection.toggleBlockComments(selectedRange: selectedRange)
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadBeginSelect)) { _ in
                let pos = selectedRange.location == NSNotFound ? 0 : selectedRange.location
                beginEndSelect.setBegin(at: pos)
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadEndSelect)) { _ in
                let end = selectedRange.location == NSNotFound ? 0 : selectedRange.location
                let length = (collection.activeDocument?.text as NSString?)?.length ?? 0
                if let range = beginEndSelect.selection(to: end, textLength: length) {
                    selectedRange = range
                }
                beginEndSelect.clear()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadGoToLineSelection)) { note in
                if let range = note.userInfo?["range"] as? NSRange {
                    selectedRange = range
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadFindInProject)) { _ in
                runFindInProject()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleRecentFiles)) { _ in
                sidebarState.showRecentFiles.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadClearRecentFiles)) { _ in
                collection.clearRecentFiles()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSaveSession)) { _ in
                guard settings.restoreSession else { return }
                SessionStore.save(
                    from: collection,
                    tabGroups: tabGroups,
                    splitState: splitState,
                    sidebarState: sidebarState
                )
                SessionStore.saveCrash(
                    from: collection,
                    tabGroups: tabGroups,
                    splitState: splitState,
                    sidebarState: sidebarState
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleVirtualSpace)) { _ in
                settings.virtualSpace.toggle()
                settings.persist()
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                guard settings.enableAutosave else { return }
                collection.autosaveDirtyDocuments()
                if settings.restoreSession {
                    SessionStore.save(
                        from: collection,
                        tabGroups: tabGroups,
                        splitState: splitState,
                        sidebarState: sidebarState
                    )
                    SessionStore.saveCrash(
                        from: collection,
                        tabGroups: tabGroups,
                        splitState: splitState,
                        sidebarState: sidebarState
                    )
                }
            }
    }
}
