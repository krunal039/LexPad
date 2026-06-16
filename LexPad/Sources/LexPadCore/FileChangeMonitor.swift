import Foundation
import Dispatch
import Darwin

@MainActor
public final class FileChangeMonitor: ObservableObject {
    @Published public private(set) var changedURL: URL?

    private var monitors: [UUID: DispatchSourceFileSystemObject] = [:]
    private var descriptors: [UUID: Int32] = [:]
    private var urls: [UUID: URL] = [:]

    public init() {}

    public func watch(document: TextDocument) {
        unwatch(documentID: document.id)
        guard let url = document.url else { return }
        let path = url.path
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .attrib],
            queue: .main
        )
        let docID = document.id
        source.setEventHandler { [weak self] in
            self?.changedURL = url
        }
        source.setCancelHandler { close(fd) }
        source.resume()

        monitors[docID] = source
        descriptors[docID] = fd
        urls[docID] = url
    }

    public func unwatch(documentID: UUID) {
        monitors[documentID]?.cancel()
        monitors.removeValue(forKey: documentID)
        descriptors.removeValue(forKey: documentID)
        urls.removeValue(forKey: documentID)
    }

    public func clearChange() {
        changedURL = nil
    }

    public func sync(documents: [TextDocument]) {
        let ids = Set(documents.map(\.id))
        for id in monitors.keys where !ids.contains(id) {
            unwatch(documentID: id)
        }
        for doc in documents {
            watch(document: doc)
        }
    }
}
