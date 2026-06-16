import Foundation
import SwiftUI

public enum BuiltInEditorTheme: String, CaseIterable, Identifiable, Sendable {
    case classic
    case monokai
    case solarizedDark
    case solarizedLight
    case dracula
    case oneDark
    case githubLight
    case nord
    case gruvbox
    case cobalt
    case ayuDark
    case ayuLight
    case materialDark
    case materialLight
    case tomorrowNight
    case tomorrow
    case zenburn
    case atomOneLight
    case hopscotch
    case irBlack
    case lucario
    case palenight
    case railscasts
    case twilight
    case vibrantInk
    case blackboard
    case espresso
    case idleFingers
    case krTheme
    case merbivore

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .monokai: return "Monokai"
        case .solarizedDark: return "Solarized Dark"
        case .solarizedLight: return "Solarized Light"
        case .dracula: return "Dracula"
        case .oneDark: return "One Dark"
        case .githubLight: return "GitHub Light"
        case .nord: return "Nord"
        case .gruvbox: return "Gruvbox"
        case .cobalt: return "Cobalt"
        case .ayuDark: return "Ayu Dark"
        case .ayuLight: return "Ayu Light"
        case .materialDark: return "Material Dark"
        case .materialLight: return "Material Light"
        case .tomorrowNight: return "Tomorrow Night"
        case .tomorrow: return "Tomorrow"
        case .zenburn: return "Zenburn"
        case .atomOneLight: return "Atom One Light"
        case .hopscotch: return "Hopscotch"
        case .irBlack: return "IR Black"
        case .lucario: return "Lucario"
        case .palenight: return "Palenight"
        case .railscasts: return "Railscasts"
        case .twilight: return "Twilight"
        case .vibrantInk: return "Vibrant Ink"
        case .blackboard: return "Blackboard"
        case .espresso: return "Espresso"
        case .idleFingers: return "Idle Fingers"
        case .krTheme: return "Kr Theme"
        case .merbivore: return "Merbivore"
        }
    }

    public var isDark: Bool {
        AppChromeColors.isDarkBackground(EditorThemePalette.colors(for: self).background)
    }
}

public struct ThemeColors: Sendable {
    public var background: (r: Double, g: Double, b: Double)
    public var foreground: (r: Double, g: Double, b: Double)
    public var keyword: (r: Double, g: Double, b: Double)
    public var comment: (r: Double, g: Double, b: Double)
    public var string: (r: Double, g: Double, b: Double)
    public var number: (r: Double, g: Double, b: Double)
}

public enum EditorThemePalette {
    private static func c(_ bg: (Double, Double, Double), _ fg: (Double, Double, Double),
                          _ kw: (Double, Double, Double), _ cm: (Double, Double, Double),
                          _ st: (Double, Double, Double), _ nu: (Double, Double, Double)) -> ThemeColors {
        ThemeColors(background: bg, foreground: fg, keyword: kw, comment: cm, string: st, number: nu)
    }

    public static func colors(for theme: BuiltInEditorTheme) -> ThemeColors {
        if let extra = extended[theme] { return extra }
        switch theme {
        case .classic:
            return ThemeColors(
                background: (1, 1, 1), foreground: (0, 0, 0),
                keyword: (0.55, 0, 0.75), comment: (0, 0.53, 0),
                string: (0.77, 0.1, 0.09), number: (0.11, 0.21, 0.85)
            )
        case .monokai:
            return ThemeColors(
                background: (0.15, 0.16, 0.13), foreground: (0.97, 0.97, 0.95),
                keyword: (0.96, 0.26, 0.64), comment: (0.46, 0.49, 0.44),
                string: (0.9, 0.86, 0.45), number: (0.68, 0.51, 1)
            )
        case .solarizedDark:
            return ThemeColors(
                background: (0, 0.17, 0.21), foreground: (0.51, 0.58, 0.59),
                keyword: (0.15, 0.55, 0.82), comment: (0.4, 0.48, 0.51),
                string: (0.13, 0.55, 0.4), number: (0.86, 0.44, 0.34)
            )
        case .solarizedLight:
            return ThemeColors(
                background: (0.99, 0.96, 0.89), foreground: (0.4, 0.48, 0.51),
                keyword: (0.15, 0.55, 0.82), comment: (0.52, 0.6, 0.63),
                string: (0.13, 0.55, 0.4), number: (0.86, 0.44, 0.34)
            )
        case .dracula:
            return ThemeColors(
                background: (0.16, 0.17, 0.21), foreground: (0.97, 0.97, 0.95),
                keyword: (1, 0.47, 0.78), comment: (0.38, 0.47, 0.56),
                string: (0.95, 0.98, 0.55), number: (0.74, 0.58, 1)
            )
        case .oneDark:
            return ThemeColors(
                background: (0.17, 0.19, 0.23), foreground: (0.86, 0.89, 0.95),
                keyword: (0.78, 0.47, 0.95), comment: (0.38, 0.45, 0.56),
                string: (0.6, 0.86, 0.47), number: (0.85, 0.56, 0.31)
            )
        case .githubLight:
            return ThemeColors(
                background: (1, 1, 1), foreground: (0.14, 0.16, 0.18),
                keyword: (0.8, 0.14, 0.47), comment: (0.42, 0.47, 0.53),
                string: (0.03, 0.4, 0.14), number: (0.01, 0.39, 0.64)
            )
        case .nord:
            return ThemeColors(
                background: (0.18, 0.2, 0.25), foreground: (0.85, 0.87, 0.91),
                keyword: (0.52, 0.75, 0.9), comment: (0.4, 0.48, 0.58),
                string: (0.64, 0.75, 0.53), number: (0.9, 0.72, 0.58)
            )
        case .gruvbox:
            return ThemeColors(
                background: (0.16, 0.16, 0.14), foreground: (0.85, 0.82, 0.67),
                keyword: (0.98, 0.65, 0.38), comment: (0.46, 0.49, 0.44),
                string: (0.6, 0.75, 0.47), number: (0.85, 0.56, 0.31)
            )
        case .cobalt:
            return ThemeColors(
                background: (0, 0.17, 0.31), foreground: (1, 1, 1),
                keyword: (1, 1, 0.4), comment: (0, 0.53, 0),
                string: (1, 0.62, 0.11), number: (0.6, 0.86, 1)
            )
        default:
            return extended[theme] ?? ThemeColors(
                background: (1, 1, 1), foreground: (0, 0, 0),
                keyword: (0.55, 0, 0.75), comment: (0, 0.53, 0),
                string: (0.77, 0.1, 0.09), number: (0.11, 0.21, 0.85)
            )
        }
    }

    private static let extended: [BuiltInEditorTheme: ThemeColors] = [
        .ayuDark: c((0.06, 0.07, 0.09), (0.87, 0.89, 0.91), (0.95, 0.64, 0.45), (0.42, 0.47, 0.53), (0.6, 0.85, 0.47), (0.82, 0.6, 0.32)),
        .ayuLight: c((0.98, 0.98, 0.97), (0.36, 0.38, 0.4), (0.85, 0.37, 0.01), (0.55, 0.58, 0.62), (0.15, 0.55, 0.35), (0.11, 0.45, 0.85)),
        .materialDark: c((0.12, 0.13, 0.15), (0.88, 0.89, 0.91), (0.64, 0.78, 0.98), (0.42, 0.47, 0.53), (0.66, 0.84, 0.48), (0.98, 0.72, 0.45)),
        .materialLight: c((0.98, 0.98, 0.98), (0.2, 0.22, 0.25), (0.2, 0.45, 0.85), (0.5, 0.55, 0.6), (0.15, 0.55, 0.35), (0.85, 0.35, 0.1)),
        .tomorrowNight: c((0.13, 0.14, 0.16), (0.78, 0.8, 0.84), (0.69, 0.51, 0.85), (0.52, 0.55, 0.6), (0.6, 0.85, 0.47), (0.98, 0.72, 0.45)),
        .tomorrow: c((1, 1, 1), (0.25, 0.27, 0.3), (0.2, 0.45, 0.85), (0.55, 0.58, 0.62), (0.15, 0.55, 0.35), (0.85, 0.35, 0.1)),
        .zenburn: c((0.24, 0.27, 0.25), (0.82, 0.84, 0.8), (0.7, 0.75, 0.55), (0.5, 0.58, 0.52), (0.55, 0.72, 0.55), (0.85, 0.65, 0.45)),
        .atomOneLight: c((0.98, 0.98, 0.98), (0.23, 0.27, 0.31), (0.52, 0.36, 0.82), (0.55, 0.6, 0.65), (0.15, 0.55, 0.35), (0.85, 0.35, 0.1)),
        .hopscotch: c((0.16, 0.14, 0.15), (0.92, 0.9, 0.88), (0.98, 0.43, 0.42), (0.55, 0.52, 0.5), (0.6, 0.85, 0.47), (0.98, 0.72, 0.45)),
        .irBlack: c((0.1, 0.1, 0.1), (0.9, 0.9, 0.9), (0.67, 0.39, 0.98), (0.42, 0.47, 0.53), (0.98, 0.43, 0.42), (0.82, 0.6, 0.32)),
        .lucario: c((0.16, 0.19, 0.22), (0.94, 0.96, 0.98), (0.67, 0.39, 0.98), (0.42, 0.47, 0.53), (0.98, 0.43, 0.42), (0.82, 0.6, 0.32)),
        .palenight: c((0.16, 0.17, 0.21), (0.86, 0.89, 0.95), (0.67, 0.39, 0.98), (0.42, 0.47, 0.53), (0.6, 0.86, 0.47), (0.98, 0.72, 0.45)),
        .railscasts: c((0.11, 0.12, 0.14), (0.9, 0.9, 0.88), (0.98, 0.72, 0.45), (0.42, 0.47, 0.53), (0.6, 0.85, 0.47), (0.82, 0.6, 0.32)),
        .twilight: c((0.1, 0.1, 0.1), (0.9, 0.9, 0.88), (0.67, 0.39, 0.98), (0.42, 0.47, 0.53), (0.98, 0.43, 0.42), (0.82, 0.6, 0.32)),
        .vibrantInk: c((0, 0, 0), (1, 1, 1), (1, 1, 0.4), (0, 0.53, 0), (1, 0.62, 0.11), (0.6, 0.86, 1)),
        .blackboard: c((0.08, 0.12, 0.08), (0.85, 0.9, 0.85), (0.7, 0.9, 0.7), (0.45, 0.55, 0.45), (0.9, 0.85, 0.6), (0.85, 0.65, 0.45)),
        .espresso: c((0.2, 0.18, 0.16), (0.9, 0.88, 0.85), (0.85, 0.55, 0.35), (0.55, 0.52, 0.48), (0.6, 0.75, 0.5), (0.85, 0.65, 0.45)),
        .idleFingers: c((0.13, 0.12, 0.11), (0.9, 0.88, 0.85), (0.98, 0.72, 0.45), (0.5, 0.52, 0.5), (0.6, 0.85, 0.47), (0.82, 0.6, 0.32)),
        .krTheme: c((0.12, 0.12, 0.14), (0.88, 0.9, 0.92), (0.67, 0.39, 0.98), (0.42, 0.47, 0.53), (0.98, 0.43, 0.42), (0.82, 0.6, 0.32)),
        .merbivore: c((0.16, 0.14, 0.15), (0.92, 0.9, 0.88), (0.98, 0.72, 0.45), (0.42, 0.47, 0.53), (0.6, 0.85, 0.47), (0.98, 0.43, 0.42)),
    ]
}
