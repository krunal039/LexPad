import Foundation

public enum ColumnEditorEngine {
    /// Insert ascending numbers at the end of each line in the selection (or caret line).
    public static func insertNumbers(
        in text: String,
        selectedRange: NSRange,
        start: Int,
        step: Int,
        padWidth: Int
    ) -> String {
        let ns = text as NSString
        guard ns.length > 0 else { return text }
        let lineRange = lineRangeForSelection(in: ns, selectedRange: selectedRange)
        var lines = text.components(separatedBy: "\n")
        var value = start
        for i in (lineRange.lowerBound - 1)..<min(lineRange.upperBound, lines.count) {
            let formatted = padWidth > 0 ? String(format: "%0\(padWidth)d", value) : String(value)
            lines[i] = lines[i] + formatted
            value += step
        }
        return lines.joined(separator: "\n")
    }

    private static func lineRangeForSelection(in ns: NSString, selectedRange: NSRange) -> ClosedRange<Int> {
        let startPos = min(max(0, selectedRange.location), max(0, ns.length - 1))
        let endPos: Int
        if selectedRange.length > 0 {
            endPos = min(NSMaxRange(selectedRange) - 1, ns.length - 1)
        } else {
            endPos = startPos
        }
        let startLine = lineNumber(in: ns, at: startPos)
        var endLine = lineNumber(in: ns, at: endPos)
        if selectedRange.length > 0, endPos < ns.length, ns.character(at: endPos) == 10 {
            endLine = max(startLine, endLine - 1)
        }
        return startLine...max(startLine, endLine)
    }

    private static func lineNumber(in ns: NSString, at position: Int) -> Int {
        guard ns.length > 0 else { return 1 }
        let prefix = ns.substring(to: position + 1) as NSString
        var count = 1
        for i in 0..<prefix.length where prefix.character(at: i) == 10 { count += 1 }
        return count
    }
}
