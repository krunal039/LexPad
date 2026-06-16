import Foundation

public enum ExtendedFind {
    /// Notepad++ extended mode: `\n`, `\r`, `\t`, `\\`
    public static func expandPattern(_ pattern: String) -> String {
        var result = ""
        var i = pattern.startIndex
        while i < pattern.endIndex {
            if pattern[i] == "\\", pattern.index(after: i) < pattern.endIndex {
                let next = pattern[pattern.index(after: i)]
                switch next {
                case "n": result.append("\n")
                case "r": result.append("\r")
                case "t": result.append("\t")
                case "\\": result.append("\\")
                default: result.append(next)
                }
                i = pattern.index(i, offsetBy: 2)
            } else {
                result.append(pattern[i])
                i = pattern.index(after: i)
            }
        }
        return result
    }

    public static func resolvedPattern(for options: FindOptions) -> String {
        if options.isExtended && !options.isRegex {
            return expandPattern(options.pattern)
        }
        return options.pattern
    }
}
