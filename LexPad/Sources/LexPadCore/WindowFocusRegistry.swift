import Foundation

/// Routes menu / open-file actions to the frontmost editor window's document collection.
@MainActor
public final class WindowFocusRegistry: ObservableObject {
    public static let shared = WindowFocusRegistry()

    private var collections: [ObjectIdentifier: DocumentCollection] = [:]
    public private(set) weak var keyCollection: DocumentCollection?

    private init() {}

    public func register(_ collection: DocumentCollection, windowID: ObjectIdentifier) {
        collections[windowID] = collection
        keyCollection = collection
    }

    public func unregister(windowID: ObjectIdentifier) {
        collections.removeValue(forKey: windowID)
        if keyCollection.map({ ObjectIdentifier($0) }) == windowID {
            keyCollection = collections.values.first
        }
    }

    public func focus(_ collection: DocumentCollection) {
        keyCollection = collection
    }

    public var activeCollection: DocumentCollection? {
        keyCollection ?? collections.values.first
    }
}
