import Foundation

public enum SmartHighlightEngine {
    public static func wordRange(at position: Int, in text: String) -> NSRange? {
        let ns = text as NSString
        guard position >= 0, position <= ns.length else { return nil }
        if ns.length == 0 { return nil }

        var start = position
        if start == ns.length { start = max(0, start - 1) }

        let set = NSMutableCharacterSet.alphanumeric()
        set.addCharacters(in: "_")

        while start > 0 {
            let ch = ns.character(at: start - 1)
            if ch == 10 || ch == 13 { break }
            if !set.characterIsMember(unichar(ch)) { break }
            start -= 1
        }
        var end = start
        while end < ns.length {
            let ch = ns.character(at: end)
            if ch == 10 || ch == 13 { break }
            if !set.characterIsMember(unichar(ch)) { break }
            end += 1
        }
        let length = end - start
        guard length >= 2 else { return nil }
        return NSRange(location: start, length: length)
    }

    public static func allOccurrences(of word: String, in text: String, matchCase: Bool = false) -> [NSRange] {
        guard !word.isEmpty else { return [] }
        let ns = text as NSString
        var ranges: [NSRange] = []
        var search = NSRange(location: 0, length: ns.length)
        let options: NSString.CompareOptions = matchCase ? [] : [.caseInsensitive]
        while search.location < ns.length {
            let found = ns.range(of: word, options: options, range: search)
            if found.location == NSNotFound { break }
            if isWholeWord(found, in: ns) {
                ranges.append(found)
            }
            search.location = found.location + max(1, found.length)
            search.length = ns.length - search.location
        }
        return ranges
    }

    private static func isWholeWord(_ range: NSRange, in ns: NSString) -> Bool {
        let set = NSMutableCharacterSet.alphanumeric()
        set.addCharacters(in: "_")
        if range.location > 0 {
            let ch = ns.character(at: range.location - 1)
            if set.characterIsMember(unichar(ch)) { return false }
        }
        if NSMaxRange(range) < ns.length {
            let ch = ns.character(at: NSMaxRange(range))
            if set.characterIsMember(unichar(ch)) { return false }
        }
        return true
    }
}
