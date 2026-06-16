import Foundation

public struct Bookmark: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var line: Int
    public var label: String?
    public var style: MarkStyle

    public init(id: UUID = UUID(), line: Int, label: String? = nil, style: MarkStyle = .style3) {
        self.id = id
        self.line = line
        self.label = label
        self.style = style
    }
}

public enum BookmarkStore {
    public static func toggle(bookmarks: inout [Bookmark], line: Int, style: MarkStyle = .style3) -> Bool {
        if let idx = bookmarks.firstIndex(where: { $0.line == line }) {
            bookmarks.remove(at: idx)
            return false
        }
        bookmarks.append(Bookmark(line: line, style: style))
        bookmarks.sort { $0.line < $1.line }
        return true
    }

    public static func next(from line: Int, in bookmarks: [Bookmark]) -> Bookmark? {
        bookmarks.first { $0.line > line } ?? bookmarks.first
    }

    public static func previous(from line: Int, in bookmarks: [Bookmark]) -> Bookmark? {
        bookmarks.last { $0.line < line } ?? bookmarks.last
    }

    public static func clearAll(in bookmarks: inout [Bookmark]) {
        bookmarks.removeAll()
    }

    public static func bookmarkAll(lines: [Int], in bookmarks: inout [Bookmark], style: MarkStyle = .style3) {
        for line in lines where line >= 1 {
            if !bookmarks.contains(where: { $0.line == line }) {
                bookmarks.append(Bookmark(line: line, style: style))
            }
        }
        bookmarks.sort { $0.line < $1.line }
    }

    public static func setMark(on line: Int, style: MarkStyle, in bookmarks: inout [Bookmark]) {
        if let idx = bookmarks.firstIndex(where: { $0.line == line }) {
            bookmarks[idx].style = style
        } else {
            bookmarks.append(Bookmark(line: line, style: style))
            bookmarks.sort { $0.line < $1.line }
        }
    }

    public static func clearStyle(_ style: MarkStyle, in bookmarks: inout [Bookmark]) {
        bookmarks.removeAll { $0.style == style }
    }

    public static func clearAll(on document: inout TextDocument) {
        document.bookmarks.removeAll()
    }
}
