import AppKit
import LexPadCore
import SwiftUI

struct TierFeatureNotificationsModifier: ViewModifier {
    @ObservedObject var collection: DocumentCollection
    @Binding var selectedRange: NSRange

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadDuplicateTab)) { _ in
                guard let id = collection.activeDocumentID else { return }
                try? collection.openDuplicateTab(for: id)
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleReadOnly)) { _ in
                collection.toggleReadOnly()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadTogglePinTab)) { _ in
                guard let id = collection.activeDocumentID else { return }
                collection.togglePinned(documentID: id)
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadFormatJSON)) { _ in
                runPlugin(id: "com.lexpad.json-formatter", action: "format")
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadFormatXML)) { _ in
                runPlugin(id: "com.lexpad.xml-formatter", action: "format")
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadRunPlugin)) { note in
                guard let pluginID = note.userInfo?["pluginID"] as? String,
                      let action = note.userInfo?["action"] as? String else { return }
                runPlugin(id: pluginID, action: action)
            }
    }

    private func runPlugin(id: String, action: String) {
        guard let doc = collection.activeDocument else { return }
        let sel = selectedRange.location == NSNotFound ? NSRange(location: 0, length: 0) : selectedRange
        guard let output = PluginManager.run(pluginID: id, action: action, text: doc.text, selection: sel) else { return }
        collection.replaceActiveText(output)
    }
}

struct WindowOpenBridge: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear.frame(width: 0, height: 0)
            .onReceive(NotificationCenter.default.publisher(for: .lexPadNewWindow)) { _ in
                openWindow(id: "editor")
            }
    }
}

struct WindowFocusTracker: NSViewRepresentable {
    let collection: DocumentCollection

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didBecomeKeyNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    Task { @MainActor in
                        AppController.shared.collection = collection
                        WindowFocusRegistry.shared.focus(collection)
                    }
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
