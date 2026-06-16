# LexPad

Native macOS text editor inspired by Notepad++ — fast, regex-heavy, log-friendly.

**Repository:** [github.com/krunal039/LexPad](https://github.com/krunal039/LexPad)

Built with SwiftUI + **Scintilla/Lexilla** (160+ languages, code folding, column mode).

**Current release:** 0.3.0 — see [CHANGELOG.md](CHANGELOG.md) and [FEATURE_TRACKER.md](FEATURE_TRACKER.md) for parity status.

## Quick Start

```bash
cd "/path/to/Notepad++"
chmod +x scripts/*.sh
./scripts/bootstrap.sh          # First time: vendors + Scintilla + Lexilla
./scripts/run-lexpad.sh         # Dev launch
```

Requires **full Xcode** (not just Command Line Tools):

```bash
sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Documentation

| Doc | Description |
|-----|-------------|
| [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) | Quick start guide |
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | Full user guide |
| [docs/SHORTCUTS.md](docs/SHORTCUTS.md) | Keyboard shortcuts |
| [docs/LICENSES.md](docs/LICENSES.md) | Open source licenses |
| [docs/README.md](docs/README.md) | Documentation index |
| [CHANGELOG.md](CHANGELOG.md) | Release notes |
| [FEATURE_TRACKER.md](FEATURE_TRACKER.md) | N++ parity checklist |

In-app: **Help** menu → Getting Started, User Guide, About LexPad, Open Source Licenses.

## Ship a `.app` (distribution)

```bash
./scripts/build-app-bundle.sh release   # → dist/LexPad.app
open dist/LexPad.app
```

Builds a polished app icon, bundles Help docs, and produces a signed `.app` at version **0.3.0**.

### Notarization (for sharing outside your Mac)

```bash
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="TEAMID"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
./scripts/notarize-app.sh
```

### Homebrew (local cask)

```bash
./scripts/build-app-bundle.sh release
brew install --cask ./packaging/homebrew/lexpad.rb
```

## Features (0.3.0)

| Category | Features |
|----------|----------|
| **Editing** | Multi-tab, inline rename, overflow tab menu, undo/redo, word wrap, go-to-line |
| **Layout** | Resizable split panes, drag-tab-to-split, clone + sync scroll, vertical tab bar |
| **Panels** | Workspace, function list, document map, Git, snippets — all resizable |
| **Git** | Status, stage, commit, diff + blame |
| **Themes** | **30+ built-in themes** via Style Configurator |
| **Search** | Find/replace (literal + regex), find/replace in files, incremental search |
| **Power editing** | Column mode, multi-cursor, auto-completion, calltips, brace matching, smart highlight |
| **Tabs** | Pin, duplicate, read-only, file change monitoring |
| **Tools** | Compare files, JSON/XML formatters, macros (save/load), plugins, print, spell check |
| **Languages** | 160+ via Lexilla, UDL editor, encoding auto-detect |
| **Session** | Restore tabs/layout, crash recovery, cloud path prefs, large-file mode |
| **Shortcuts** | macOS default + **Notepad++ preset** in Preferences |

Open files from Terminal:

```bash
./scripts/run-lexpad.sh /path/to/file.txt
./scripts/run-lexpad.sh -n 42 -l swift src/main.swift
open -a LexPad /path/to/file.txt
```

## Keyboard Shortcuts (essentials)

| Shortcut | Action |
|----------|--------|
| `Cmd+T` | New tab |
| `Cmd+Shift+N` | New window |
| `Cmd+O` / `Cmd+P` | Open / Quick Open |
| `Cmd+S` / `Cmd+Shift+S` | Save / Save As |
| `Cmd+F` / `Cmd+Option+F` | Find / Replace |
| `Cmd+L` | Go to line |
| `Cmd+Shift+P` | Command palette |
| `Cmd+,` | Preferences |

Full list: [docs/SHORTCUTS.md](docs/SHORTCUTS.md)

## Releases

Tag a version to build and publish `LexPad.app` via GitHub Actions:

```bash
git tag v0.3.0
git push origin v0.3.0
```

The workflow at `.github/workflows/release.yml` runs bootstrap, builds `dist/LexPad.app`, and attaches a zip to the GitHub release.

## Development

```bash
cd LexPad
swift build --product LexPad
swift test
swift run -c release LexPadBenchmark 100
```

## Project Structure

```
├── LexPad/                 # Swift package (app + LexPadCore + ScintillaBridge)
├── docs/                   # User guide, shortcuts, architecture notes
├── Vendor/scintilla/       # Scintilla Cocoa framework
├── Vendor/lexilla/         # Lexilla lexers
├── scripts/
│   ├── bootstrap.sh
│   ├── run-lexpad.sh
│   ├── build-app-bundle.sh
│   ├── generate-app-icon.swift
│   └── notarize-app.sh
├── dist/LexPad.app         # Built app bundle (generated)
├── packaging/homebrew/     # Homebrew cask formula
└── PRODUCT_ROADMAP.md      # Full roadmap
```

## License

TBD — GPL-3.0 likely when linking Scintilla/Lexilla.
