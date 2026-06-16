# Phase 0 Spike Results

**Date:** 2026-06-15  
**Project:** LexPad

## Summary

Phase 0 foundation is in place. The Swift app shell runs; Lexilla builds; Scintilla awaits full Xcode.

## Completed

| Item | Result |
|------|--------|
| Project named **LexPad** | ✅ |
| Architecture ADR | ✅ `docs/ADR-001-architecture.md` |
| MVP scope locked | ✅ `docs/MVP_SCOPE.md` |
| Lexilla build (macOS ARM64) | ✅ `Vendor/lexilla/bin/liblexilla.{a,dylib}` |
| Swift tab shell + find bar | ✅ `swift run LexPad` |
| Regex/literal find engine | ✅ `LexPadCore/FindEngine.swift` |
| Large-file benchmark CLI | ✅ `swift run LexPadBenchmark 100` |
| Scintilla bridge stub | ✅ `ScintillaBridge/LPScintillaEditorView` |
| Git repo initialized | ✅ |

## Benchmark (100 MB log, `/tmp`)

Run: `cd LexPad && swift run -c release LexPadBenchmark 100`

| Metric | Target | Result |
|--------|--------|--------|
| Mmap load | <1s | ~0.001s ✅ |
| UTF-8 decode | — | ~0.04s |
| Find (1.3M lines, literal) | <2s | ~1.8s ✅ |

> Full regex on 1.3M lines is ~2s with line-wise engine. Scintilla native search expected to improve in-editor find further.

## Blocked / Next

| Item | Blocker |
|------|---------|
| Scintilla Cocoa framework | Requires **full Xcode** (`xcodebuild`) |
| XCTest suite | Requires Xcode test runtime |
| Syntax highlighting in editor | Scintilla + Lexilla integration |

## Commands

```bash
./scripts/bootstrap.sh          # Clone vendors + build Lexilla
cd LexPad && swift run LexPad   # Launch app
swift run -c release LexPadBenchmark 100  # Performance spike
```

## Recommendation

Proceed to **Phase 1 MVP** after:

1. Install Xcode from App Store
2. Run `./scripts/bootstrap.sh` to build Scintilla framework
3. Replace `NSTextView` with `ScintillaView` in `TextEditorView.swift`
4. Wire Lexilla `CreateLexer("cpp")` etc.
