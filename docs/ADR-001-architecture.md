# ADR-001: Native Swift + Scintilla/Lexilla Architecture

**Status:** Accepted  
**Date:** 2026-06-15  
**Context:** Phase 0 foundation for a Notepad++-class macOS editor.

## Decision

Build **LexPad** as a native macOS application using:

| Layer | Technology |
|-------|------------|
| UI shell | Swift, SwiftUI + AppKit (`NSViewRepresentable`) |
| Text engine | Scintilla (Cocoa `ScintillaView`) |
| Syntax lexers | Lexilla (same engine as Notepad++) |
| Regex search | Scintilla built-in + ICU/NSRegularExpression for find-in-files |
| Plugins (future) | Swift Package plugins or XPC helpers — **not** Win32 DLLs |

## Rationale

1. **Scintilla/Lexilla parity** — Notepad++ uses this stack; 80+ language definitions are reusable.
2. **Native macOS** — AppKit integration, sandbox, notarization, system appearance.
3. **Rejected: Electron/Tauri** — Memory footprint and non-native feel conflict with product goals.
4. **Rejected: Pure NSTextView** — Insufficient for column mode, folding, and N++-grade regex/mark APIs long-term (acceptable for Phase 0 shell only).
5. **Rejected: Win32 port** — Notepad++ codebase is deeply Win32-coupled; port cost exceeds clean rewrite.

## Consequences

- Requires **Xcode** (not CLT alone) to build Scintilla Cocoa framework.
- ObjC++ bridge layer (`ScintillaBridge`) isolates C++ headers from Swift.
- GPL-3.0 consideration if statically linking Scintilla; evaluate license with legal review before App Store.

## Phase 0 Validation

| Spike | Target | Status |
|-------|--------|--------|
| Lexilla `make` on macOS ARM64 | Static + dynamic libs in `Vendor/lexilla/bin/` | ✅ Done |
| Scintilla Cocoa `xcodebuild` | Framework builds | ⏳ Requires full Xcode |
| Swift tab shell + regex find | Runnable app | In progress |
| 100 MB file open + find | <3s open, <2s find | Script provided |

## References

- [Scintilla Cocoa README](https://github.com/jrsoftware/scintilla)
- [Lexilla Documentation](https://scintilla.org/LexillaDoc.html)
- [Scintilla 5 Migration](https://www.scintilla.org/Scintilla5Migration.html)
