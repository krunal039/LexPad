import Foundation
import SwiftUI

/// Notepad++-style mark styles (5 colors) for bookmarks and marked lines.
public enum MarkStyle: Int, Codable, Sendable, CaseIterable, Identifiable {
    case style1 = 1
    case style2 = 2
    case style3 = 3
    case style4 = 4
    case style5 = 5

    public var id: Int { rawValue }

    public var displayName: String { "Style \(rawValue)" }

    public var menuTitle: String {
        switch self {
        case .style1: return "Mark Style 1 (Red)"
        case .style2: return "Mark Style 2 (Green)"
        case .style3: return "Mark Style 3 (Blue)"
        case .style4: return "Mark Style 4 (Cyan)"
        case .style5: return "Mark Style 5 (Orange)"
        }
    }

    /// Scintilla marker number (margin 2 mask).
    public var scintillaMarker: Int { 9 + rawValue }

    public var swiftUIColor: Color {
        switch self {
        case .style1: return .red
        case .style2: return .green
        case .style3: return .blue
        case .style4: return .cyan
        case .style5: return .orange
        }
    }
}

public struct LineMark: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var line: Int
    public var style: MarkStyle

    public init(id: UUID = UUID(), line: Int, style: MarkStyle = .style3) {
        self.id = id
        self.line = line
        self.style = style
    }
}
