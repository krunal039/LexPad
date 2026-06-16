import AppKit
import Foundation

public enum SpellCheckEngine {
    public static func misspelledRanges(in text: String, language: String? = nil) -> [NSRange] {
        let checker = NSSpellChecker.shared
        let ns = text as NSString
        var ranges: [NSRange] = []
        var searchRange = NSRange(location: 0, length: ns.length)

        while searchRange.location < ns.length {
            let wordRange = checker.checkSpelling(
                of: text,
                startingAt: searchRange.location,
                language: language,
                wrap: false,
                inSpellDocumentWithTag: 0,
                wordCount: nil
            )
            if wordRange.location == NSNotFound { break }
            if wordRange.length >= 2, isLikelyWord(ns.substring(with: wordRange)) {
                ranges.append(wordRange)
            }
            searchRange.location = wordRange.location + max(1, wordRange.length)
            searchRange.length = ns.length - searchRange.location
        }
        return ranges
    }

    private static func isLikelyWord(_ word: String) -> Bool {
        guard let first = word.unicodeScalars.first else { return false }
        return CharacterSet.letters.contains(first)
    }
}
