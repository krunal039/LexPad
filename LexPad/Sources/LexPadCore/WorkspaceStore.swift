import Foundation

public struct WorkspaceNode: Identifiable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public var children: [WorkspaceNode]?

    public init(url: URL, name: String, isDirectory: Bool, children: [WorkspaceNode]? = nil) {
        self.id = UUID()
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.children = children
    }
}

@MainActor
public final class WorkspaceStore: ObservableObject {
    @Published public private(set) var rootURL: URL?
    @Published public private(set) var tree: [WorkspaceNode] = []
    @Published public var filter = ""

    public init() {}

    public func openFolder(_ url: URL) {
        rootURL = url
        tree = scan(directory: url, depth: 0)
    }

    public func closeFolder() {
        rootURL = nil
        tree = []
    }

    public var filteredTree: [WorkspaceNode] {
        guard !filter.isEmpty else { return tree }
        return filterNodes(tree, query: filter.lowercased())
    }

    private func filterNodes(_ nodes: [WorkspaceNode], query: String) -> [WorkspaceNode] {
        var result: [WorkspaceNode] = []
        for node in nodes {
            if node.isDirectory {
                let kids = filterNodes(node.children ?? [], query: query)
                if !kids.isEmpty || node.name.lowercased().contains(query) {
                    result.append(WorkspaceNode(url: node.url, name: node.name, isDirectory: true, children: kids))
                }
            } else if node.name.lowercased().contains(query) {
                result.append(node)
            }
        }
        return result
    }

    private func scan(directory: URL, depth: Int) -> [WorkspaceNode] {
        guard depth < 8 else { return [] }
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return items.sorted { a, b in
            let ad = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let bd = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if ad != bd { return ad && !bd }
            return a.lastPathComponent.localizedCaseInsensitiveCompare(b.lastPathComponent) == .orderedAscending
        }.compactMap { url -> WorkspaceNode? in
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                let kids = scan(directory: url, depth: depth + 1)
                return WorkspaceNode(url: url, name: url.lastPathComponent, isDirectory: true, children: kids)
            }
            if shouldIncludeFile(url) {
                return WorkspaceNode(url: url, name: url.lastPathComponent, isDirectory: false)
            }
            return nil
        }
    }

    private func shouldIncludeFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ext.isEmpty { return true }
        let skip = ["o", "a", "dylib", "framework", "app", "png", "jpg", "jpeg", "gif", "ico", "pdf", "zip", "exe"]
        return !skip.contains(ext)
    }
}
