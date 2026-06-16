import LexPadCore
import SwiftUI

struct EditorSheetsModifier: ViewModifier {
    @Binding var showGoToLine: Bool
    @Binding var showFindInFiles: Bool
    @Binding var showReplaceInFiles: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showQuickOpen: Bool
    @Binding var showMacros: Bool
    @Binding var showDiff: Bool
    @ObservedObject var collection: DocumentCollection
    @ObservedObject var macroRecorder: MacroRecorder
    @ObservedObject var settings: EditorSettings
    @Binding var findPattern: String
    @Binding var replacePattern: String
    @Binding var findRegex: Bool
    @Binding var findMatchCase: Bool
    @Binding var fifDirectory: URL?
    @Binding var fifFilter: String
    @Binding var fifResults: [FindInFilesResult]
    @Binding var fifSearching: Bool
    @Binding var rifStatus: String
    var diffLeftTitle: String
    var diffRightTitle: String
    var diffLines: [DiffLine]
    var onGoToLine: (Int) -> Void
    var onOpenFindResult: (FindInFilesResult) -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showGoToLine) {
                GoToLineSheet(isPresented: $showGoToLine, maxLine: collection.activeDocument?.lineCount ?? 1, onGo: onGoToLine)
                    .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showFindInFiles) {
                FindInFilesPanel(
                    isPresented: $showFindInFiles,
                    pattern: $findPattern,
                    isRegex: $findRegex,
                    matchCase: $findMatchCase,
                    directory: $fifDirectory,
                    fileFilter: $fifFilter,
                    results: $fifResults,
                    isSearching: $fifSearching,
                    onOpenResult: onOpenFindResult
                )
                .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showReplaceInFiles) {
                ReplaceInFilesPanel(
                    isPresented: $showReplaceInFiles,
                    pattern: $findPattern,
                    replacement: $replacePattern,
                    isRegex: $findRegex,
                    matchCase: $findMatchCase,
                    directory: $fifDirectory,
                    fileFilter: $fifFilter,
                    status: $rifStatus,
                    isSearching: $fifSearching
                )
                .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showCommandPalette) {
                CommandPaletteView(isPresented: $showCommandPalette)
                    .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showQuickOpen) {
                QuickOpenView(collection: collection, isPresented: $showQuickOpen)
                    .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showMacros) {
                MacroPanelView(isPresented: $showMacros, recorder: macroRecorder)
                    .lexPadTheme(settings: settings)
            }
            .sheet(isPresented: $showDiff) {
                DiffCompareView(leftTitle: diffLeftTitle, rightTitle: diffRightTitle, diffLines: diffLines)
                    .lexPadTheme(settings: settings)
            }
    }
}
