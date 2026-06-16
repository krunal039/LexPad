import LexPadCore
import XCTest

@MainActor
final class TabGroupStoreTests: XCTestCase {
    func testGroupByFolder() {
        let store = TabGroupStore()
        store.mode = .byFolder
        let docs = [
            TextDocument(url: URL(fileURLWithPath: "/tmp/project/src/main.swift")),
            TextDocument(url: URL(fileURLWithPath: "/tmp/project/tests/main_test.swift")),
            TextDocument(url: URL(fileURLWithPath: "/tmp/other/readme.md")),
        ]
        let sections = store.sections(for: docs)
        XCTAssertEqual(sections.count, 3)
        XCTAssertTrue(sections.contains { $0.title == "src" })
        XCTAssertTrue(sections.contains { $0.title == "tests" })
    }

    func testUserTabGroup() {
        let store = TabGroupStore()
        let a = UUID()
        let b = UUID()
        let group = store.createGroup(name: "Sprint", documentIDs: [a])
        store.addDocument(b, to: group.id)
        store.mode = .byGroup
        let docs = [
            TextDocument(id: a, text: "a"),
            TextDocument(id: b, text: "b"),
            TextDocument(id: UUID(), text: "c"),
        ]
        let sections = store.sections(for: docs)
        XCTAssertEqual(sections.first?.title, "Sprint")
        XCTAssertEqual(sections.first?.documentIDs.count, 2)
        XCTAssertTrue(sections.contains { $0.title == "Ungrouped" })
    }

    func testSanitizeRemovesDuplicateEmptyGroups() {
        let store = TabGroupStore()
        let docID = UUID()
        store.groups = [
            TabGroup(name: "Sprint", documentIDs: []),
            TabGroup(name: "Sprint", documentIDs: []),
            TabGroup(name: "Scripts", documentIDs: [docID]),
        ]
        store.sanitizeGroups()
        XCTAssertEqual(store.groups.count, 1)
        XCTAssertEqual(store.groups.first?.name, "Scripts")
    }
}

final class MarkStyleTests: XCTestCase {
    func testBookmarkWithStyle() {
        var bookmarks: [Bookmark] = []
        XCTAssertTrue(BookmarkStore.toggle(bookmarks: &bookmarks, line: 3, style: .style1))
        XCTAssertEqual(bookmarks.first?.style, .style1)
        BookmarkStore.setMark(on: 5, style: .style5, in: &bookmarks)
        XCTAssertEqual(bookmarks.count, 2)
        BookmarkStore.clearStyle(.style1, in: &bookmarks)
        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.style, .style5)
    }
}
