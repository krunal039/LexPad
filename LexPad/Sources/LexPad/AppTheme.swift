import LexPadCore
import SwiftUI

struct AppTheme {
    let chrome: AppChromeColors

    init(builtInTheme: BuiltInEditorTheme, appearance: EditorTheme) {
        chrome = AppChromeColors(theme: builtInTheme, appearance: appearance)
    }

    init(builtIn theme: BuiltInEditorTheme) {
        chrome = AppChromeColors(theme: theme, appearance: .system)
    }

    var editorBackground: Color { Self.color(chrome.editor.background) }
    var editorForeground: Color { Self.color(chrome.editor.foreground) }
    var windowBackground: Color { Self.color(chrome.windowBackground) }
    var panelBackground: Color { Self.color(chrome.panelBackground) }
    var toolbarBackground: Color { Self.color(chrome.toolbarBackground) }
    var separator: Color { Self.color(chrome.separator) }
    var primaryText: Color { Self.color(chrome.primaryText) }
    var secondaryText: Color { Self.color(chrome.secondaryText) }
    var accent: Color { Self.color(chrome.accent) }

    func activeTabBackground(opacity: Double = 0.22) -> Color {
        accent.opacity(opacity)
    }

    private static func color(_ rgb: (r: Double, g: Double, b: Double)) -> Color {
        Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme(builtIn: .classic)
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

private struct LexPadThemeModifier: ViewModifier {
    let builtInTheme: BuiltInEditorTheme
    let appearance: EditorTheme
    let colorScheme: ColorScheme?

    func body(content: Content) -> some View {
        let theme = AppTheme(builtInTheme: builtInTheme, appearance: appearance)
        content
            .environment(\.appTheme, theme)
            .preferredColorScheme(colorScheme)
            .tint(theme.accent)
    }
}

extension View {
    func lexPadTheme(settings: EditorSettings) -> some View {
        modifier(LexPadThemeModifier(
            builtInTheme: settings.builtInTheme,
            appearance: settings.theme,
            colorScheme: settings.resolvedColorScheme
        ))
    }

    func lexPadWindowBackground() -> some View {
        modifier(LexPadWindowBackgroundModifier())
    }

    func lexPadToolbarBackground() -> some View {
        modifier(LexPadToolbarBackgroundModifier())
    }

    func lexPadPanelBackground() -> some View {
        modifier(LexPadPanelBackgroundModifier())
    }

    func lexPadThemedForm() -> some View {
        modifier(LexPadThemedFormModifier())
    }

    func lexPadSheetContainer() -> some View {
        modifier(LexPadSheetContainerModifier())
    }

    func lexPadThemedList() -> some View {
        modifier(LexPadThemedListModifier())
    }
}

private struct LexPadWindowBackgroundModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content.background(theme.windowBackground)
    }
}

private struct LexPadToolbarBackgroundModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.toolbarBackground)
            .overlay(alignment: .bottom) {
                theme.separator.frame(height: 1)
            }
    }
}

private struct LexPadPanelBackgroundModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content.background(theme.panelBackground)
    }
}

private struct LexPadThemedFormModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(theme.panelBackground)
    }
}

private struct LexPadSheetContainerModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content.background(theme.panelBackground)
    }
}

private struct LexPadThemedListModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(theme.panelBackground)
    }
}
