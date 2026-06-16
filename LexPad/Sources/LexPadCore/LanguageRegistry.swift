import Foundation

public enum LanguageRegistry {
    private static let extensionMap: [String: EditorLanguage] = {
        var map: [String: EditorLanguage] = [:]
        for spec in LanguageRegistryData.languages {
            for ext in spec.extensions {
                map[ext.lowercased()] = spec.id
            }
        }
        return map
    }()

    public static func detect(from url: URL) -> EditorLanguage {
        let filename = url.lastPathComponent.lowercased()
        if let language = LanguageRegistryData.filenameMap[filename] {
            return language
        }
        let ext = url.pathExtension.lowercased()
        if ext.isEmpty { return .normal_lang }
        return extensionMap[ext] ?? .normal_lang
    }

    public static func keywords(for language: EditorLanguage) -> [String] {
        spec(for: language)?.keywords ?? []
    }

    static func spec(for language: EditorLanguage) -> LanguageRegistryData.LanguageSpec? {
        LanguageRegistryData.languages.first { $0.id == language }
    }

    public static var languageCount: Int { LanguageRegistryData.languages.count }

    public static func lexillaName(for language: EditorLanguage) -> String? {
        spec(for: language)?.lexillaName
    }

    static func commentStyle(for language: EditorLanguage) -> LanguageRegistryData.CommentStyle? {
        spec(for: language)?.commentStyle
    }
}
