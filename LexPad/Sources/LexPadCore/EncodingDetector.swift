import Foundation

public struct EncodingDetectionResult: Sendable {
    public let encoding: String.Encoding
    public let confidence: Double
    public let label: String

    public init(encoding: String.Encoding, confidence: Double, label: String) {
        self.encoding = encoding
        self.confidence = confidence
        self.label = label
    }
}

public enum EncodingDetector {
    /// BOM-first, then UTF-8 validity, then simple byte-distribution heuristics.
    public static func detect(in data: Data) -> EncodingDetectionResult {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            return EncodingDetectionResult(encoding: .utf8, confidence: 1.0, label: "UTF-8 BOM")
        }
        if data.starts(with: [0xFF, 0xFE, 0x00, 0x00]) {
            return EncodingDetectionResult(encoding: .utf32LittleEndian, confidence: 1.0, label: "UTF-32 LE BOM")
        }
        if data.starts(with: [0x00, 0x00, 0xFE, 0xFF]) {
            return EncodingDetectionResult(encoding: .utf32BigEndian, confidence: 1.0, label: "UTF-32 BE BOM")
        }
        if data.starts(with: [0xFF, 0xFE]) {
            return EncodingDetectionResult(encoding: .utf16LittleEndian, confidence: 1.0, label: "UTF-16 LE BOM")
        }
        if data.starts(with: [0xFE, 0xFF]) {
            return EncodingDetectionResult(encoding: .utf16BigEndian, confidence: 1.0, label: "UTF-16 BE BOM")
        }

        if String(data: data, encoding: .utf8) != nil {
            let asciiRatio = asciiByteRatio(in: data)
            if asciiRatio > 0.98 {
                return EncodingDetectionResult(encoding: .utf8, confidence: 0.95, label: "UTF-8 (ASCII)")
            }
            return EncodingDetectionResult(encoding: .utf8, confidence: 0.85, label: "UTF-8")
        }

        if let utf16 = detectUTF16WithoutBOM(data) {
            return utf16
        }

        let latin1Confidence = 0.55
        if String(data: data, encoding: .windowsCP1252) != nil {
            return EncodingDetectionResult(encoding: .windowsCP1252, confidence: latin1Confidence + 0.1, label: "Windows-1252")
        }
        return EncodingDetectionResult(encoding: .isoLatin1, confidence: latin1Confidence, label: "ISO Latin-1")
    }

    private static func asciiByteRatio(in data: Data) -> Double {
        guard !data.isEmpty else { return 1 }
        let ascii = data.filter { $0 < 0x80 }.count
        return Double(ascii) / Double(data.count)
    }

    private static func detectUTF16WithoutBOM(_ data: Data) -> EncodingDetectionResult? {
        guard data.count >= 4, data.count % 2 == 0 else { return nil }
        var zeroEven = 0, zeroOdd = 0
        for (i, byte) in data.enumerated() where byte == 0 {
            if i % 2 == 0 { zeroEven += 1 } else { zeroOdd += 1 }
        }
        if zeroOdd > zeroEven * 2, String(data: data, encoding: .utf16LittleEndian) != nil {
            return EncodingDetectionResult(encoding: .utf16LittleEndian, confidence: 0.7, label: "UTF-16 LE (guessed)")
        }
        if zeroEven > zeroOdd * 2, String(data: data, encoding: .utf16BigEndian) != nil {
            return EncodingDetectionResult(encoding: .utf16BigEndian, confidence: 0.7, label: "UTF-16 BE (guessed)")
        }
        return nil
    }
}
