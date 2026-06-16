import AppKit
import LexPadCore
import SwiftUI

struct EditorExtensionModifier: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var settings: EditorSettings
    @ObservedObject var workspace: WorkspaceStore
    @ObservedObject var tabGroups: TabGroupStore
    @ObservedObject var sidebarState: SidebarState
    @Binding var showIncrementalSearch: Bool
    @Binding var incrementalPattern: String
    @Binding var incrementalMatchCase: Bool
    @Binding var incrementalIndex: Int
    @Binding var selectedRange: NSRange
    @Binding var showColumnEditor: Bool
    @Binding var showStyleConfigurator: Bool
    @Binding var showPluginManager: Bool
    @Binding var gitBranch: String?
    @Binding var gitStatuses: [GitFileStatus]
    @Binding var gitDiff: String
    @Binding var gitBlame: String
    @Binding var gitRepoRoot: URL?

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadIncrementalSearch)) { _ in
                showIncrementalSearch.toggle()
                if showIncrementalSearch { incrementalIndex = 0 }
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadColumnEditor)) { _ in
                showColumnEditor = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadShowStyleConfigurator)) { _ in
                showStyleConfigurator = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadPluginManager)) { _ in
                showPluginManager = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleGitPanel)) { _ in
                sidebarState.showGitPanel.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleSnippets)) { _ in
                sidebarState.showSnippets.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSaveProject)) { _ in
                saveProject()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadOpenProject)) { _ in
                openProject()
            }
            .onChange(of: incrementalPattern) { _ in
                incrementalIndex = 0
                applyIncrementalSelection()
            }
            .onChange(of: incrementalMatchCase) { _ in
                incrementalIndex = 0
                applyIncrementalSelection()
            }
            .onChange(of: collection.activeDocumentID) { _ in
                refreshGit()
            }
    }

    private func applyIncrementalSelection() {
        guard let text = collection.activeDocument?.text else { return }
        let state = IncrementalSearchState(pattern: incrementalPattern, matchCase: incrementalMatchCase, currentIndex: incrementalIndex)
        let matches = IncrementalSearchEngine.matches(in: text, state: state)
        guard let match = IncrementalSearchEngine.currentMatch(in: text, state: state) else {
            selectedRange = NSRange(location: NSNotFound, length: 0)
            return
        }
        selectedRange = NSRange(match.range, in: text)
        _ = matches
    }

    private func refreshGit() {
        guard let url = collection.activeDocument?.url else {
            gitRepoRoot = nil
            gitBranch = nil
            gitStatuses = []
            gitDiff = ""
            gitBlame = ""
            return
        }
        gitRepoRoot = GitService.repositoryRoot(for: url)
        guard let root = gitRepoRoot else {
            gitBranch = nil
            gitStatuses = []
            gitDiff = ""
            gitBlame = ""
            return
        }
        gitBranch = GitService.currentBranch(at: root)
        gitStatuses = GitService.status(at: root)
        if let path = relativePath(for: url, root: root) {
            gitDiff = GitService.diff(for: path, at: root)
            gitBlame = GitService.blame(for: path, at: root)
        }
    }

    private func relativePath(for file: URL, root: URL) -> String? {
        let rootPath = root.standardized.path
        let filePath = file.standardized.path
        guard filePath.hasPrefix(rootPath) else { return file.lastPathComponent }
        var relative = String(filePath.dropFirst(rootPath.count))
        if relative.hasPrefix("/") { relative.removeFirst() }
        return relative.isEmpty ? nil : relative
    }

    private func saveProject() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "project.lexproj"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let project = ProjectStore.buildProject(
            name: url.deletingPathExtension().lastPathComponent,
            from: collection,
            tabGroups: tabGroups,
            workspace: workspace
        )
        try? ProjectStore.save(project, to: url)
    }

    private func openProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, let url = panel.url,
              let project = try? ProjectStore.load(from: url) else { return }
        ProjectStore.apply(project, to: collection, tabGroups: tabGroups, workspace: workspace)
        sidebarState.showWorkspace = project.rootPath != nil
        refreshGit()
    }
}
