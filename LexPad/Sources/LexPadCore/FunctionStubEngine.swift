import Foundation

public enum FunctionStubEngine {
    public static func stub(for language: EditorLanguage, name: String = "newFunction") -> String {
        let safe = name.isEmpty ? "newFunction" : name
        switch language {
        case .python_lang:
            return "def \(safe)():\n    pass\n"
        case .swift_lang:
            return "func \(safe)() {\n    \n}\n"
        case .ruby_lang:
            return "def \(safe)\n    \nend\n"
        case .go_lang:
            return "func \(safe)() {\n    \n}\n"
        case .rust_lang:
            return "fn \(safe)() {\n    \n}\n"
        case .java_lang, .kotlin_lang:
            return "void \(safe)() {\n    \n}\n"
        default:
            return "function \(safe)() {\n    \n}\n"
        }
    }
}
