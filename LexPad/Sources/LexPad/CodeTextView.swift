import AppKit
import LexPadCore

final class CodeTextView: NSTextView {
    var onSelectionChange: ((Int, Int) -> Void)?

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            let point = convert(event.locationInWindow, from: nil)
            guard let layoutManager, let textContainer else {
                super.mouseDown(with: event)
                return
            }
            let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            var ranges = selectedRanges.map { $0.rangeValue }
            ranges.append(NSRange(location: index, length: 0))
            selectedRanges = ranges.map { NSValue(range: $0) }
            notifySelection()
            return
        }
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "l" {
            NotificationCenter.default.post(name: .lexPadGoToLine, object: nil)
            return
        }
        super.keyDown(with: event)
    }

    func notifySelection() {
        let nsText = string as NSString
        let location = min(selectedRange().location, nsText.length)
        let prefix = nsText.substring(to: location)
        let line = prefix.filter { $0 == "\n" }.count + 1
        let lastNewline = prefix.lastIndex(of: "\n")
        let column: Int
        if let lastNewline {
            column = prefix.distance(from: lastNewline, to: prefix.endIndex) + 1
        } else {
            column = prefix.count + 1
        }
        onSelectionChange?(line, column)
    }
}

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        ruleThickness = 44
        clientView = textView

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSText.didChangeNotification,
            object: textView
        )
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func textDidChange() {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView, let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else { return }

        NSColor.quaternaryLabelColor.setFill()
        bounds.fill()

        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor,
        ]

        let visible = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visible, in: textContainer)
        var lineNumber = 1
        var index = 0
        let nsString = textView.string as NSString

        while index < nsString.length {
            let lineRange = nsString.lineRange(for: NSRange(location: index, length: 0))
            if lineRange.location >= NSMaxRange(glyphRange) { break }
            if NSMaxRange(lineRange) >= glyphRange.location {
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: lineRange.location)
                var lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
                lineRect.origin.y += textView.textContainerOrigin.y - visible.origin.y
                let label = "\(lineNumber)" as NSString
                let size = label.size(withAttributes: attrs)
                let x = ruleThickness - size.width - 8
                label.draw(at: NSPoint(x: x, y: lineRect.origin.y), withAttributes: attrs)
            }
            lineNumber += 1
            index = NSMaxRange(lineRange)
        }
    }
}
