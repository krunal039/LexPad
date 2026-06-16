# LexPad User Guide

LexPad is a native macOS text editor inspired by Notepad++. It combines a familiar tabbed editing workflow with Scintilla-powered syntax highlighting, folding, and search.

## Getting started

### Launch

- **Development:** `./scripts/run-lexpad.sh`
- **App bundle:** build with `./scripts/build-app-bundle.sh release`, then open `dist/LexPad.app`
- **Terminal:** `LexPad path/to/file.txt` or `open -a LexPad path/to/file.txt`

### Open files

- **File → Open…** (`Cmd+O`) — pick one or more files
- **Quick Open** (`Cmd+P`) — fuzzy search open tabs and recent files
- **Drag and drop** files onto the editor window
- **Open Recent** — under the File menu

### Save

- **Save** (`Cmd+S`) — writes to the file path if known
- **Save As…** (`Cmd+Shift+S`) — choose a new location
- Unsaved tabs show a dot in the tab title; LexPad prompts before closing dirty tabs

## Tabs

LexPad uses a multi-tab interface similar to Notepad++.

| Action | How |
|--------|-----|
| New tab | `Cmd+T`, **+** button, or double-click empty tab bar area |
| Close tab | Click **×** on the tab |
| Rename tab | Double-click tab title, or right-click → **Rename Tab** |
| See all open tabs | Click **▼** at the right of the tab bar |
| Duplicate tab | **View → Duplicate Tab** |
| Pin tab | **View → Pin Tab** — pinned tabs stay at the front |
| Reorder tabs | Drag tabs left/right |

Tab titles truncate long filenames. The overflow menu lists every open document with a checkmark on the active tab.

## Split view and panes

Split the editor to work on two documents side by side.

| Action | Menu |
|--------|------|
| Split horizontal | **View → Split Horizontal** |
| Split vertical | **View → Split Vertical** |
| Clone document | **View → Clone Document** — same file in both panes |
| Sync scroll | **View → Sync Scroll** — lock vertical scroll between panes |
| Close split | **View → Close Split** |
| Move to other pane | **View → Move to Other View** |

**Resize splits:** drag the divider between panes or side panels. All dock panels (workspace, function list, document map, Git, etc.) have draggable edges.

**Drag tab to split:** drag a tab toward the left, right, top, or bottom edge of the editor to dock it in a new split.

## Side panels

Toggle panels from the **View** menu. Each panel can be resized by dragging its inner edge.

| Panel | Purpose |
|-------|---------|
| Workspace | Folder tree — open a folder as a project root |
| Function List | Jump to functions/classes in the active file |
| Document Map | Minimap of the active file |
| Document List | List of all open tabs |
| Git Panel | Status, stage, commit, diff, blame |
| Snippets | Insert saved code templates |
| Character Panel | Insert special characters |
| Hex View | Hex dump of the file |
| Project Panel | Saved project files |
| Recent Files | Quick access to recently opened paths |

## Search and replace

| Feature | Shortcut |
|---------|----------|
| Find | `Cmd+F` |
| Replace | `Cmd+Option+F` |
| Find in Files | `Cmd+Shift+F` |
| Replace in Files | `Cmd+Shift+R` |
| Go to Line | `Cmd+L` |
| Incremental Search | `Cmd+E` |
| Command Palette | `Cmd+Shift+P` |

Find supports **literal**, **regex**, **match case**, **whole word**, and **extended** search modes. Use **Bookmark All Matches** from the find bar to mark every result line in the gutter.

## Editing power features

- **Multi-cursor:** `Cmd+Click` to add cursors; **Add Next Occurrence** (`Cmd+Ctrl+D`)
- **Column mode:** **Tools → Column Editor…** or `Option+drag` for column selection
- **Auto-completion:** `Ctrl+Space` — language-aware suggestions and calltips
- **Comment/uncomment:** `Cmd+/` (line) or **Toggle Block Comment** in Edit menu
- **Bookmarks:** `F2` toggle; navigate with Next/Previous Bookmark
- **Mark styles:** five gutter mark styles from the Edit menu
- **Brace matching:** highlights matching brackets/tags (Scintilla)
- **Smart highlight:** highlights other occurrences of the word under the caret
- **Overwrite mode:** toggle from View menu
- **Read-only mode:** **View → Read Only** for the active tab

## Line operations

**Edit** menu provides sort, dedupe, join, reverse, trim, case conversion, tabs↔spaces, and end-of-line conversion (LF / CRLF / CR).

## Languages and themes

- **160+ languages** via Lexilla — auto-detected from file extension
- Set language manually: **View → Language**
- **User Defined Languages (UDL):** **Tools → User Defined Languages…**
- **30+ built-in color themes:** **View → Appearance → Style Configurator…**
- App chrome follows **Preferences → Appearance** (system / light / dark)

## Tools

| Tool | Location |
|------|----------|
| Compare Files | **Tools → Compare Files…** |
| Format JSON / XML | **Tools** menu |
| Macro record/play | **Tools** menu; save/load macro libraries in Preferences |
| Plugin Manager | **Tools → Plugin Manager…** or **Settings → Plugins** |
| Print | **File → Print…** |
| Spell check | Enabled per language in Preferences |

## Settings

Open **Settings** (`Cmd+,`) from the **LexPad** menu. On older Mac apps this was called Preferences — it is the same window with a sidebar for Editor, Appearance, Shortcuts, Languages, and Plugins.

Configure:

- Font, tab size, word wrap, line numbers, folding
- Session restore — reopen tabs and layout on launch
- Crash recovery snapshot
- Cloud/session path preferences
- Large-file mode threshold
- Keyboard shortcut preset (macOS default or Notepad++ compatible)
- Custom shortcut mapping

**Settings → Plugins** has step-by-step instructions for installing script plugins. See [PLUGINS.md](PLUGINS.md) for full details.

**File change monitoring:** if an open file changes on disk, LexPad prompts to reload.

## Multiple windows

**File → New Window** (`Cmd+Shift+N`) opens a separate LexPad window with its own tab set.

## Command line

```bash
LexPad [options] [file...]

  -n <line>       Jump to line after opening
  -l <language>   Set syntax (e.g. swift, python, json)
  -h, --help      Show help
```

## Getting help

- **Help → Getting Started Guide** — five-minute quick start
- **Help → User Guide** — full reference
- **Help → Keyboard Shortcuts** — shortcut reference
- **Help → What's New** — release notes
- **Help → About LexPad** — version, developer, copyright
- **Help → Open Source Licenses** — Scintilla, Lexilla, and attributions
- **Help → View Documentation on GitHub** — online docs
- **Help → Report an Issue** — GitHub issue tracker

Repository: [github.com/krunal039/LexPad](https://github.com/krunal039/LexPad)
