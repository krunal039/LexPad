import Foundation

public struct AppCommand: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let category: String
    public let notificationName: Notification.Name
    public let shortcut: String?

    public init(id: String, title: String, category: String, notificationName: Notification.Name, shortcut: String? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.notificationName = notificationName
        self.shortcut = shortcut
    }
}

public enum AppCommands {
    public static let all: [AppCommand] = [
        AppCommand(id: "find", title: "Find", category: "Search", notificationName: .lexPadToggleFind, shortcut: "⌘F"),
        AppCommand(id: "replace", title: "Replace", category: "Search", notificationName: .lexPadToggleReplace, shortcut: "⌘⌥F"),
        AppCommand(id: "findInFiles", title: "Find in Files", category: "Search", notificationName: .lexPadFindInFiles, shortcut: "⌘⇧F"),
        AppCommand(id: "gotoLine", title: "Go to Line", category: "Navigation", notificationName: .lexPadGoToLine, shortcut: "⌘L"),
        AppCommand(id: "quickOpen", title: "Quick Open", category: "Navigation", notificationName: .lexPadQuickOpen, shortcut: "⌘P"),
        AppCommand(id: "compare", title: "Compare Files", category: "Tools", notificationName: .lexPadCompareFiles),
        AppCommand(id: "foldAll", title: "Fold All", category: "View", notificationName: .lexPadFoldAll),
        AppCommand(id: "unfoldAll", title: "Unfold All", category: "View", notificationName: .lexPadUnfoldAll),
        AppCommand(id: "dupLine", title: "Duplicate Line", category: "Edit", notificationName: .lexPadDuplicateLine),
        AppCommand(id: "sortAsc", title: "Sort Lines Ascending", category: "Edit", notificationName: .lexPadSortLinesAsc),
        AppCommand(id: "sortDesc", title: "Sort Lines Descending", category: "Edit", notificationName: .lexPadSortLinesDesc),
        AppCommand(id: "removeDupes", title: "Remove Duplicate Lines", category: "Edit", notificationName: .lexPadRemoveDupLines),
        AppCommand(id: "trimTrailing", title: "Trim Trailing Whitespace", category: "Edit", notificationName: .lexPadTrimTrailing),
        AppCommand(id: "trimLeading", title: "Trim Leading Whitespace", category: "Edit", notificationName: .lexPadTrimLeading),
        AppCommand(id: "removeEmpty", title: "Remove Empty Lines", category: "Edit", notificationName: .lexPadRemoveEmptyLines),
        AppCommand(id: "joinLines", title: "Join Lines", category: "Edit", notificationName: .lexPadJoinLines),
        AppCommand(id: "reverseLines", title: "Reverse Lines", category: "Edit", notificationName: .lexPadReverseLines),
        AppCommand(id: "moveLineUp", title: "Move Line Up", category: "Edit", notificationName: .lexPadMoveLineUp),
        AppCommand(id: "moveLineDown", title: "Move Line Down", category: "Edit", notificationName: .lexPadMoveLineDown),
        AppCommand(id: "upper", title: "Convert to UPPERCASE", category: "Edit", notificationName: .lexPadUpperCase),
        AppCommand(id: "lower", title: "Convert to lowercase", category: "Edit", notificationName: .lexPadLowerCase),
        AppCommand(id: "proper", title: "Convert to Proper Case", category: "Edit", notificationName: .lexPadProperCase),
        AppCommand(id: "invertCase", title: "Invert Case", category: "Edit", notificationName: .lexPadInvertCase),
        AppCommand(id: "tabsToSpaces", title: "Tabs to Spaces", category: "Edit", notificationName: .lexPadTabsToSpaces),
        AppCommand(id: "spacesToTabs", title: "Spaces to Tabs", category: "Edit", notificationName: .lexPadSpacesToTabs),
        AppCommand(id: "eolLF", title: "Convert EOL to Unix (LF)", category: "Edit", notificationName: .lexPadConvertEOLToLF),
        AppCommand(id: "eolCRLF", title: "Convert EOL to Windows (CR LF)", category: "Edit", notificationName: .lexPadConvertEOLToCRLF),
        AppCommand(id: "eolCR", title: "Convert EOL to Macintosh (CR)", category: "Edit", notificationName: .lexPadConvertEOLToCR),
        AppCommand(id: "prefs", title: "Settings", category: "LexPad", notificationName: .lexPadShowPreferences, shortcut: "⌘,"),
        AppCommand(id: "palette", title: "Command Palette", category: "LexPad", notificationName: .lexPadCommandPalette, shortcut: "⌘⇧P"),
        AppCommand(id: "selectNext", title: "Add Next Occurrence", category: "Edit", notificationName: .lexPadSelectNextOccurrence, shortcut: "⌘⌃D"),
        AppCommand(id: "snippets", title: "Snippets Panel", category: "Tools", notificationName: .lexPadToggleSnippets),
        AppCommand(id: "incremental", title: "Incremental Search", category: "Search", notificationName: .lexPadIncrementalSearch, shortcut: "⌘E"),
        AppCommand(id: "gitPanel", title: "Git Panel", category: "View", notificationName: .lexPadToggleGitPanel),
        AppCommand(id: "completion", title: "Show Completions", category: "Edit", notificationName: .lexPadTriggerCompletion, shortcut: "⌃Space"),
        AppCommand(id: "udlEditor", title: "User Defined Languages", category: "Tools", notificationName: .lexPadOpenUDLEditor),
    ]

    public static func filter(_ query: String) -> [AppCommand] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.title.lowercased().contains(q) || $0.category.lowercased().contains(q)
        }
    }
}
