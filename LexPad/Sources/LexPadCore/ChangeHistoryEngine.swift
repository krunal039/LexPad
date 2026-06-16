import Foundation

public enum LineChangeState: Int, Codable, Sendable {
    case none = 0
    case unsaved = 1
    case saved = 2
}

public enum ChangeHistoryEngine {
    public static func linesAffected(oldText: String, newText: String) -> Set<Int> {
        let oldLines = oldText.components(separatedBy: "\n")
        let newLines = newText.components(separatedBy: "\n")
        let count = max(oldLines.count, newLines.count)
        var affected = Set<Int>()
        for i in 0..<count {
            let oldLine = i < oldLines.count ? oldLines[i] : ""
            let newLine = i < newLines.count ? newLines[i] : ""
            if oldLine != newLine {
                affected.insert(i + 1)
            }
        }
        return affected
    }

    public static func markEdited(lines: Set<Int>, in history: inout [Int: LineChangeState]) {
        for line in lines where line >= 1 {
            if history[line] != .saved {
                history[line] = .unsaved
            }
        }
    }

    public static func commitSave(in history: inout [Int: LineChangeState]) {
        for line in history.keys {
            if history[line] == .unsaved {
                history[line] = .saved
            }
        }
    }

    public static func payload(for history: [Int: LineChangeState]) -> [[AnyHashable: Any]] {
        history.compactMap { line, state -> [AnyHashable: Any]? in
            guard state != .none else { return nil }
            return ["line": line, "state": state.rawValue]
        }
    }
}
