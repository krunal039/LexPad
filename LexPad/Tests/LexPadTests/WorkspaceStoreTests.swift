import LexPadCore
import XCTest

@MainActor
final class WorkspaceStoreTests: XCTestCase {
    func testOpenFolderBuildsTree() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let sub = root.appendingPathComponent("src")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try "hello".write(to: root.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)
        try "fn main() {}".write(to: sub.appendingPathComponent("main.rs"), atomically: true, encoding: .utf8)

        let store = WorkspaceStore()
        store.openFolder(root)

        XCTAssertEqual(store.rootURL, root)
        XCTAssertFalse(store.tree.isEmpty)
        XCTAssertTrue(store.tree.contains { $0.name == "readme.txt" && !$0.isDirectory })
        XCTAssertTrue(store.tree.contains { $0.name == "src" && $0.isDirectory })
    }

    func testFilterMatchesFileNames() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try "a".write(to: root.appendingPathComponent("alpha.txt"), atomically: true, encoding: .utf8)
        try "b".write(to: root.appendingPathComponent("beta.txt"), atomically: true, encoding: .utf8)

        let store = WorkspaceStore()
        store.openFolder(root)
        store.filter = "alpha"

        XCTAssertEqual(store.filteredTree.count, 1)
        XCTAssertEqual(store.filteredTree[0].name, "alpha.txt")
    }
}
