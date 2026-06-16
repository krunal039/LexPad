import AppKit
import LexPadCore
import SwiftUI

struct TextEditorView: NSViewRepresentable {
    @Binding var text: String
    var selectedRange: NSRange
    var highlightRanges: [NSRange]
    var onTextChange: (String) -> Void
    var onSelectionChange: (Int, Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .textColor
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.string = text

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            context.coordinator.isUpdatingFromSwiftUI = true
            textView.string = text
            context.coordinator.isUpdatingFromSwiftUI = false
        }

        applyHighlights(on: textView)
    }

    private func applyHighlights(on textView: NSTextView) {
        let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
        textView.textStorage?.removeAttribute(.backgroundColor, range: fullRange)

        for range in highlightRanges where NSMaxRange(range) <= fullRange.length {
            textView.textStorage?.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.35), range: range)
        }

        if selectedRange.location != NSNotFound,
           NSMaxRange(selectedRange) <= fullRange.length,
           selectedRange.length > 0 {
            textView.showFindIndicator(for: selectedRange)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextEditorView
        weak var textView: NSTextView?
        var isUpdatingFromSwiftUI = false

        init(_ parent: TextEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI, let textView else { return }
            parent.onTextChange(textView.string)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView else { return }
            let nsText = textView.string as NSString
            let location = min(textView.selectedRange().location, nsText.length)
            let prefix = nsText.substring(to: location)
            let line = prefix.filter { $0 == "\n" }.count + 1
            let lastNewline = prefix.lastIndex(of: "\n")
            let column: Int
            if let lastNewline {
                column = prefix.distance(from: lastNewline, to: prefix.endIndex) + 1
            } else {
                column = prefix.count + 1
            }
            parent.onSelectionChange(line, column)
        }
    }
}
