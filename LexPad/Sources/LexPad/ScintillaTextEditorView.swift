import AppKit
import LexPadCore
import SwiftUI

#if LEXPAD_HAS_SCINTILLA
import ScintillaBridge
#endif

/// Editor surface: Scintilla+Lexilla when built, otherwise AppKit NSTextView.
struct EditorSurfaceView: View {
    @Binding var text: String
    var language: EditorLanguage
    var userLanguage: UserDefinedLanguage?
    var snippets: [Snippet]
    var enableSnippetTriggers: Bool
    var virtualSpaceEnabled: Bool
    var enableAutoCompletion: Bool
    var autoCompletionMinLength: Int
    var buildCompletionItems: () -> [String]
    var selectedRange: NSRange
    var highlightRanges: [NSRange]
    var bookmarks: [Bookmark]
    var changeHistory: [Int: LineChangeState]
    var showChangeHistory: Bool
    var builtInTheme: String
    var disableHighlighting: Bool
    var wordWrap: Bool
    var showLineNumbers: Bool
    var fontSize: Double
    var tabSize: Int
    var useSpacesForTab: Bool
    var codeFolding: Bool
    var isOverwriteMode: Bool
    var isReadOnly: Bool = false
    var enableBraceMatching: Bool = true
    var enableSmartHighlight: Bool = true
    var enableSpellCheck: Bool = false
    var enableCalltips: Bool = true
    var prefersDarkMode: Bool?
    var scrollToLine: Int?
    var onTextChange: (String) -> Void
    var onSelectionChange: (Int, Int) -> Void
    var onScroll: ((Int) -> Void)?

    var body: some View {
        #if LEXPAD_HAS_SCINTILLA
        if ScintillaEditorSupport.isAvailable {
            ScintillaTextEditorView(
                text: $text,
                language: language,
                userLanguage: userLanguage,
                snippets: snippets,
                enableSnippetTriggers: enableSnippetTriggers,
                virtualSpaceEnabled: virtualSpaceEnabled,
                enableAutoCompletion: enableAutoCompletion,
                autoCompletionMinLength: autoCompletionMinLength,
                buildCompletionItems: buildCompletionItems,
                selectedRange: selectedRange,
                highlightRanges: highlightRanges,
                bookmarks: bookmarks,
                changeHistory: changeHistory,
                showChangeHistory: showChangeHistory,
                builtInTheme: builtInTheme,
                disableHighlighting: disableHighlighting,
                wordWrap: wordWrap,
                showLineNumbers: showLineNumbers,
                fontSize: fontSize,
                tabSize: tabSize,
                useSpacesForTab: useSpacesForTab,
                codeFolding: codeFolding,
                isOverwriteMode: isOverwriteMode,
                isReadOnly: isReadOnly,
                enableBraceMatching: enableBraceMatching,
                enableSmartHighlight: enableSmartHighlight,
                enableSpellCheck: enableSpellCheck,
                enableCalltips: enableCalltips,
                prefersDarkMode: prefersDarkMode,
                scrollToLine: scrollToLine,
                onTextChange: onTextChange,
                onSelectionChange: onSelectionChange,
                onScroll: onScroll
            )
        } else {
            fallbackEditor
        }
        #else
        fallbackEditor
        #endif
    }

    private var fallbackEditor: some View {
        TextEditorView(
            text: $text,
            language: language,
            selectedRange: selectedRange,
            highlightRanges: highlightRanges,
            wordWrap: wordWrap,
            showLineNumbers: showLineNumbers,
            fontSize: fontSize,
            onTextChange: onTextChange,
            onSelectionChange: onSelectionChange
        )
    }
}

#if LEXPAD_HAS_SCINTILLA
enum ScintillaEditorSupport {
    static var isAvailable: Bool {
        LPScintillaEditorView.isEngineAvailable()
    }

    static func foldAll() {
        NotificationCenter.default.post(name: .lexPadEditorAction, object: nil, userInfo: ["action": "foldAll"])
    }

    static func unfoldAll() {
        NotificationCenter.default.post(name: .lexPadEditorAction, object: nil, userInfo: ["action": "unfoldAll"])
    }
}

struct ScintillaTextEditorView: NSViewRepresentable {
    @Binding var text: String
    var language: EditorLanguage
    var userLanguage: UserDefinedLanguage?
    var snippets: [Snippet]
    var enableSnippetTriggers: Bool
    var virtualSpaceEnabled: Bool
    var enableAutoCompletion: Bool
    var autoCompletionMinLength: Int
    var buildCompletionItems: () -> [String]
    var selectedRange: NSRange
    var highlightRanges: [NSRange]
    var bookmarks: [Bookmark]
    var changeHistory: [Int: LineChangeState]
    var showChangeHistory: Bool
    var builtInTheme: String
    var disableHighlighting: Bool
    var wordWrap: Bool
    var showLineNumbers: Bool
    var fontSize: Double
    var tabSize: Int
    var useSpacesForTab: Bool
    var codeFolding: Bool
    var isOverwriteMode: Bool
    var isReadOnly: Bool
    var enableBraceMatching: Bool
    var enableSmartHighlight: Bool
    var enableSpellCheck: Bool
    var enableCalltips: Bool
    var prefersDarkMode: Bool?
    var scrollToLine: Int?
    var onTextChange: (String) -> Void
    var onSelectionChange: (Int, Int) -> Void
    var onScroll: ((Int) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> LPScintillaEditorView {
        let view = LPScintillaEditorView(frame: .zero)
        view.editorDelegate = context.coordinator
        view.string = text
        applyConfiguration(to: view, context: context)
        context.coordinator.editorView = view
        context.coordinator.observeEditorActions()
        return view
    }

    func updateNSView(_ view: LPScintillaEditorView, context: Context) {
        context.coordinator.parent = self
        applyConfiguration(to: view, context: context)

        if context.coordinator.lastLanguage != language
            || context.coordinator.lastUserLanguageID != userLanguage?.id
            || context.coordinator.lastDisableHighlighting != disableHighlighting {
            context.coordinator.lastLanguage = language
            context.coordinator.lastUserLanguageID = userLanguage?.id
            context.coordinator.lastDisableHighlighting = disableHighlighting
            applyLexer(to: view)
        }

        view.setAutoCompletionEnabled(enableAutoCompletion, minimumLength: autoCompletionMinLength)

        if view.string != text, !context.coordinator.isUpdatingFromEditor {
            context.coordinator.isUpdatingFromSwiftUI = true
            view.string = text
            context.coordinator.isUpdatingFromSwiftUI = false
        }

        view.applySearchHighlights(highlightRanges.map { NSValue(range: $0) })

        if enableSmartHighlight, selectedRange.length == 0,
           let wordRange = SmartHighlightEngine.wordRange(at: selectedRange.location, in: text) {
            let word = (text as NSString).substring(with: wordRange)
            let smart = SmartHighlightEngine.allOccurrences(of: word, in: text)
            view.applySmartHighlights(smart.map { NSValue(range: $0) })
        } else {
            view.applySmartHighlights([])
        }

        if enableSpellCheck, !text.isEmpty, text.count < 500_000 {
            let misspelled = SpellCheckEngine.misspelledRanges(in: text)
            view.applySpellCheckHighlights(misspelled.map { NSValue(range: $0) })
        } else {
            view.applySpellCheckHighlights([])
        }

        if context.coordinator.lastBraceMatching != enableBraceMatching {
            context.coordinator.lastBraceMatching = enableBraceMatching
            view.setBraceMatchingEnabled(enableBraceMatching)
        }
        if context.coordinator.lastReadOnly != isReadOnly {
            context.coordinator.lastReadOnly = isReadOnly
            view.setReadOnlyMode(isReadOnly)
        }
        let markPayload: [[AnyHashable: Any]] = bookmarks.map { bookmark in
            ["line": bookmark.line, "style": bookmark.style.rawValue]
        }
        view.applyLineMarks(markPayload)
        if showChangeHistory {
            view.applyChangeHistory(ChangeHistoryEngine.payload(for: changeHistory))
        }

        if let scrollToLine,
           scrollToLine != context.coordinator.lastAppliedScrollLine,
           !context.coordinator.isApplyingExternalScroll {
            context.coordinator.isApplyingExternalScroll = true
            view.scroll(toFirstVisibleLine: scrollToLine)
            context.coordinator.lastAppliedScrollLine = scrollToLine
            context.coordinator.isApplyingExternalScroll = false
        }

        if selectedRange.location != NSNotFound,
           NSMaxRange(selectedRange) <= (view.string as NSString).length,
           view.selectedRange() != selectedRange {
            view.setSelectedRange(selectedRange)
        }

        view.setOverwriteMode(isOverwriteMode)
    }

    private func applyConfiguration(to view: LPScintillaEditorView, context: Context) {
        let dark: Bool
        if let prefersDarkMode {
            dark = prefersDarkMode
        } else {
            dark = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        view.configureAppearance(
            withFontSize: fontSize,
            wordWrap: wordWrap,
            showLineNumbers: showLineNumbers,
            darkMode: dark,
            tabSize: tabSize,
            useSpacesForTab: useSpacesForTab,
            codeFolding: codeFolding,
            showChangeHistory: showChangeHistory,
            themeName: builtInTheme,
            virtualSpaceEnabled: virtualSpaceEnabled,
            themeColors: Self.themeColorsPayload(for: builtInTheme)
        )
        if context.coordinator.lastLanguage != language
            || context.coordinator.lastUserLanguageID != userLanguage?.id
            || context.coordinator.lastDisableHighlighting != disableHighlighting {
            context.coordinator.lastLanguage = language
            context.coordinator.lastUserLanguageID = userLanguage?.id
            context.coordinator.lastDisableHighlighting = disableHighlighting
            applyLexer(to: view)
        }
        view.setAutoCompletionEnabled(enableAutoCompletion, minimumLength: autoCompletionMinLength)
    }

    private func applyLexer(to view: LPScintillaEditorView) {
        let context = LanguageContext(editorLanguage: language, userLanguage: userLanguage)
        let keywords = LanguageContext.keywords(for: language, userLanguage: userLanguage)
        if disableHighlighting {
            view.setLexerLanguage(nil, keywords: nil)
        } else if let lexilla = context.lexillaName {
            view.setLexerLanguage(lexilla, keywords: keywords)
        } else {
            view.setLexerLanguage(nil, keywords: nil)
        }
    }

    private static func themeColorsPayload(for themeName: String) -> [AnyHashable: Any]? {
        guard themeName != BuiltInEditorTheme.classic.rawValue,
              let theme = BuiltInEditorTheme(rawValue: themeName) else { return nil }
        let colors = EditorThemePalette.colors(for: theme)
        return [
            "bg": [colors.background.r, colors.background.g, colors.background.b],
            "fg": [colors.foreground.r, colors.foreground.g, colors.foreground.b],
            "kw": [colors.keyword.r, colors.keyword.g, colors.keyword.b],
            "cm": [colors.comment.r, colors.comment.g, colors.comment.b],
            "st": [colors.string.r, colors.string.g, colors.string.b],
            "nu": [colors.number.r, colors.number.g, colors.number.b],
        ]
    }

    final class Coordinator: NSObject, LPScintillaEditorDelegate {
        var parent: ScintillaTextEditorView
        weak var editorView: LPScintillaEditorView?
        var isUpdatingFromSwiftUI = false
        var isUpdatingFromEditor = false
        var lastLanguage: EditorLanguage
        var lastUserLanguageID: String?
        var lastDisableHighlighting = false
        var lastBraceMatching = true
        var lastReadOnly = false
        private var actionObserver: NSObjectProtocol?
        private var pendingSelection: (line: Int, column: Int)?
        private var selectionDispatchScheduled = false
        private var pendingScrollLine: Int?
        private var scrollDispatchScheduled = false
        var isApplyingExternalScroll = false
        var lastAppliedScrollLine: Int?

        init(parent: ScintillaTextEditorView) {
            self.parent = parent
            self.lastLanguage = parent.language
        }

        func observeEditorActions() {
            actionObserver = NotificationCenter.default.addObserver(
                forName: .lexPadEditorAction,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let action = note.userInfo?["action"] as? String,
                      let view = self?.editorView else { return }
                switch action {
                case "foldAll": view.foldAll()
                case "unfoldAll": view.unfoldAll()
                case "selectNext":
                    let matchCase = note.userInfo?["matchCase"] as? Bool ?? false
                    let wholeWord = note.userInfo?["wholeWord"] as? Bool ?? false
                    view.selectNextOccurrenceMatchCase(matchCase, wholeWord: wholeWord)
                case "showCompletion":
                    if let items = note.userInfo?["items"] as? [String] {
                        view.showAutoComplete(withItems: items)
                    } else {
                        self?.showCompletion(on: view)
                    }
                default: break
                }
            }
        }

        deinit {
            if let actionObserver { NotificationCenter.default.removeObserver(actionObserver) }
        }

        func scintillaEditorTextDidChange(_ sender: Any) {
            guard !isUpdatingFromSwiftUI, let view = sender as? LPScintillaEditorView else { return }
            let rawText = view.string
            var finalText = rawText

            if parent.enableSnippetTriggers, !parent.snippets.isEmpty {
                let sel = view.selectedRange()
                // Only expand when user is typing (empty main selection).
                if sel.length == 0 {
                    let caret = sel.location
                    if let expansion = SnippetTriggerEngine.expansion(
                        in: rawText,
                        caretLocation: caret,
                        snippets: parent.snippets
                    ) {
                        let result = SnippetEngine.insert(expansion.body, into: rawText, replacing: expansion.triggerRange)
                        finalText = result.text
                        // Apply immediately so the editor shows the expanded snippet.
                        view.string = finalText
                        view.setSelectedRange(result.selection)
                    }
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.isUpdatingFromSwiftUI else { return }
                self.isUpdatingFromEditor = true
                self.parent.onTextChange(finalText)
                self.isUpdatingFromEditor = false
            }
        }

        func scintillaEditorSelectionDidChange(_ sender: Any, line: Int, column: Int) {
            guard !isUpdatingFromSwiftUI else { return }
            if parent.enableCalltips, let view = sender as? LPScintillaEditorView {
                let caret = view.selectedRange().location
                if let hint = CalltipEngine.hint(at: caret, in: view.string, language: parent.language) {
                    view.showCalltip(hint.signature, atPosition: caret)
                }
            }
            pendingSelection = (line, column)
            guard !selectionDispatchScheduled else { return }
            selectionDispatchScheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.selectionDispatchScheduled = false
                guard let pending = self.pendingSelection else { return }
                self.pendingSelection = nil
                self.parent.onSelectionChange(pending.line, pending.column)
            }
        }

        func scintillaEditorAutoCompleteRequested(_ sender: Any) {
            guard let view = sender as? LPScintillaEditorView else { return }
            showCompletion(on: view)
        }

        private func showCompletion(on view: LPScintillaEditorView) {
            let items = parent.buildCompletionItems()
            guard !items.isEmpty else { return }
            view.showAutoComplete(withItems: items)
        }

        func scintillaEditorDidScroll(_ sender: Any, firstVisibleLine line: Int) {
            guard !isApplyingExternalScroll, parent.onScroll != nil else { return }
            pendingScrollLine = line
            guard !scrollDispatchScheduled else { return }
            scrollDispatchScheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.scrollDispatchScheduled = false
                guard let pending = self.pendingScrollLine else { return }
                self.pendingScrollLine = nil
                self.parent.onScroll?(pending)
            }
        }
    }
}
#endif
