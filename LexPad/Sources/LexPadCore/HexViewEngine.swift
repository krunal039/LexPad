import Foundation

public struct HexLine: Identifiable, Sendable {
    public let id: Int
    public let offset: Int
    public let hex: String
    public let ascii: String

    public init(id: Int, offset: Int, hex: String, ascii: String) {
        self.id = id
        self.offset = offset
        self.hex = hex
        self.ascii = ascii
    }
}

public enum HexViewEngine {
    public static func lines(from data: Data, bytesPerLine: Int = 16, maxLines: Int = 4096) -> [HexLine] {
        guard !data.isEmpty else { return [] }
        var result: [HexLine] = []
        var offset = 0
        var lineIndex = 0
        while offset < data.count, lineIndex < maxLines {
            let end = min(offset + bytesPerLine, data.count)
            let chunk = data[offset..<end]
            let hex = chunk.map { String(format: "%02X", $0) }.joined(separator: " ")
            let ascii = chunk.map { byte -> String in
                (32...126).contains(byte) ? String(UnicodeScalar(byte)) : "."
            }.joined()
            result.append(HexLine(id: lineIndex, offset: offset, hex: hex, ascii: ascii))
            offset = end
            lineIndex += 1
        }
        return result
    }

    public static func data(for url: URL, maxBytes: Int = 256 * 1024) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        return try? handle.read(upToCount: maxBytes)
    }
}
