import Foundation
import LexPadCore

@main
enum LexPadBenchmark {
    static func main() {
        let megabytes = Int(CommandLine.arguments.dropFirst().first ?? "100") ?? 100
        let tempURL = URL(fileURLWithPath: "/tmp/lexpad-benchmark-\(megabytes)mb.log")

        print("Generating \(megabytes)MB sample log at \(tempURL.path)...")
        generateSampleLog(at: tempURL, megabytes: megabytes)

        print("Loading file (mmap)...")
        let mmapStart = CFAbsoluteTimeGetCurrent()
        let data = try! Data(contentsOf: tempURL, options: [.mappedIfSafe])
        let mmapSeconds = CFAbsoluteTimeGetCurrent() - mmapStart

        let decodeStart = CFAbsoluteTimeGetCurrent()
        let text = String(decoding: data, as: UTF8.self)
        let decodeSeconds = CFAbsoluteTimeGetCurrent() - decodeStart
        print(String(format: "Mmap: %.3fs | Decode: %.3fs | Lines: %d", mmapSeconds, decodeSeconds, text.split(separator: "\n", omittingEmptySubsequences: false).count))

        let bench = FindEngine.benchmarkFind(in: text, pattern: "ERROR", isRegex: false)
        print("Regex find: \(bench.matches) matches in \(String(format: "%.3f", bench.seconds))s")

        let passLoad = mmapSeconds < 1.0
        let passFind = bench.seconds < 2.0
        print(passLoad && passFind ? "PASS: Phase 0 spike criteria met" : "FAIL: Performance criteria not met (Scintilla integration expected to improve editor load/render)")
        exit(passLoad && passFind ? 0 : 1)
    }

    private static func generateSampleLog(at url: URL, megabytes: Int) {
        let line = "2026-06-15 ERROR server=server-001 message=request_id=00000001 status=timeout\n"
        let lineData = Data(line.utf8)
        let target = megabytes * 1024 * 1024

        try? FileManager.default.removeItem(at: url)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let handle = try! FileHandle(forWritingTo: url)
        defer { try? handle.close() }

        var buffer = Data()
        buffer.reserveCapacity(lineData.count * 8192)
        for _ in 0..<8192 { buffer.append(lineData) }

        var written = 0
        while written + buffer.count <= target {
            handle.write(buffer)
            written += buffer.count
        }
        let remainder = target - written
        if remainder > 0 {
            handle.write(lineData.prefix(remainder))
        }
    }
}
