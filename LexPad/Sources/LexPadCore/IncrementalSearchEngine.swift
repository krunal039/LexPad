import Foundation

public struct IncrementalSearchState: Sendable {
    public var pattern: String
    public var matchCase: Bool
    public var currentIndex: Int

    public init(pattern: String = "", matchCase: Bool = false, currentIndex: Int = 0) {
        self.pattern = pattern
        self.matchCase = matchCase
        self.currentIndex = currentIndex
    }
}

public enum IncrementalSearchEngine {
    public static func matches(in text: String, state: IncrementalSearchState) -> [FindMatch] {
        guard !state.pattern.isEmpty else { return [] }
        let options = FindOptions(pattern: state.pattern, isRegex: false, matchCase: state.matchCase, wholeWord: false)
        return (try? FindEngine.findAll(in: text, options: options)) ?? []
    }

    public static func currentMatch(in text: String, state: IncrementalSearchState) -> FindMatch? {
        let all = matches(in: text, state: state)
        guard !all.isEmpty else { return nil }
        let index = ((state.currentIndex % all.count) + all.count) % all.count
        return all[index]
    }

    public static func nextIndex(matchCount: Int, current: Int) -> Int {
        guard matchCount > 0 else { return 0 }
        return (current + 1) % matchCount
    }

    public static func previousIndex(matchCount: Int, current: Int) -> Int {
        guard matchCount > 0 else { return 0 }
        return (current - 1 + matchCount) % matchCount
    }
}
