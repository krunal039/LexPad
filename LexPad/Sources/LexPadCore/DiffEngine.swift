import Foundation

public enum DiffLineKind: Sendable {
    case unchanged, added, removed
}

public struct DiffLine: Identifiable, Sendable {
    public let id = UUID()
    public let kind: DiffLineKind
    public let leftLineNumber: Int?
    public let rightLineNumber: Int?
    public let text: String

    public init(kind: DiffLineKind, leftLineNumber: Int?, rightLineNumber: Int?, text: String) {
        self.kind = kind
        self.leftLineNumber = leftLineNumber
        self.rightLineNumber = rightLineNumber
        self.text = text
    }
}

public enum DiffEngine {
    /// Line-based diff using LCS backtracking.
    public static func compare(left: String, right: String) -> [DiffLine] {
        diffLines(left.components(separatedBy: "\n"), right.components(separatedBy: "\n"))
    }

    private static func diffLines(_ a: [String], _ b: [String]) -> [DiffLine] {
        let m = a.count, n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 1...m {
            for j in 1...n where a[i - 1] == b[j - 1] {
                dp[i][j] = dp[i - 1][j - 1] + 1
            }
        }

        var stack: [(kind: DiffLineKind, left: Int?, right: Int?, text: String)] = []
        var i = m, j = n
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && a[i - 1] == b[j - 1] {
                stack.append((.unchanged, i, j, a[i - 1]))
                i -= 1; j -= 1
            } else if j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j]) {
                stack.append((.added, nil, j, b[j - 1]))
                j -= 1
            } else {
                stack.append((.removed, i, nil, a[i - 1]))
                i -= 1
            }
        }

        return stack.reversed().map {
            DiffLine(kind: $0.kind, leftLineNumber: $0.left, rightLineNumber: $0.right, text: $0.text)
        }
    }
}
