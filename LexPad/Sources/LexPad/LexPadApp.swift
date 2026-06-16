import AppKit
import LexPadCore
import SwiftUI

@main
struct LexPadApp: App {
    @StateObject private var collection = DocumentCollection()

    var body: some Scene {
        WindowGroup {
            MainEditorContainer(collection: collection)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") { collection.newDocument() }
                    .keyboardShortcut("t", modifiers: [.command])
            }
            CommandGroup(after: .saveItem) {
                Button("Open…") { openDocument() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button("Save") { saveDocument() }
                    .keyboardShortcut("s", modifiers: [.command])
            }
            CommandGroup(after: .textEditing) {
                Button("Find…") {
                    NotificationCenter.default.post(name: .lexPadToggleFind, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
    }

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK else { return }
            for url in panel.urls {
                try? collection.open(url: url)
            }
        }
    }

    private func saveDocument() {
        guard let doc = collection.activeDocument else { return }
        if let url = doc.url {
            try? collection.saveActive(to: url)
            return
        }
        let panel = NSSavePanel()
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? collection.saveActive(to: url)
        }
    }
}

extension Notification.Name {
    static let lexPadToggleFind = Notification.Name("LexPadToggleFind")
}

struct MainEditorContainer: View {
    @ObservedObject var collection: DocumentCollection
    @State private var showFindBar = false
    @State private var findPattern = ""
    @State private var findRegex = false
    @State private var findMatchCase = false
    @State private var findMatches: [FindMatch] = []
    @State private var currentMatchIndex = 0
    @State private var selectedRange = NSRange(location: NSNotFound, length: 0)

    var body: some View {
        VStack(spacing: 0) {
            TabStripView(collection: collection) { id in
                collection.close(documentID: id)
            }

            if showFindBar {
                FindBarView(
                    pattern: $findPattern,
                    isRegex: $findRegex,
                    matchCase: $findMatchCase,
                    matchCount: findMatches.count,
                    onFindNext: findNext,
                    onFindPrevious: findPrevious,
                    onClose: { showFindBar = false }
                )
            }

            if let document = collection.activeDocument {
                TextEditorView(
                    text: Binding(
                        get: { collection.activeDocument?.text ?? "" },
                        set: { collection.updateActiveText($0) }
                    ),
                    selectedRange: selectedRange,
                    highlightRanges: findMatches.compactMap { NSRange($0.range, in: document.text) },
                    onTextChange: { collection.updateActiveText($0) },
                    onSelectionChange: { line, column in
                        collection.updateActiveCaret(line: line, column: column)
                    }
                )
            }

            StatusBarView(document: collection.activeDocument, matchCount: findMatches.count)
        }
        .onReceive(NotificationCenter.default.publisher(for: .lexPadToggleFind)) { _ in
            showFindBar.toggle()
            if showFindBar { refreshFind() }
        }
        .onChange(of: findPattern) { _ in refreshFind() }
        .onChange(of: findRegex) { _ in refreshFind() }
        .onChange(of: findMatchCase) { _ in refreshFind() }
        .onChange(of: collection.activeDocumentID) { _ in refreshFind() }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private func refreshFind() {
        guard showFindBar, let text = collection.activeDocument?.text else {
            findMatches = []
            return
        }
        let options = FindOptions(pattern: findPattern, isRegex: findRegex, matchCase: findMatchCase)
        findMatches = (try? FindEngine.findAll(in: text, options: options)) ?? []
        currentMatchIndex = 0
        updateSelectionForCurrentMatch()
    }

    private func findNext() {
        guard !findMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % findMatches.count
        updateSelectionForCurrentMatch()
    }

    private func findPrevious() {
        guard !findMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + findMatches.count) % findMatches.count
        updateSelectionForCurrentMatch()
    }

    private func updateSelectionForCurrentMatch() {
        guard findMatches.indices.contains(currentMatchIndex),
              let text = collection.activeDocument?.text else {
            selectedRange = NSRange(location: NSNotFound, length: 0)
            return
        }
        selectedRange = NSRange(findMatches[currentMatchIndex].range, in: text)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers where provider.hasItemConformingToTypeIdentifier("public.file-url") {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    try? collection.open(url: url)
                }
            }
        }
        return true
    }
}
