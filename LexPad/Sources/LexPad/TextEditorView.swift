import AppKit
import LexPadCore
import SwiftUI

struct TextEditorView: NSViewRepresentable {
    @Binding var text: String
    var language: EditorLanguage
    var selectedRange: NSRange
    var highlightRanges: [NSRange]
    var wordWrap: Bool
    var showLineNumbers: Bool
    var fontSize: Double
    var onTextChange: (String) -> Void
    var onSelectionChange: (Int, Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.autoresizingMask = [.width, .height]

        let textView = CodeTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = !wordWrap
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.textContainer?.lineFragmentPadding = 4
        textView.delegate = context.coordinator
        textView.onSelectionChange = { line, col in
            context.coordinator.parent.onSelectionChange(line, col)
        }

        scrollView.documentView = textView
        configureLayout(scrollView: scrollView, textView: textView)
        applyFont(to: textView)

        if showLineNumbers {
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
            scrollView.verticalRulerView = LineNumberRulerView(textView: textView, scrollView: scrollView)
        }

        textView.string = text
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.applySyntaxHighlighting()

        DispatchQueue.main.async {
            configureLayout(scrollView: scrollView, textView: textView)
            scrollView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? CodeTextView else { return }

        configureLayout(scrollView: scrollView, textView: textView)
        applyFont(to: textView)

        let showRuler = showLineNumbers
        if showRuler != scrollView.hasVerticalRuler {
            scrollView.hasVerticalRuler = showRuler
            scrollView.rulersVisible = showRuler
            scrollView.verticalRulerView = showRuler ? LineNumberRulerView(textView: textView, scrollView: scrollView) : nil
        }

        if textView.string != text, !context.coordinator.isUpdatingFromTextView, !context.coordinator.isUpdatingFromSwiftUI {
            // If the text view is ahead of SwiftUI state, the user is typing — don't clobber.
            if textView.string.count > text.count {
                context.coordinator.isUpdatingFromTextView = true
                context.coordinator.parent.onTextChange(textView.string)
                context.coordinator.isUpdatingFromTextView = false
            } else {
                context.coordinator.isUpdatingFromSwiftUI = true
                let saved = textView.selectedRange()
                textView.string = text
                if saved.location <= (text as NSString).length {
                    textView.setSelectedRange(saved)
                }
                context.coordinator.isUpdatingFromSwiftUI = false
                context.coordinator.applySyntaxHighlighting()
            }
        } else if context.coordinator.lastLanguage != language {
            context.coordinator.lastLanguage = language
            context.coordinator.applySyntaxHighlighting()
        }

        applySearchHighlights(on: textView)

        if selectedRange.location != NSNotFound,
           NSMaxRange(selectedRange) <= (textView.string as NSString).length,
           textView.selectedRange() != selectedRange {
            textView.setSelectedRange(selectedRange)
            textView.showFindIndicator(for: selectedRange)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
        CGSize(
            width: proposal.width ?? 800,
            height: proposal.height ?? max(200, (proposal.height ?? 400))
        )
    }

    private func configureLayout(scrollView: NSScrollView, textView: NSTextView) {
        textView.isHorizontallyResizable = !wordWrap
        let width = max(scrollView.contentSize.width, scrollView.bounds.width, 400)
        if wordWrap {
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        } else {
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }

    private func applyFont(to textView: NSTextView) {
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    private func applySearchHighlights(on textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let full = NSRange(location: 0, length: storage.length)
        storage.removeAttribute(.backgroundColor, range: full)
        for range in highlightRanges where NSMaxRange(range) <= full.length {
            storage.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.35), range: range)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextEditorView
        weak var textView: CodeTextView?
        weak var scrollView: NSScrollView?
        var isUpdatingFromSwiftUI = false
        var isUpdatingFromTextView = false
        var lastLanguage: EditorLanguage = .normal_lang
        private var highlightWorkItem: DispatchWorkItem?

        init(_ parent: TextEditorView) {
            self.parent = parent
            self.lastLanguage = parent.language
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI, let textView else { return }
            isUpdatingFromTextView = true
            parent.onTextChange(textView.string)
            isUpdatingFromTextView = false
            scheduleSyntaxHighlighting()
            scrollView?.verticalRulerView?.needsDisplay = true
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            DispatchQueue.main.async { [weak self] in
                self?.textView?.notifySelection()
            }
        }

        func applySyntaxHighlighting() {
            guard let textView, let storage = textView.textStorage else { return }
            let dark = textView.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let font = NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular)
            SyntaxHighlighter.apply(to: storage, language: parent.language, font: font, darkMode: dark)
        }

        private func scheduleSyntaxHighlighting() {
            highlightWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                DispatchQueue.main.async {
                    self?.applySyntaxHighlighting()
                }
            }
            highlightWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
        }
    }
}
