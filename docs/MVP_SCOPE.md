# MVP Scope (Phase 1) — Locked for Implementation

**Project:** LexPad  
**Target:** Months 2–4 after Phase 0 completion

## In Scope (P0)

### Editing
- [ ] Multi-document tabs (new, close, reorder, dirty indicator)
- [ ] Open / Save / Save As / Recent files
- [ ] Drag-and-drop file open
- [ ] Undo / redo
- [ ] Line numbers
- [ ] Word wrap toggle
- [ ] Go to line
- [ ] **Column / rectangular selection**
- [ ] **Multi-cursor editing**
- [ ] Status bar: line, column, encoding, EOL, language

### Search
- [ ] Find / Replace panel (literal + regex)
- [ ] Find next / previous in document
- [ ] Highlight all matches
- [ ] Match count

### Languages
- [ ] Syntax highlighting — top 20 languages (Lexilla)
- [ ] Code folding
- [ ] Language detection by file extension
- [ ] Dark / light theme (follow system)

### Line & Text Operations
- [ ] Duplicate line
- [ ] Sort lines (asc/desc, case sensitive/insensitive)
- [ ] Remove duplicate / consecutive duplicate lines
- [ ] Join lines / split lines
- [ ] Trim leading/trailing whitespace
- [ ] Tab ↔ space conversion
- [ ] EOL conversion (LF / CRLF / CR)
- [ ] Case conversion (upper, lower, proper)

### Encoding
- [ ] UTF-8 default
- [ ] Encoding detection on open
- [ ] Reopen with encoding / convert encoding

### Platform
- [ ] macOS 13+ Universal Binary
- [ ] Autosave + document restoration
- [ ] Standard macOS menus and shortcuts

## Explicitly Out of Scope (Deferred to v1.0+)

- Find in Files
- Macros
- Session management
- Compare / diff
- User Defined Languages GUI
- Plugin system
- Split view
- Bookmarks / document map
- Function list
- Print

## Phase 0 Exit Criteria (Current)

Before starting Phase 1 implementation:

1. ✅ Lexilla builds on developer machine
2. ⏳ Scintilla Cocoa framework builds (needs Xcode)
3. ⏳ Demo opens 100 MB file and regex-find in <2s
4. ⏳ Tab shell prototype runs natively

## Success Metric

A developer can use LexPad daily for editing config files, logs, and scripts — replacing TextEdit + external grep for 80% of tasks.
