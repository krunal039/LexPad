import LexPadCore
import SwiftUI

struct EditorCompletionNotificationsModifier: ViewModifier {
    var selectNextOccurrence: () -> Void
    var triggerCompletion: () -> Void
    var openUDLEditor: () -> Void
    var insertSnippetFromNotification: (Notification) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .lexPadSelectNextOccurrence)) { _ in
                selectNextOccurrence()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadTriggerCompletion)) { _ in
                triggerCompletion()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadOpenUDLEditor)) { _ in
                openUDLEditor()
            }
            .onReceive(NotificationCenter.default.publisher(for: .lexPadInsertSnippet)) { note in
                insertSnippetFromNotification(note)
            }
    }
}

struct EditorLocalSheetsModifier: ViewModifier {
    @Binding var showEncodingPicker: Bool
    @Binding var showColumnEditor: Bool
    @Binding var showStyleConfigurator: Bool
    @Binding var showPluginManager: Bool
    @Binding var showUDLEditor: Bool
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var settings: EditorSettings
    @ObservedObject var pluginRegistry: PluginRegistry
    @ObservedObject var userLanguageStore: UserLanguageStore
    var selectedRange: NSRange

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showEncodingPicker) {
                EncodingPickerSheet(
                    isPresented: $showEncodingPicker,
                    currentEncoding: collection.activeDocument?.encoding ?? .utf8
                ) { encoding in
                    try? collection.reloadActive(with: encoding)
                }
                .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showColumnEditor) {
                ColumnEditorSheet(isPresented: $showColumnEditor) { start, step, pad in
                    collection.applyColumnNumbers(start: start, step: step, padWidth: pad, selectedRange: selectedRange)
                }
                .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showStyleConfigurator) {
                StyleConfiguratorView(settings: settings, onClose: { showStyleConfigurator = false })
                    .frame(width: 420, height: 360)
                    .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showPluginManager) {
                PluginManagerPanel(manager: pluginRegistry, onClose: { showPluginManager = false })
                    .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showUDLEditor) {
                UDLEditorView(store: userLanguageStore, isPresented: $showUDLEditor)
                    .lexPadTheme(settings: settings)
            }
    }
}
