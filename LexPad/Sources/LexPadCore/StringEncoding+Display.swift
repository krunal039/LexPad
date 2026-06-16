import Foundation

public extension String.Encoding {
    var displayName: String {
        switch self {
        case .utf8: return "UTF-8"
        case .utf16: return "UTF-16"
        case .utf16LittleEndian: return "UTF-16 LE"
        case .utf16BigEndian: return "UTF-16 BE"
        case .utf32: return "UTF-32"
        case .ascii: return "ASCII"
        case .isoLatin1: return "ISO Latin-1"
        case .windowsCP1252: return "Windows-1252"
        case .macOSRoman: return "Mac Roman"
        case .japaneseEUC: return "Japanese (EUC)"
        case .shiftJIS: return "Shift JIS"
        default: return "Unknown"
        }
    }
}
