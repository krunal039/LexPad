import LexPadCore
import SwiftUI

struct UDLEditorView: View {
    @ObservedObject var store: UserLanguageStore
    @Binding var isPresented: Bool
    @State private var editing: UserDefinedLanguage?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            PanelHeaderView(title: "User Defined Languages", onClose: { isPresented = false }) {
                Button("New") { editing = UserLanguageStore.sample() }
                    .font(.caption)
            }
            NavigationSplitView {
                List(selection: $editing) {
                    ForEach(store.languages) { language in
                        Text(language.name).tag(Optional(language))
                    }
                }
            } detail: {
                if let editing {
                    UDLFormView(
                        language: binding(for: editing),
                        onSave: { save($0) },
                        onDelete: { delete($0) }
                    )
                } else {
                    Text("Select a language")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(width: 720, height: 480)
        .alert("UDL Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func binding(for language: UserDefinedLanguage) -> Binding<UserDefinedLanguage> {
        Binding(
            get: { editing ?? language },
            set: { editing = $0 }
        )
    }

    private func save(_ language: UserDefinedLanguage) {
        guard !language.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name is required."
            return
        }
        guard !language.extensions.isEmpty else {
            errorMessage = "At least one file extension is required."
            return
        }
        do {
            try store.save(language)
            editing = store.language(id: language.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ language: UserDefinedLanguage) {
        do {
            try store.delete(id: language.id)
            editing = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct UDLFormView: View {
    @Binding var language: UserDefinedLanguage
    let onSave: (UserDefinedLanguage) -> Void
    let onDelete: (UserDefinedLanguage) -> Void

    @State private var extensionsText = ""
    @State private var keywordsText = ""
    @State private var keywords2Text = ""

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $language.name)
                TextField("Extensions (comma-separated)", text: $extensionsText)
                    .onAppear { extensionsText = language.extensions.joined(separator: ", ") }
                    .onChange(of: extensionsText) { value in
                        language.extensions = value
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                            .filter { !$0.isEmpty }
                    }
            }
            Section("Highlighting") {
                TextField("Base lexer (e.g. cpp, python)", text: $language.baseLexer)
                TextField("Line comment prefix", text: $language.commentLine)
            }
            Section("Keywords") {
                TextEditor(text: $keywordsText)
                    .frame(minHeight: 80)
                    .onAppear { keywordsText = language.keywords.joined(separator: "\n") }
                    .onChange(of: keywordsText) { value in
                        language.keywords = Self.parseLines(value)
                    }
                Text("Keywords 2").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $keywords2Text)
                    .frame(minHeight: 60)
                    .onAppear { keywords2Text = language.keywords2.joined(separator: "\n") }
                    .onChange(of: keywords2Text) { value in
                        language.keywords2 = Self.parseLines(value)
                    }
            }
            HStack {
                Button("Delete", role: .destructive) { onDelete(language) }
                Spacer()
                Button("Save") { onSave(language) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private static func parseLines(_ text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

struct UserLanguagesPreferencesView: View {
    @ObservedObject var store: UserLanguageStore
    @State private var showEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User-defined languages (UDL) map file extensions to custom keywords and comment styles.")
                .font(.caption)
                .foregroundStyle(.secondary)
            List(store.languages) { language in
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.name)
                    Text(".\(language.fileExtensionList) · \(language.baseLexer)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Button("Open UDL Editor…") { showEditor = true }
        }
        .sheet(isPresented: $showEditor) {
            UDLEditorView(store: store, isPresented: $showEditor)
        }
    }
}
