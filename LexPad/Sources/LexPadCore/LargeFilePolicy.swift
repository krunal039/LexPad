import Foundation

public enum LargeFilePolicy {
    public static let defaultThresholdBytes: Int = 5 * 1024 * 1024

    public static func shouldUseLargeFileMode(byteCount: Int, threshold: Int = defaultThresholdBytes) -> Bool {
        byteCount >= threshold
    }

    public static func languageForLargeFile(current: EditorLanguage) -> EditorLanguage {
        .normal_lang
    }
}
