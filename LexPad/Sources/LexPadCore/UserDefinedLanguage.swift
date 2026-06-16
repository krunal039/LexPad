import Foundation

public struct UserDefinedLanguage: Codable, Identifiable, Sendable, Equatable, Hashable {
    public var id: String
    public var name: String
    public var extensions: [String]
    public var keywords: [String]
    public var keywords2: [String]
    public var baseLexer: String
    public var commentLine: String

    public init(
        id: String = UUID().uuidString,
        name: String,
        extensions: [String],
        keywords: [String] = [],
        keywords2: [String] = [],
        baseLexer: String = "cpp",
        commentLine: String = "//"
    ) {
        self.id = id
        self.name = name
        self.extensions = extensions
        self.keywords = keywords
        self.keywords2 = keywords2
        self.baseLexer = baseLexer
        self.commentLine = commentLine
    }

    public var allKeywords: [String] { keywords + keywords2 }

    public var fileExtensionList: String {
        extensions.joined(separator: ", ")
    }
}

public enum LanguageDisplay {
    public static func name(for document: TextDocument, userLanguages: [UserDefinedLanguage]) -> String {
        if let id = document.userLanguageID,
           let udl = userLanguages.first(where: { $0.id == id }) {
            return udl.name
        }
        return document.language.rawValue
    }
}

public struct LanguageContext: Sendable {
    public let editorLanguage: EditorLanguage
    public let userLanguage: UserDefinedLanguage?

    public init(editorLanguage: EditorLanguage, userLanguage: UserDefinedLanguage?) {
        self.editorLanguage = editorLanguage
        self.userLanguage = userLanguage
    }

    public var displayName: String {
        userLanguage?.name ?? editorLanguage.rawValue
    }

    public var lexillaName: String? {
        if let userLanguage { return userLanguage.baseLexer }
        return LanguageRegistry.lexillaName(for: editorLanguage)
    }

    public var commentLinePrefix: String {
        if let userLanguage {
            let trimmed = userLanguage.commentLine.trimmingCharacters(in: .whitespaces)
            return trimmed.hasSuffix(" ") ? trimmed : trimmed + " "
        }
        return CommentEngine.lineCommentPrefix(for: editorLanguage) ?? "// "
    }

    public static func keywords(for language: EditorLanguage, userLanguage: UserDefinedLanguage?) -> [String] {
        if let userLanguage, !userLanguage.allKeywords.isEmpty {
            return userLanguage.allKeywords
        }
        return LanguageRegistry.keywords(for: language)
    }
}

@MainActor
public final class UserLanguageStore: ObservableObject {
    public static let shared = UserLanguageStore()

    @Published public private(set) var languages: [UserDefinedLanguage] = []

    public init() {
        reload()
    }

    public func reload() {
        languages = UserLanguagePersistence.loadAll()
    }

    public func language(id: String?) -> UserDefinedLanguage? {
        guard let id else { return nil }
        return languages.first { $0.id == id }
    }

    public func detect(from url: URL) -> String? {
        UserLanguagePersistence.detect(from: url)
    }

    public func save(_ language: UserDefinedLanguage) throws {
        try UserLanguagePersistence.save(language)
        reload()
    }

    public func delete(id: String) throws {
        try UserLanguagePersistence.delete(id: id)
        reload()
    }

    public static func sample() -> UserDefinedLanguage {
        UserDefinedLanguage(
            name: "My DSL",
            extensions: ["dsl"],
            keywords: ["module", "import", "export", "func", "let", "true", "false"],
            keywords2: ["print", "read", "write"],
            baseLexer: "cpp",
            commentLine: "//"
        )
    }
}
