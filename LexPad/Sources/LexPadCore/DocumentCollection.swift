import Foundation

@MainActor
public final class DocumentCollection: ObservableObject {
    @Published public private(set) var documents: [TextDocument] = []
    @Published public var activeDocumentID: UUID?
    @Published public var recentFiles: [URL] = []

    public init() {
        newDocument()
    }

    public var activeDocument: TextDocument? {
        get {
            guard let id = activeDocumentID else { return nil }
            return documents.first { $0.id == id }
        }
        set {
            guard let newValue, let index = documents.firstIndex(where: { $0.id == newValue.id }) else { return }
            documents[index] = newValue
        }
    }

    public func newDocument() {
        let doc = TextDocument()
        documents.append(doc)
        activeDocumentID = doc.id
    }

    public func open(url: URL) throws {
        let doc = try DocumentStore.load(from: url)
        documents.append(doc)
        activeDocumentID = doc.id
        rememberRecent(url)
    }

    public func close(documentID: UUID) {
        documents.removeAll { $0.id == documentID }
        if activeDocumentID == documentID {
            activeDocumentID = documents.last?.id
        }
        if documents.isEmpty {
            newDocument()
        }
    }

    public func updateActiveText(_ text: String) {
        guard var doc = activeDocument else { return }
        doc.text = text
        doc.isDirty = true
        activeDocument = doc
    }

    public func updateActiveCaret(line: Int, column: Int) {
        guard var doc = activeDocument else { return }
        doc.caret = CaretPosition(line: line, column: column)
        activeDocument = doc
    }

    public func saveActive(to url: URL? = nil) throws {
        guard let doc = activeDocument else { return }
        let saved = try DocumentStore.save(doc, to: url)
        if let index = documents.firstIndex(where: { $0.id == saved.id }) {
            documents[index] = saved
        }
        if let savedURL = saved.url {
            rememberRecent(savedURL)
        }
    }

    private func rememberRecent(_ url: URL) {
        recentFiles.removeAll { $0 == url }
        recentFiles.insert(url, at: 0)
        recentFiles = Array(recentFiles.prefix(20))
    }
}
