# LexPad Feature Tracker — N++ Parity (Tiers 1–3)

> Living checklist for Tier 1–3 parity work. Update status as features ship.

**Legend:** ✅ Done · 🔶 Partial · ⬜ Not started

| # | Feature | Tier | Status | Key files |
|---|---------|------|--------|-----------|
| 1 | File change monitoring | 1 | ✅ | `FileChangeMonitor.swift`, `LexPadApp.swift` |
| 2 | Duplicate tab | 1 | ✅ | `DocumentCollection.swift`, `EditorViews.swift` |
| 3 | Shortcut mapper | 1 | ✅ | `ShortcutSettings.swift`, `ShortcutMapperView` |
| 4 | Function parameter calltips | 1 | ✅ | `CalltipEngine.swift`, `LPScintillaEditorView.mm` |
| 5 | Brace / tag matching | 1 | ✅ | `LPScintillaEditorView.mm`, `ScintillaTextEditorView.swift` |
| 6 | Multiple windows | 1 | ✅ | `WindowFocusRegistry.swift`, `EditorWindowRoot`, `LexPadApp.swift` |
| 7 | Drag tab to split | 2 | ✅ | `EditorViews.swift`, `EditorMainStack.swift` |
| 8 | Vertical / multi-line tab bar | 2 | ✅ | `EditorSettings.swift`, `EditorViews.swift` |
| 9 | Encoding auto-detect | 2 | ✅ | `EncodingDetector.swift`, `DocumentStore` |
| 10 | Read-only mode | 2 | ✅ | `TextDocument.swift`, editor bridge |
| 11 | Macro library (rename/export) | 2 | ✅ | `MacroRecorder.swift`, `FeaturePanels.swift` |
| 12 | Loadable plugin commands | 2 | ✅ | `PluginAPI.swift`, `LexPadApp.swift` |
| 13 | Spell check | 2 | ✅ | `SpellCheckEngine.swift`, Scintilla indicators |
| 14 | Print with line numbers | 2 | ✅ | `PrintAndCharacterSupport.swift` |
| 15 | JSON / XML formatters | 3 | ✅ | `PluginAPI.swift`, Tools menu |
| 16 | Cloud / session path prefs | 3 | ✅ | `EditorSettings.swift`, `PreferencesView.swift` |
| 17 | Large-file threshold wiring | 3 | ✅ | `LargeFilePolicy.swift`, `DocumentStore` |
| 18 | Tab pinning | 3 | ✅ | `TextDocument.swift`, `TabStripView` |
| 19 | Smart highlight | 3 | ✅ | `SmartHighlightEngine.swift`, Scintilla bridge |
| 20 | 30+ built-in themes | 3 | ✅ | `EditorThemePalette.swift` |

## Verification

```bash
cd LexPad && swift test && swift build --product LexPad
./scripts/run-lexpad.sh
```

## Notes

- **Multiple windows:** each window owns its own `DocumentCollection`; `WindowFocusRegistry` routes menu commands to the key window.
- **Plugins:** bundled Swift plugins + manifest scan; Tools menu runs enabled plugin commands.
- **Large files:** threshold from Preferences; load still materializes `String` (mmap used for initial read).
