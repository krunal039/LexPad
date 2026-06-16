import Foundation
import LexPadCore

@main
enum LexPadBenchmark {
    static func main() {
        let megabytes = Int(CommandLine.arguments.dropFirst().first ?? "100") ?? 100
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("lexpad-benchmark-\(megabytes)mb.log")

        print("Generating \(megabytes)MB sample log...")
        generateSampleLog(at: tempURL, megabytes: megabytes)

        print("Loading file...")
        let loadStart = CFAbsoluteTimeGetCurrent()
        let doc: TextDocument
        do {
            doc = try DocumentStore.load(from: tempURL)
        } catch {
            fputs("Load failed: \(error)\n", stderr)
            exit(1)
        }
        let loadSeconds = CFAbsoluteTimeGetCurrent() - loadStart
        print(String(format: "Loaded %.1f MB in %.3fs (%d lines)", Double(doc.characterCount) / 1024 / 1024, loadSeconds, doc.lineCount))

        let bench = FindEngine.benchmarkFind(in: doc.text, pattern: "ERROR.*timeout", isRegex: true)
        print("Regex find: \(bench.matches) matches in \(String(format: "%.3f", bench.seconds))s")

        let passLoad = loadSeconds < 3.0
        let passFind = bench.seconds < 2.0
        print(passLoad && passFind ? "PASS: Phase 0 spike criteria met" : "FAIL: Performance criteria not met")
        exit(passLoad && passFind ? 0 : 1)
    }

    private static func generateSampleLog(at url: URL, megabytes: Int) {
        let target = megabytes * 1024 * 1024
        var written = 0
        var i = 0
        try? FileManager.default.removeItem(at: url)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let handle = try! FileHandle(forWritingTo: url)
        defer { try? handle.close() }

        while written < target {
            let line = "2026-06-15 ERROR server=server-\(i % 50) message=request_id=\(String(format: "%08d", i)) status=timeout\n"
            let data = Data(line.utf8)
            handle.write(data)
            written += data.count
            i += 1
        }
    }
}
