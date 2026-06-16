import Foundation

public struct GitFileStatus: Sendable, Identifiable {
    public let id: String
    public let path: String
    public let statusCode: String

    public var label: String {
        switch statusCode {
        case "M": return "Modified"
        case "A", "?": return "Added/Untracked"
        case "D": return "Deleted"
        default: return statusCode
        }
    }
}

public struct GitCommitResult: Sendable {
    public let succeeded: Bool
    public let output: String
}

public enum GitService {
    public static func repositoryRoot(for url: URL) -> URL? {
        var dir = url.deletingLastPathComponent()
        if url.hasDirectoryPath { dir = url }
        let fm = FileManager.default
        while dir.path != "/" {
            if fm.fileExists(atPath: dir.appendingPathComponent(".git").path) {
                return dir
            }
            dir.deleteLastPathComponent()
        }
        return nil
    }

    public static func currentBranch(at repoRoot: URL) -> String? {
        let result = runGit(["rev-parse", "--abbrev-ref", "HEAD"], in: repoRoot)
        guard result.exitCode == 0 else { return nil }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func status(at repoRoot: URL) -> [GitFileStatus] {
        let result = runGit(["status", "--porcelain"], in: repoRoot)
        guard result.exitCode == 0 else { return [] }
        return result.stdout
            .split(separator: "\n")
            .compactMap { line -> GitFileStatus? in
                let text = String(line)
                guard text.count > 3 else { return nil }
                let code = String(text.prefix(2)).trimmingCharacters(in: .whitespaces)
                let path = String(text.dropFirst(3))
                return GitFileStatus(id: path, path: path, statusCode: code.isEmpty ? "?" : String(code.prefix(1)))
            }
    }

    public static func diff(for filePath: String, at repoRoot: URL) -> String {
        let result = runGit(["diff", "--", filePath], in: repoRoot)
        return result.stdout
    }

    public static func stage(filePath: String, at repoRoot: URL) -> Bool {
        runGit(["add", "--", filePath], in: repoRoot).exitCode == 0
    }

    public static func commit(message: String, at repoRoot: URL) -> GitCommitResult {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return GitCommitResult(succeeded: false, output: "Commit message is empty.")
        }
        let result = runGit(["commit", "-m", trimmed], in: repoRoot)
        let output = result.stdout.isEmpty ? result.stderr : result.stdout
        return GitCommitResult(succeeded: result.exitCode == 0, output: output.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public static func initRepository(at directory: URL) -> Bool {
        runGit(["init"], in: directory).exitCode == 0
    }

    public static func blame(for filePath: String, at repoRoot: URL, maxLines: Int = 40) -> String {
        let result = runGit(["blame", "-c", "--abbrev=8", "--", filePath], in: repoRoot)
        guard result.exitCode == 0 else { return result.stderr }
        let lines = result.stdout.split(separator: "\n", omittingEmptySubsequences: false)
        if lines.count <= maxLines { return result.stdout }
        return lines.prefix(maxLines).joined(separator: "\n") + "\n…"
    }

    private static func runGit(_ args: [String], in directory: URL) -> (stdout: String, stderr: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = directory
        let out = Pipe()
        let err = Pipe()
        process.standardOutput = out
        process.standardError = err
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ("", error.localizedDescription, 1)
        }
        let stdout = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (stdout, stderr, process.terminationStatus)
    }
}
