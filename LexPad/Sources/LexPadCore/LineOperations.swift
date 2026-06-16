import Foundation

public enum LineOperations {
    public static func duplicateLine(in text: String, line: Int) -> String {
        let lines = text.components(separatedBy: "\n")
        guard line >= 1, line <= lines.count else { return text }
        var copy = lines
        copy.insert(lines[line - 1], at: line)
        return copy.joined(separator: "\n")
    }

    public static func moveLineUp(in text: String, line: Int) -> String {
        let lines = text.components(separatedBy: "\n")
        guard line > 1, line <= lines.count else { return text }
        var copy = lines
        copy.swapAt(line - 2, line - 1)
        return copy.joined(separator: "\n")
    }

    public static func moveLineDown(in text: String, line: Int) -> String {
        let lines = text.components(separatedBy: "\n")
        guard line >= 1, line < lines.count else { return text }
        var copy = lines
        copy.swapAt(line - 1, line)
        return copy.joined(separator: "\n")
    }

    public static func removeEmptyLines(in text: String, includingWhitespace: Bool) -> String {
        let lines = text.components(separatedBy: "\n")
        let filtered = lines.filter { line in
            includingWhitespace ? !line.trimmingCharacters(in: .whitespaces).isEmpty : !line.isEmpty
        }
        return filtered.joined(separator: "\n")
    }

    public static func removeDuplicateLines(in text: String, consecutiveOnly: Bool) -> String {
        let lines = text.components(separatedBy: "\n")
        if consecutiveOnly {
            var result: [String] = []
            for line in lines {
                if result.last != line { result.append(line) }
            }
            return result.joined(separator: "\n")
        }
        var seen = Set<String>()
        var result: [String] = []
        for line in lines where seen.insert(line).inserted {
            result.append(line)
        }
        return result.joined(separator: "\n")
    }

    public static func joinLines(in text: String, range: ClosedRange<Int>?) -> String {
        var lines = text.components(separatedBy: "\n")
        let r = range ?? 1...lines.count
        let lo = max(1, r.lowerBound) - 1
        let hi = min(lines.count, r.upperBound)
        guard lo < hi else { return text }
        let joined = lines[lo..<hi].joined(separator: " ")
        lines.replaceSubrange(lo..<hi, with: [joined])
        return lines.joined(separator: "\n")
    }

    /// Split the current line at the caret column (or at each comma when `splitOnComma`).
    public static func splitLine(in text: String, line: Int, column: Int, splitOnComma: Bool = false) -> String {
        var lines = text.components(separatedBy: "\n")
        guard line >= 1, line <= lines.count else { return text }
        let idx = line - 1
        let current = lines[idx]
        if splitOnComma, current.contains(",") {
            let parts = current.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            lines.replaceSubrange(idx...idx, with: parts)
            return lines.joined(separator: "\n")
        }
        let col = max(0, min(column - 1, current.count))
        let splitIndex = current.index(current.startIndex, offsetBy: col)
        let left = String(current[..<splitIndex])
        let right = String(current[splitIndex...])
        lines.replaceSubrange(idx...idx, with: [left, right])
        return lines.joined(separator: "\n")
    }

    public static func sortLines(in text: String, ascending: Bool, caseInsensitive: Bool) -> String {
        var lines = text.components(separatedBy: "\n")
        lines.sort { a, b in
            let cmp: ComparisonResult
            if caseInsensitive {
                cmp = a.localizedCaseInsensitiveCompare(b)
            } else {
                cmp = a.compare(b)
            }
            return ascending ? cmp == .orderedAscending : cmp == .orderedDescending
        }
        return lines.joined(separator: "\n")
    }

    public static func reverseLines(in text: String) -> String {
        text.components(separatedBy: "\n").reversed().joined(separator: "\n")
    }

    public static func trimLines(in text: String, leading: Bool, trailing: Bool) -> String {
        text.components(separatedBy: "\n").map { line in
            var s = line
            if leading { s = String(s.drop(while: { $0 == " " || $0 == "\t" })) }
            if trailing { s = String(s.reversed().drop(while: { $0 == " " || $0 == "\t" }).reversed()) }
            return s
        }.joined(separator: "\n")
    }

    public static func tabsToSpaces(in text: String, tabSize: Int = 4, leadingOnly: Bool = false) -> String {
        let spaces = String(repeating: " ", count: tabSize)
        return text.components(separatedBy: "\n").map { line in
            if leadingOnly {
                var count = 0
                for ch in line {
                    if ch == "\t" { count += 1 } else { break }
                }
                return String(repeating: spaces, count: count) + line.dropFirst(count)
            }
            return line.replacingOccurrences(of: "\t", with: spaces)
        }.joined(separator: "\n")
    }

    public static func spacesToTabs(in text: String, tabSize: Int = 4, leadingOnly: Bool = false) -> String {
        text.components(separatedBy: "\n").map { line in
            convertSpacesToTabs(line, tabSize: tabSize, leadingOnly: leadingOnly)
        }.joined(separator: "\n")
    }

    private static func convertSpacesToTabs(_ line: String, tabSize: Int, leadingOnly: Bool) -> String {
        var result = ""
        var i = line.startIndex
        while i < line.endIndex {
            if line[i] == " " {
                var spaces = 0
                var j = i
                while j < line.endIndex, line[j] == " " {
                    spaces += 1
                    j = line.index(after: j)
                }
                if leadingOnly && !result.isEmpty {
                    result += String(line[i..<j])
                } else {
                    let tabs = spaces / tabSize
                    let rem = spaces % tabSize
                    result += String(repeating: "\t", count: tabs) + String(repeating: " ", count: rem)
                }
                i = j
            } else {
                if leadingOnly { return line }
                result.append(line[i])
                i = line.index(after: i)
            }
        }
        return result
    }

    public static func convertCase(in text: String, mode: CaseMode) -> String {
        switch mode {
        case .upper: return text.uppercased()
        case .lower: return text.lowercased()
        case .proper:
            return text.components(separatedBy: .whitespaces).map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined(separator: " ")
        case .invert:
            return String(text.map { ch in ch.isUppercase ? Character(ch.lowercased()) : Character(ch.uppercased()) })
        }
    }

    public enum CaseMode { case upper, lower, proper, invert }

    public static func convertEndOfLine(in text: String, to target: EndOfLine) -> String {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        switch target {
        case .lf: return normalized
        case .crlf: return normalized.replacingOccurrences(of: "\n", with: "\r\n")
        case .cr: return normalized.replacingOccurrences(of: "\n", with: "\r")
        }
    }

    public static func lineIndex(in text: String, line: Int) -> String.Index? {
        guard line >= 1 else { return nil }
        var current = 1
        var idx = text.startIndex
        while idx < text.endIndex {
            if current == line { return idx }
            if text[idx] == "\n" {
                current += 1
                if current == line {
                    return text.index(after: idx)
                }
            }
            idx = text.index(after: idx)
        }
        return current == line ? idx : nil
    }
}
