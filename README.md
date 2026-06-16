# LexPad

Native macOS text editor inspired by Notepad++ — fast, regex-heavy, log-friendly.

**Phase 0 status:** Foundation spike in progress. App shell runs with AppKit text view; Scintilla/Lexilla integration next.

## Quick Start

### Prerequisites

- macOS 13+
- Swift 6.x (included with Xcode or Command Line Tools)
- **Full Xcode** (required to build Scintilla Cocoa framework)

### Bootstrap

```bash
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

### Run the app

```bash
cd LexPad
swift run LexPad
```

### Run tests (includes large-file regex benchmark)

```bash
cd LexPad
swift test
```

### Large-file spike

```bash
./scripts/spike-large-file.sh 100
```

## Project Structure

```
├── PRODUCT_ROADMAP.md      # Full product analysis & roadmap
├── docs/
│   ├── ADR-001-architecture.md
│   ├── MVP_SCOPE.md
│   └── NAMING.md
├── LexPad/                 # Swift package (app + core)
├── Vendor/
│   ├── scintilla/          # Upstream Scintilla
│   └── lexilla/            # Upstream Lexilla (built → bin/liblexilla.dylib)
├── scripts/
│   ├── bootstrap.sh
│   └── spike-large-file.sh
└── fixtures/               # Generated test logs (gitignored)
```

## Phase 0 Exit Criteria

| Criterion | Status |
|-----------|--------|
| Lexilla builds on macOS | ✅ |
| Tab shell + regex find UI | ✅ |
| Large-file regex find <2s | ✅ (unit test) |
| Scintilla Cocoa framework | ⏳ Needs Xcode |

## Next Steps

1. Install Xcode and run `./scripts/bootstrap.sh` to build Scintilla
2. Wire `LPScintillaEditorView` to real `ScintillaView` + Lexilla
3. Begin Phase 1 MVP per `docs/MVP_SCOPE.md`

## License

TBD — GPL-3.0 likely when linking Scintilla/Lexilla statically.
