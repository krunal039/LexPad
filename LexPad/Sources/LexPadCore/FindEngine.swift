import Foundation

public struct FindOptions: Sendable {
    public var pattern: String
    public var isRegex: Bool
    public var matchCase: Bool
    public var wholeWord: Bool
    public var wrapAround: Bool

    public init(
        pattern: String,
        isRegex: Bool = false,
        matchCase: Bool = false,
        wholeWord: Bool = false,
        wrapAround: Bool = true
    ) {
        self.pattern = pattern
        self.isRegex = isRegex
        self.matchCase = matchCase
        self.wholeWord = wholeWord
        self.wrapAround = wrapAround
    }
}

public struct FindMatch: Sendable, Equatable {
    public let range: Range<String.Index>
    public let line: Int
    public let column: Int
}

public enum FindEngineError: Error, LocalizedError {
    case emptyPattern
    case invalidRegex(String)

    public var errorDescription: String? {
        switch self {
        case .emptyPattern: return "Search pattern is empty."
        case .invalidRegex(let message): return "Invalid regular expression: \(message)"
        }
    }
}

public enum FindEngine {
    public static func findAll(in text: String, options: FindOptions) throws -> [FindMatch] {
        guard !options.pattern.isEmpty else { throw FindEngineError.emptyPattern }

        let nsText = text as NSString
        let searchLength = nsText.length
        var matches: [FindMatch] = []
        var searchStart = 0

        let regex = try makeRegex(for: options)
        while searchStart <= searchLength {
            let searchRange = NSRange(location: searchStart, length: max(0, searchLength - searchStart))
            guard let result = regex.firstMatch(in: text, options: [], range: searchRange) else { break }
            if result.range.length == 0 { break }

            if let swiftRange = Range(result.range, in: text) {
                let prefix = nsText.substring(to: result.range.location)
                let line = prefix.filter { $0 == "\n" }.count + 1
                let lastNewline = prefix.lastIndex(of: "\n")
                let column: Int
                if let lastNewline {
                    column = prefix.distance(from: lastNewline, to: prefix.endIndex)
                } else {
                    column = prefix.count + 1
                }
                matches.append(FindMatch(range: swiftRange, line: line, column: column))
            }

            searchStart = result.range.location + max(1, result.range.length)
        }

        return matches
    }

    public static func findNext(
        in text: String,
        from selection: Range<String.Index>?,
        options: FindOptions
    ) throws -> FindMatch? {
        let all = try findAll(in: text, options: options)
        guard !all.isEmpty else { return nil }

        let start = selection?.lowerBound ?? text.startIndex
        if let next = all.first(where: { $0.range.lowerBound >= start }) {
            return next
        }
        return options.wrapAround ? all.first : nil
    }

    public static func replaceAll(in text: String, options: FindOptions, replacement: String) throws -> (text: String, count: Int) {
        guard !options.pattern.isEmpty else { throw FindEngineError.emptyPattern }
        let regex = try makeRegex(for: options)
        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.numberOfMatches(in: text, options: [], range: nsRange)
        let template = NSRegularExpression.escapedTemplate(for: replacement)
        let output = regex.stringByReplacingMatches(in: text, options: [], range: nsRange, withTemplate: template)
        return (output, matches)
    }

    /// Phase 0 spike benchmark helper.
    public static func benchmarkFind(in text: String, pattern: String, isRegex: Bool) -> (matches: Int, seconds: Double) {
        let start = CFAbsoluteTimeGetCurrent()
        let options = FindOptions(pattern: pattern, isRegex: isRegex, matchCase: false)
        let count = (try? findAll(in: text, options: options).count) ?? 0
        return (count, CFAbsoluteTimeGetCurrent() - start)
    }

    private static func makeRegex(for options: FindOptions) throws -> NSRegularExpression {
        let pattern: String
        if options.isRegex {
            pattern = options.pattern
        } else if options.wholeWord {
            pattern = "\\b\(NSRegularExpression.escapedPattern(for: options.pattern))\\b"
        } else {
            pattern = NSRegularExpression.escapedPattern(for: options.pattern)
        }

        var regexOptions: NSRegularExpression.Options = []
        if !options.matchCase {
            regexOptions.insert(.caseInsensitive)
        }

        do {
            return try NSRegularExpression(pattern: pattern, options: regexOptions)
        } catch {
            throw FindEngineError.invalidRegex(error.localizedDescription)
        }
    }
}
