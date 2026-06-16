import Foundation

public enum SelectNextEngine {
    /// Expands an empty caret position to the word under the cursor.
    public static func wordRange(at location: Int, in text: String) -> NSRange? {
        let ns = text as NSString
        guard location >= 0, location <= ns.length else { return nil }
        if ns.length == 0 { return nil }

        var start = location
        var end = location
        let set = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))

        while start > 0 {
            let ch = ns.character(at: start - 1)
            guard let scalar = UnicodeScalar(ch), set.contains(scalar) else { break }
            start -= 1
        }
        while end < ns.length {
            let ch = ns.character(at: end)
            guard let scalar = UnicodeScalar(ch), set.contains(scalar) else { break }
            end += 1
        }
        guard end > start else { return nil }
        return NSRange(location: start, length: end - start)
    }

    /// Finds the next literal occurrence of `needle` after `searchAfter`, optionally wrapping.
    public static func nextOccurrence(
        of needle: String,
        in text: String,
        after searchAfter: Int,
        matchCase: Bool,
        wholeWord: Bool,
        wrapAround: Bool = true
    ) -> NSRange? {
        guard !needle.isEmpty else { return nil }
        let ns = text as NSString
        let options: NSString.CompareOptions = matchCase ? [] : [.caseInsensitive]
        let tailStart = min(max(0, searchAfter), ns.length)
        let tailRange = NSRange(location: tailStart, length: ns.length - tailStart)

        if let found = find(in: ns, needle: needle, range: tailRange, options: options, wholeWord: wholeWord) {
            return found
        }
        guard wrapAround, searchAfter > 0 else { return nil }
        let headRange = NSRange(location: 0, length: min(searchAfter, ns.length))
        return find(in: ns, needle: needle, range: headRange, options: options, wholeWord: wholeWord)
    }

    private static func find(
        in ns: NSString,
        needle: String,
        range: NSRange,
        options: NSString.CompareOptions,
        wholeWord: Bool
    ) -> NSRange? {
        var search = range
        while search.length > 0 {
            let found = ns.range(of: needle, options: options, range: search)
            guard found.location != NSNotFound else { return nil }
            if !wholeWord || isWholeWord(found, in: ns) {
                return found
            }
            let next = found.location + max(found.length, 1)
            search = NSRange(location: next, length: NSMaxRange(range) - next)
        }
        return nil
    }

    private static func isWholeWord(_ range: NSRange, in ns: NSString) -> Bool {
        let set = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if range.location > 0 {
            let ch = ns.character(at: range.location - 1)
            if let scalar = UnicodeScalar(ch), set.contains(scalar) { return false }
        }
        let end = NSMaxRange(range)
        if end < ns.length {
            let ch = ns.character(at: end)
            if let scalar = UnicodeScalar(ch), set.contains(scalar) { return false }
        }
        return true
    }
}
