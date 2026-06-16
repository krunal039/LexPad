import Foundation

/// UI chrome colors derived from the active editor theme palette.
public struct AppChromeColors: Sendable {
    public let editor: ThemeColors
    /// Whether chrome (sidebars, toolbars, sheets) uses a dark palette.
    public let isDark: Bool
    public let windowBackground: (r: Double, g: Double, b: Double)
    public let panelBackground: (r: Double, g: Double, b: Double)
    public let toolbarBackground: (r: Double, g: Double, b: Double)
    public let separator: (r: Double, g: Double, b: Double)
    public let primaryText: (r: Double, g: Double, b: Double)
    public let secondaryText: (r: Double, g: Double, b: Double)
    public let accent: (r: Double, g: Double, b: Double)

    public init(theme: BuiltInEditorTheme, appearance: EditorTheme) {
        let editor = EditorThemePalette.colors(for: theme)
        let editorIsDark = Self.isDarkBackground(editor.background)
        let chromeIsDark: Bool = switch appearance {
        case .system: editorIsDark
        case .light: false
        case .dark: true
        }

        self.editor = editor
        self.isDark = chromeIsDark

        if chromeIsDark == editorIsDark {
            windowBackground = editor.background
            if editorIsDark {
                panelBackground = Self.adjust(editor.background, by: 0.10, lighter: false)
                toolbarBackground = Self.adjust(editor.background, by: 0.16, lighter: false)
            } else {
                panelBackground = Self.adjust(editor.background, by: 0.05, lighter: true)
                toolbarBackground = Self.adjust(editor.background, by: 0.10, lighter: true)
            }
        } else if chromeIsDark {
            windowBackground = (0.13, 0.13, 0.14)
            panelBackground = (0.16, 0.16, 0.17)
            toolbarBackground = (0.20, 0.20, 0.21)
        } else {
            windowBackground = (0.97, 0.97, 0.98)
            panelBackground = (0.94, 0.94, 0.95)
            toolbarBackground = (0.89, 0.89, 0.91)
        }

        separator = Self.mix(
            panelBackground,
            chromeIsDark ? (1, 1, 1) : (0, 0, 0),
            amount: 0.14
        )
        primaryText = chromeIsDark ? (0.93, 0.93, 0.95) : (0.11, 0.11, 0.13)
        secondaryText = Self.mix(primaryText, panelBackground, amount: 0.42)
        accent = editor.keyword
    }

    public static func isDarkBackground(_ color: (r: Double, g: Double, b: Double)) -> Bool {
        relativeLuminance(color) < 0.5
    }

    public static func relativeLuminance(_ color: (r: Double, g: Double, b: Double)) -> Double {
        0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
    }

    private static func mix(
        _ left: (r: Double, g: Double, b: Double),
        _ right: (r: Double, g: Double, b: Double),
        amount: Double
    ) -> (r: Double, g: Double, b: Double) {
        let t = min(max(amount, 0), 1)
        return (
            left.r + (right.r - left.r) * t,
            left.g + (right.g - left.g) * t,
            left.b + (right.b - left.b) * t
        )
    }

    private static func adjust(
        _ color: (r: Double, g: Double, b: Double),
        by amount: Double,
        lighter: Bool
    ) -> (r: Double, g: Double, b: Double) {
        let target: (r: Double, g: Double, b: Double) = lighter ? (1, 1, 1) : (0, 0, 0)
        return mix(color, target, amount: amount)
    }
}
