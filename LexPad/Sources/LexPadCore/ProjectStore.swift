import Foundation

public struct LexProject: Codable, Sendable {
    public var name: String
    public var rootPath: String?
    public var openFiles: [String]
    public var activeIndex: Int
    public var tabGroups: [TabGroup]
    public var tabGroupingMode: TabGroupingMode

    public init(
        name: String,
        rootPath: String? = nil,
        openFiles: [String] = [],
        activeIndex: Int = 0,
        tabGroups: [TabGroup] = [],
        tabGroupingMode: TabGroupingMode = .flat
    ) {
        self.name = name
        self.rootPath = rootPath
        self.openFiles = openFiles
        self.activeIndex = activeIndex
        self.tabGroups = tabGroups
        self.tabGroupingMode = tabGroupingMode
    }
}

@MainActor
public enum ProjectStore {
    public static func save(
        _ project: LexProject,
        to url: URL
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(project)
        try data.write(to: url, options: .atomic)
    }

    public static func load(from url: URL) throws -> LexProject {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(LexProject.self, from: data)
    }

    public static func buildProject(
        name: String,
        from collection: DocumentCollection,
        tabGroups: TabGroupStore,
        workspace: WorkspaceStore
    ) -> LexProject {
        let files = collection.documents.compactMap { $0.url?.path }
        let activeIndex = collection.documents.firstIndex { $0.id == collection.activeDocumentID } ?? 0
        return LexProject(
            name: name,
            rootPath: workspace.rootURL?.path,
            openFiles: files,
            activeIndex: activeIndex,
            tabGroups: tabGroups.groups,
            tabGroupingMode: tabGroups.mode
        )
    }

    public static func apply(
        _ project: LexProject,
        to collection: DocumentCollection,
        tabGroups: TabGroupStore,
        workspace: WorkspaceStore
    ) {
        collection.clearAll()
        for path in project.openFiles where FileManager.default.fileExists(atPath: path) {
            try? collection.open(url: URL(fileURLWithPath: path))
        }
        if collection.documents.isEmpty {
            collection.bootstrapIfEmpty()
        }
        if project.activeIndex < collection.documents.count {
            collection.activeDocumentID = collection.documents[project.activeIndex].id
        }
        tabGroups.groups = project.tabGroups
        tabGroups.mode = project.tabGroupingMode
        tabGroups.persist()
        if let root = project.rootPath {
            workspace.openFolder(URL(fileURLWithPath: root))
        }
    }
}
