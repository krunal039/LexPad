import Foundation
import LexPadCore
import XCTest

@MainActor
final class SessionStoreTests: XCTestCase {
    func testSaveAndRestoreTabsWithUntitled() {
        let collection = DocumentCollection()
        let tabGroups = TabGroupStore()
        let split = SplitViewState()

        collection.newDocument()
        guard let untitledID = collection.activeDocumentID else {
            XCTFail("missing untitled")
            return
        }
        collection.updateDocument(untitledID, text: "draft content")

        let file = FileManager.default.temporaryDirectory.appendingPathComponent("session-test-\(UUID().uuidString).txt")
        try? "file body".write(to: file, atomically: true, encoding: .utf8)
        try? collection.open(url: file)
        guard let fileDocID = collection.activeDocumentID else {
            XCTFail("missing file doc")
            return
        }

        SessionStore.save(from: collection, tabGroups: tabGroups, splitState: split)

        let restored = DocumentCollection()
        let restoredGroups = TabGroupStore()
        let restoredSplit = SplitViewState()
        let ok = SessionStore.restore(into: restored, tabGroups: restoredGroups, splitState: restoredSplit)
        XCTAssertTrue(ok)
        XCTAssertEqual(restored.documents.count, 2)
        XCTAssertTrue(restored.documents.contains { $0.id == untitledID && $0.text == "draft content" })
        XCTAssertTrue(restored.documents.contains { $0.id == fileDocID })
    }

    func testRecentFilesRememberTimestamp() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("recent-\(UUID().uuidString).txt")
        try? "x".write(to: url, atomically: true, encoding: .utf8)
        let entries = RecentFilesStore.rememberEntry(url)
        XCTAssertEqual(entries.first?.path, url.path)
        XCTAssertEqual(entries.first?.openCount, 1)
        let again = RecentFilesStore.rememberEntry(url)
        XCTAssertEqual(again.first?.openCount, 2)
    }
}
