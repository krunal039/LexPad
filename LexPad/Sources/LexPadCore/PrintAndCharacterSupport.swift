import AppKit
import Foundation

public enum PrintSupport {
    @MainActor
    public static func print(document: TextDocument, fontSize: CGFloat = 12, showLineNumbers: Bool = true) {
        let numbered: String
        if showLineNumbers {
            let lines = document.text.components(separatedBy: "\n")
            let width = max(4, String(lines.count).count)
            numbered = lines.enumerated().map { index, line in
                String(format: "%\(width)d | %@", index + 1, line)
            }.joined(separator: "\n")
        } else {
            numbered = document.text
        }

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.string = numbered
        textView.sizeToFit()

        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36
        printInfo.jobDisposition = .save

        let operation = NSPrintOperation(view: textView, printInfo: printInfo)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        operation.run()
    }
}

public enum CharacterInsertCatalog {
    public struct Entry: Identifiable, Sendable {
        public let id: String
        public let label: String
        public let character: String

        public init(label: String, character: String) {
            self.id = label + character
            self.label = label
            self.character = character
        }
    }

    public static let categories: [(name: String, entries: [Entry])] = [
        ("ASCII Control", [
            Entry(label: "Tab", character: "\t"),
            Entry(label: "Newline", character: "\n"),
            Entry(label: "NUL", character: "\0"),
        ]),
        ("Symbols", [
            Entry(label: "©", character: "©"),
            Entry(label: "®", character: "®"),
            Entry(label: "™", character: "™"),
            Entry(label: "€", character: "€"),
            Entry(label: "£", character: "£"),
            Entry(label: "¥", character: "¥"),
            Entry(label: "°", character: "°"),
            Entry(label: "±", character: "±"),
            Entry(label: "×", character: "×"),
            Entry(label: "÷", character: "÷"),
        ]),
        ("Arrows", [
            Entry(label: "←", character: "←"),
            Entry(label: "→", character: "→"),
            Entry(label: "↑", character: "↑"),
            Entry(label: "↓", character: "↓"),
            Entry(label: "↔", character: "↔"),
        ]),
        ("Math", [
            Entry(label: "≤", character: "≤"),
            Entry(label: "≥", character: "≥"),
            Entry(label: "≠", character: "≠"),
            Entry(label: "≈", character: "≈"),
            Entry(label: "∞", character: "∞"),
            Entry(label: "√", character: "√"),
            Entry(label: "π", character: "π"),
        ]),
        ("HTML Entities", [
            Entry(label: "&amp;", character: "&"),
            Entry(label: "&lt;", character: "<"),
            Entry(label: "&gt;", character: ">"),
            Entry(label: "&nbsp;", character: "\u{00A0}"),
        ]),
    ]
}
