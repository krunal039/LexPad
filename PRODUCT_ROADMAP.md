# macOS Notepad++-Class Editor — Product Analysis & Roadmap

> **Status:** Planning document (no implementation)  
> **Date:** June 2026  
> **Goal:** Define a native macOS open-source text/code editor with Notepad++-equivalent power, without the bloat of a full IDE.

---

## 1. Executive Summary

Notepad++ has been the de facto lightweight power editor on Windows for 20+ years. There is **no official macOS version**, and the creator (Don Ho) has explicitly stated he will not endorse or co-brand macOS ports due to trademark concerns — though forking the GPL codebase is permitted.

The macOS landscape today splits into three camps:

| Category | Examples | Gap |
|----------|----------|-----|
| **Native lightweight** | CotEditor | Missing column edit, macros, find-in-files depth, plugin ecosystem |
| **Native IDE-aspiring** | CodeEdit | Still immature; targets Xcode-like scope, not N++ simplicity |
| **Cross-platform heavy** | VS Code, Sublime | Too large/slow for users who want a fast scratchpad + log wrangler |
| **Community ports** | Nextpad++, Notemac++ | Branding/legal friction; varying maturity |

**Opportunity:** A purpose-built, **native macOS** editor that delivers Notepad++'s core value proposition — *fast, lightweight, regex-heavy, log-friendly, plugin-extensible* — while respecting macOS HIG and avoiding trademark issues.

---

## 2. Notepad++ Deep Analysis

### 2.1 What Notepad++ Is

- **License:** GPL-3.0 (forkable, but name/logo are trademarked)
- **Platform:** Windows only (Win32 API, x86/x64/ARM64)
- **Core engine:** [Scintilla](https://www.scintilla.org/) + [Lexilla](https://www.scintilla.org/Lexilla.html) for lexing
- **Language:** C++ with STL
- **Binary size:** ~5–15 MB
- **Philosophy:** Maximum editing power, minimum resource use; not an IDE

### 2.2 Technical Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PowerEditor (C++)                     │
│  Menus · Tabs · Sessions · Preferences · Dark Mode       │
├─────────────────────────────────────────────────────────┤
│  ScintillaEditView (wraps Scintilla HWND)               │
│  · 2 views (split/compare) · Document map · Margins     │
├──────────────┬──────────────────┬───────────────────────┤
│   Lexilla    │  Boost.Regex     │   PluginsManager      │
│  (80+ langs) │  (PCRE search)   │   (Win32 DLL plugins) │
└──────────────┴──────────────────┴───────────────────────┘
```

**Key integration points for any macOS rewrite:**
- Scintilla is cross-platform (used by SciTE, Geany, etc.) — viable on macOS
- Lexilla provides the same syntax definitions
- Plugin API is Win32-specific (`SendMessage`, `NPPM_*` messages, DLL exports) — **not portable**
- Dark mode, tabs, and dockable panels are custom Win32 UI

### 2.3 Complete Feature Inventory

Features grouped by category with priority tags for macOS port planning:
- **P0** = Must-have for MVP (core N++ identity)
- **P1** = Expected by N++ users, ship in v1.x
- **P2** = Important but can follow later
- **P3** = Nice-to-have / plugin territory

#### A. Core Editing (P0)

| Feature | N++ Details | macOS Notes |
|---------|-------------|-------------|
| Multi-document tabs | Drag reorder, close button, multi-line/vertical tab modes | Use native `NSTabView` or custom SwiftUI tabs |
| Unlimited undo/redo | Per-document | Standard text system |
| Insert/Overwrite mode | Insert key toggle, status bar indicator | Map to macOS conventions |
| Line numbers | Gutter margin | Standard |
| Word wrap | Toggle, wrap at window or margin | Standard |
| Zoom | Ctrl+scroll | Pinch or Cmd+/- |
| Go to line | Ctrl+G | Standard |
| Recent files | MRU list | Standard |
| Drag & drop files | Open on drop | Standard macOS |
| Large file handling | Partial loading, performance tuning | Critical for log files |

#### B. Selection & Multi-Edit (P0 — N++ differentiator)

| Feature | N++ Details |
|---------|-------------|
| **Column/rectangular mode** | Alt+drag, Alt+Shift+arrows |
| **Multi-cursor editing** | Ctrl+click, Ctrl+drag selections |
| **Multi-select next** | Match case / whole word variants (v8.6+) |
| **Column Editor dialog** | Insert text or incrementing numbers (dec/hex/oct/bin) |
| **Begin/End Select** | Two-step selection for huge files |
| Virtual space | Click/type beyond line end (v8.4.3+) |

#### C. Search & Replace (P0)

| Feature | N++ Details |
|---------|-------------|
| Find / Replace dialog | Normal, Extended (`\n`, `\t`), **Regex (PCRE)** |
| Find in current doc | Mark all, count, incremental search |
| **Find in Files** | Directory recursion, filters, results panel |
| Find in Projects | Project panel scope |
| Bookmark lines from search | Navigate between matches |
| Replace in Files | With confirm or silent mode |

#### D. Syntax & Languages (P0)

| Feature | N++ Details |
|---------|-------------|
| Built-in languages | 80+ via Lexilla |
| Syntax highlighting | Keywords, operators, strings, comments |
| Code folding | Block collapse/expand |
| **User Defined Languages (UDL)** | GUI builder, XML export/import |
| Language auto-detection | By extension |
| Style configurator | Per-language colors, fonts |
| Themes | 30+ built-in, dark/light mode (v8.0+) |

#### E. Auto-Completion (P1)

| Feature | N++ Details |
|---------|-------------|
| Word completion | From current document |
| Function completion | From API XML files |
| Function parameter hints | Calltip popup |
| Pathname completion | File paths in strings |

#### F. Line & Text Operations (P0 — power-user bread and butter)

**Line Operations:**
- Duplicate line
- Remove duplicate lines / consecutive duplicates
- Split lines / Join lines
- Move line up/down, transpose line
- Reverse line order, randomize
- Sort: lexicographic, case-insensitive, locale, integer, decimal, by length
- Column-aware sorting
- Remove empty lines (with/without whitespace)

**Blank Operations:**
- Trim leading/trailing/both whitespace
- EOL to space, trim + EOL to space
- Tab ↔ Space conversion (all/leading)

**Case Conversion:**
- Upper, lower, proper, sentence, invert, random

**Comment/Uncomment:**
- Single-line and block, language-aware

**Insert:**
- Date/time (short, long, custom format)

**EOL Conversion:**
- CRLF ↔ LF ↔ CR

#### G. Navigation & Marks (P1)

| Feature | N++ Details |
|---------|-------------|
| **Bookmarks** | Toggle, next/prev, clear all, bookmark all lines |
| **Mark system** | 5 styles (colored markers in margin) |
| **Change history margin** | Orange=unsaved edit, green=saved edit (v8.4.6+) |
| Document Map | Minimap sidebar |
| Function List panel | Regex-based symbol parser, XML configurable |
| Character Panel | Insert ASCII/Unicode/HTML entities |

#### H. Multi-View (P1)

| Feature | N++ Details |
|---------|-------------|
| Split view (horizontal/vertical) | Two Scintilla instances |
| Move tab to other view | Drag or context menu |
| Clone document | Same buffer, two views |
| Synchronized scrolling | Optional |
| Multiple instances | `-multiInst` |

#### I. File & Project Management (P1)

| Feature | N++ Details |
|---------|-------------|
| **Folder as Workspace** | Tree panel, open files from tree |
| **Project panels** | Save/load `.npproj` workspace files |
| **Session management** | Save/restore open tabs, positions |
| Monitor file changes | Reload prompt on external change |
| Read-only mode | Visual indicator |
| Open as admin | Windows UAC elevation (N/A on macOS) |
| Save copy / rename | Standard |

#### J. Encoding (P0 for international users)

| Feature | N++ Details |
|---------|-------------|
| UTF-8, UTF-8 BOM, UTF-16 BE/LE | With BOM handling |
| ANSI / codepage selection | macOS: focus on UTF-8 default |
| Auto-detect encoding | Charset guessing |
| Convert encoding | Preserve or reinterpret |
| GB18030, Big5, Shift-JIS, etc. | Legacy file support |

#### K. Macros (P1)

| Feature | N++ Details |
|---------|-------------|
| Record macro | Captures edits + some commands |
| Playback | Repeat N times |
| Save/load macros | Persistent macro library |
| Shortcut assignment | Per macro |

#### L. Printing (P3)

- WYSIWYG print with syntax colors
- macOS: use `NSPrintOperation`

#### M. Preferences & Customization (P1)

| Area | Options |
|------|---------|
| General | Tab bar style, status bar, recent files limit |
| Editing | Caret, multi-edit, auto-indent, copy with/without formatting |
| Margins | Line number, bookmark, change history, folding |
| New Document | Default language, encoding, EOL |
| Default Directory | Open/save paths |
| Auto-Completion | Triggers, character thresholds |
| Language | Tab size, replace-by-space per language |
| Highlighting | Smart highlight, tag match, brace match |
| Print | Header/footer, margins |
| MISC | Session ext, workspace ext, cloud sync path |
| Dark Mode | Follow system, custom tones (v8.1+) |
| **Shortcut Mapper** | Full keyboard remapping |

#### N. Command Line (P1)

```
notepad++ [file] [-lLang] [-nLine] [-cColumn]
          [-nosession] [-multiInst]
          [-openSession session.xml]
          [-openFoldersAsWorkspace folder...]
```

#### O. Plugin Ecosystem (P2 for MVP, P1 long-term)

**Architecture:** Win32 DLLs exporting `setInfo`, `beNotified`, `messageProc`, etc.

**Popular plugins (2025–2026 activity):**

| Plugin | Purpose | Priority to Built-in |
|--------|---------|---------------------|
| ComparePlus | Side-by-side diff | **P1** — expected feature |
| JSON Viewer | Tree view | P2 |
| DSpellCheck | Hunspell spell check | P2 |
| NppFTP | SFTP/FTP edit | P3 |
| CSV Lint | CSV validate/convert | P2 |
| NppExport | Export to RTF/HTML | P3 |
| Mime Tool | Base64, URL encode | P2 |
| NppOpenAI | AI assist | P3 (or skip) |

**Plugins Admin:** Built-in marketplace with one-click install.

---

## 3. Competitive Landscape (macOS)

### 3.1 Existing Alternatives

| Editor | License | Strengths | Weaknesses vs N++ |
|--------|---------|-----------|-------------------|
| **CotEditor** | Apache 2.0 | Native Swift, fast, regex find, outline, scripts | No column mode, no macros, no find-in-files, no plugins |
| **CodeEdit** | MIT | Native Swift, Git, terminal, extensions | Immature, IDE-oriented, heavy roadmap |
| **BBEdit** | Commercial | Mac power user standard | Not open source, $49+ |
| **VS Code** | MIT | Everything | 300MB+, slow startup, overkill |
| **Sublime Text** | Commercial | Fast, multi-cursor | $99, not OSS, limited Git |
| **Nextpad++** | GPL-3.0 | Claims full N++ port | Trademark dispute, independent maintenance |
| **Notemac++** | MIT | N++-inspired, Tauri+Monaco | Not truly native, web-tech stack |
| **TextMate** | Proprietary | Snippets, bundles | Aging, not fully OSS |

### 3.2 Strategic Positioning

**Target user:** Windows refugees, DevOps/SRE log wranglers, data analysts cleaning CSV/logs, sysadmins editing config files, developers wanting a *scratchpad* not an IDE.

**Positioning statement:**
> *"The fast, native macOS text editor for people who miss Notepad++ — without becoming VS Code."*

**Differentiators:**
1. Column mode + multi-edit + regex as first-class features (Day 1)
2. Find in Files optimized for logs (multi-GB, encoding detection)
3. Native macOS feel (sandbox, Touch Bar, Quick Look, Services menu)
4. Small binary (<20 MB), instant launch
5. Open plugin API designed for macOS from the start

---

## 4. Technical Approach Options

### Option A: Native Swift + Scintilla/Lexilla (Recommended)

| Pros | Cons |
|------|------|
| True macOS native UX | Scintilla macOS integration is less common |
| Best performance & battery | C++ bridge complexity |
| App Store / notarization friendly | Smaller Scintilla-Swift community |
| Sandboxing possible | Lexilla integration work |

**Stack:** Swift, AppKit/SwiftUI hybrid, Scintilla via Obj-C++ bridge, Lexilla, PCRE2 (or ICU regex)

### Option B: Native Swift + Custom Text Engine (CodeEdit path)

| Pros | Cons |
|------|------|
| Full control, modern Swift | Years of editor edge-case work |
| No Scintilla dependency | Must rebuild syntax, folding, etc. |
| Matches Apple text system | Hard to match N++ regex performance |

### Option C: Tauri/Electron + Monaco/CodeMirror (Notemac++ path)

| Pros | Cons |
|------|------|
| Fast cross-platform development | Not truly native feel |
| Rich web editor features | Higher memory, worse macOS integration |
| Web + desktop from one codebase | Users explicitly want native |

### Option D: Port Notepad++ codebase (Nextpad++ path)

| Pros | Cons |
|------|------|
| Feature parity fastest | Win32 → Cocoa is massive rewrite |
| GPL inheritance | Trademark cannot use "Notepad++" |
| Same Scintilla integration | Maintaining divergent fork is costly |

**Recommendation:** **Option A** — Native Swift shell with Scintilla/Lexilla core. Reuses battle-tested editing engine while building macOS-native chrome and a new plugin API.

---

## 5. Product Roadmap

### Phase 0: Discovery & Foundation (Weeks 1–4)

**Goals:** Validate approach, name the project, set up repo.

| Task | Deliverable |
|------|-------------|
| Project naming & branding | Unique name (avoid N++ trademark) |
| Architecture decision record | ADR documenting Option A |
| Scintilla macOS spike | Proof-of-concept: open file, syntax highlight, regex find |
| Lexilla integration spike | Load 5 languages, verify folding |
| User research | Survey 10–20 N++ users on must-have features |
| License selection | Recommend **GPL-3.0** (Lexilla/Scintilla compatible) or **MIT** if clean-room |

**Exit criteria:** Demo app opens a 100MB log file, highlights syntax, finds regex pattern in <2s.

---

### Phase 1: MVP — "Usable Daily Driver" (Months 2–4)

**Theme:** Replace TextEdit for power users.

#### P0 Features

- [ ] Multi-document tabbed interface
- [ ] Open/save/new, drag-drop, recent files
- [ ] Syntax highlighting (top 20 languages via Lexilla)
- [ ] Code folding
- [ ] Line numbers, word wrap, go-to-line
- [ ] Find / Replace (normal + regex via PCRE2)
- [ ] Find in current document (mark all, match count)
- [ ] **Column/rectangular selection mode**
- [ ] **Multi-cursor editing**
- [ ] Line operations: duplicate, sort, remove duplicates, join/split
- [ ] Blank operations: trim whitespace, tab/space convert
- [ ] EOL conversion (LF/CRLF/CR)
- [ ] Case conversion (upper/lower/proper)
- [ ] UTF-8 default + encoding detection/conversion
- [ ] Dark/light mode (follow system)
- [ ] Basic preferences (font, tab size, theme)
- [ ] Status bar (line, col, encoding, EOL, language)
- [ ] macOS native: sandbox, autosave, resume

**Target:** Private alpha with 5–10 testers.

---

### Phase 2: v1.0 — "Notepad++ Parity Core" (Months 5–8)

**Theme:** Feature-complete for 80% of N++ users.

#### P1 Features

- [ ] **Find in Files** (recursive, filters, results panel, encoding)
- [ ] Replace in Files
- [ ] **Compare files** (built-in diff view — no plugin needed)
- [ ] Split view + clone document
- [ ] Synchronized scrolling
- [ ] Document Map (minimap)
- [ ] Bookmarks + mark styles (5 colors)
- [ ] **Macro record/playback/save**
- [ ] **Session save/restore**
- [ ] Folder as Workspace panel
- [ ] Function List panel (regex symbol parser)
- [ ] User Defined Languages (UDL) editor
- [ ] Style configurator + 10 built-in themes
- [ ] Auto-completion (word + function)
- [ ] Comment/uncomment (language-aware)
- [ ] Column Editor dialog (number insertion)
- [ ] Multi-select next (match case/word)
- [ ] Change history margin
- [ ] Shortcut mapper (full remapping)
- [ ] Command-line arguments
- [ ] Print support
- [ ] Character insert panel
- [ ] External file change detection + reload prompt
- [ ] All 80+ Lexilla languages

**Target:** Public beta, Homebrew cask, GitHub releases (signed + notarized).

---

### Phase 3: v1.x — "Extensibility & Polish" (Months 9–12)

**Theme:** Plugin ecosystem + enterprise features.

| Feature | Notes |
|---------|-------|
| **Plugin API v1** | Swift Package or XPC-based plugins (NOT Win32 DLL) |
| Plugin manager UI | Browse, install, update |
| Bundled plugins | JSON viewer, spell check, MIME tools, CSV lint |
| Project panels | Save/load workspace files |
| Snippets | TextExpander-like templates |
| Large file mode | Disable highlighting, memory-map reads |
| Binary/hex view | Read-only hex panel |
| Incremental search | Cmd+E style |
| Translated UI | 10+ languages |
| Accessibility audit | VoiceOver, keyboard-only |
| Performance profiling | 1GB+ file benchmarks |

---

### Phase 4: v2.0 — "Modern macOS Native" (Year 2)

**Theme:** Features N++ doesn't have but macOS users expect.

| Feature | Rationale |
|---------|-----------|
| Git integration (basic) | Diff, blame, stage hunks — N++ lacks this |
| Quick Open (Cmd+P) | File fuzzy finder |
| Command palette | Discoverability |
| macOS Services integration | System-wide text services |
| Shortcuts / Automator | macOS automation |
| iCloud sync | Settings + sessions (optional) |
| Apple Intelligence hooks | Optional, privacy-first |
| Remote editing (SFTP) | Replaces NppFTP plugin |
| Collaborative editing | Stretch goal |
| LSP support (optional) | Go-to-definition without full IDE bloat |

---

## 6. Feature Priority Matrix

```
                    IMPACT ON N++ USERS
                 Low ────────────────── High
            ┌─────────────────────────────────┐
     High   │ Hex view    │ Column mode     │
            │ Snippets    │ Regex find/replace│
            │ iCloud sync │ Find in Files    │
  EFFORT    │ LSP         │ Multi-cursor     │
            │ AI assist   │ Syntax+folding   │
            ├─────────────────────────────────┤
     Low    │ Print       │ Tabs             │
            │ Themes 30+  │ Line operations  │
            │ Localization│ Encoding support │
            └─────────────────────────────────┘
```

**MVP scope:** High impact + low-to-medium effort quadrant.

---

## 7. macOS-Specific Requirements

Features N++ lacks but macOS users expect:

| Requirement | Implementation |
|-------------|----------------|
| Universal Binary | Apple Silicon + Intel |
| Notarization & Hardened Runtime | Required for distribution |
| App Sandbox | Optional but recommended for App Store |
| Native menus & shortcuts | Cmd not Ctrl (with optional N++ preset) |
| Touch Bar support | Optional |
| Quick Look plugin | Preview files in Finder |
| Services menu | "Open in [Editor]" |
| Dictation & emoji picker | Standard NSTextView behaviors |
| Window tabbing | Native macOS window tabs |
| Full Screen & Split View | Standard |
| Retina / font rendering | Core Text |
| Right-to-left text | Bidirectional support |

### Keyboard Mapping Strategy

Offer two preset schemes:
1. **macOS Standard** — Cmd+C/V, Cmd+F, etc.
2. **Notepad++ Compatible** — Ctrl mappings for Windows refugees

---

## 8. Non-Functional Requirements

| Metric | Target |
|--------|--------|
| Cold launch | <500ms to editable window |
| Memory (empty) | <50 MB |
| Memory (50 tabs, small files) | <200 MB |
| Open 100 MB file | <3s, responsive scrolling |
| Find in 1 GB file | <10s with regex |
| Binary size | <25 MB |
| Crash rate | <0.1% sessions |
| Test coverage | >70% on core editing logic |

---

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Scintilla macOS maturity | High | Early spike; fallback to CodeEdit's SourceEditor if needed |
| Trademark (Notepad++ name) | Legal | Unique branding from day 1 |
| Scope creep → IDE | Product drift | Strict "not an IDE" charter; defer LSP/Git to v2 |
| Plugin ecosystem chicken-egg | Adoption | Ship 5 bundled plugins; document API early |
| Nextpad++ / existing ports | Competition | Focus on native quality + open governance |
| One maintainer burnout | Sustainability | Modular architecture; seek co-maintainers early |
| GPL license friction | App Store | Evaluate dual-licensing or MIT wrapper |

---

## 10. Success Metrics

### Launch (v1.0)

- [ ] 1,000 GitHub stars in 6 months
- [ ] Homebrew install available
- [ ] 50+ beta testers providing feedback
- [ ] Feature checklist: 90% of N++ core features

### Growth (Year 1)

- [ ] 10,000 active users (telemetry-opt-in)
- [ ] 10+ community plugins
- [ ] Featured in at least one major Mac publication
- [ ] <5 open P0 bugs at any time

---

## 11. Suggested Project Name Candidates

Avoid "Notepad++" and frog/chameleon imagery. Consider:

- **PadMac** / **PadEdit**
- **Scribe** / **ScribePad**
- **LexPad**
- **Margin** (editor margin reference)
- **Scratchpad** (descriptive)

*(Final name requires trademark search.)*

---

## 12. Recommended Team & Timeline

| Role | Phase Needed |
|------|--------------|
| macOS/Swift developer (lead) | Phase 0+ |
| C++/Scintilla specialist | Phase 0–2 |
| UX designer (part-time) | Phase 1–2 |
| Technical writer | Phase 2+ |
| Community manager | Phase 2+ |

**Solo developer estimate:** 12–18 months to v1.0  
**Small team (2–3):** 6–9 months to v1.0

---

## 13. Next Steps (When Ready to Implement)

1. **Review this roadmap** — confirm scope and positioning
2. **Run Phase 0 spikes** — Scintilla on macOS proof-of-concept
3. **Choose project name** — trademark check
4. **Create GitHub repo** — LICENSE, CONTRIBUTING, CODE_OF_CONDUCT
5. **Build MVP tab shell** — file open/save + basic editor
6. **Iterate with users** — weekly builds, Discord/GitHub Discussions

---

## Appendix A: Notepad++ Feature Checklist (Implementation Tracker)

Use this as a living checklist during development.

### Editing Core
- [ ] Tabs (multi-document)
- [ ] Undo/redo
- [ ] Insert/overwrite mode
- [ ] Column selection
- [ ] Multi-cursor
- [ ] Multi-select next
- [ ] Column editor dialog
- [ ] Virtual space
- [ ] Begin/end select
- [ ] Drag & drop text
- [ ] Large file support

### Search
- [ ] Find (normal, extended, regex)
- [ ] Replace
- [ ] Find in files
- [ ] Replace in files
- [ ] Mark all / bookmark all
- [ ] Incremental search
- [ ] Find in project

### Languages
- [ ] 80+ syntax highlighters
- [ ] Code folding
- [ ] User defined languages
- [ ] Style configurator
- [ ] Language auto-detect
- [ ] Dark/light themes

### Line/Text Ops
- [ ] All line operations (see Section 2.3F)
- [ ] All blank operations
- [ ] All case conversions
- [ ] Comment/uncomment
- [ ] EOL conversion
- [ ] Date/time insert

### Navigation
- [ ] Bookmarks
- [ ] Mark styles (5)
- [ ] Change history
- [ ] Document map
- [ ] Function list
- [ ] Go to line
- [ ] Character panel

### Views
- [ ] Split horizontal/vertical
- [ ] Clone document
- [ ] Sync scroll
- [ ] Multiple windows

### Files/Projects
- [ ] Folder as workspace
- [ ] Project panels
- [ ] Session management
- [ ] File monitoring
- [ ] Encoding detection/conversion

### Automation
- [ ] Macro record/playback
- [ ] Macro library
- [ ] Command line args

### Customization
- [ ] Preferences (all sections)
- [ ] Shortcut mapper
- [ ] Plugin system
- [ ] Plugin manager

### Platform
- [ ] Compare/diff
- [ ] Print
- [ ] Spell check
- [ ] JSON/XML tools

---

## Appendix B: Key References

- [Notepad++ GitHub](https://github.com/notepad-plus-plus/notepad-plus-plus)
- [Notepad++ User Manual](https://npp-user-manual.org/docs/)
- [Scintilla Documentation](https://www.scintilla.org/ScintillaDoc.html)
- [Lexilla](https://www.scintilla.org/Lexilla.html)
- [CotEditor](https://github.com/coteditor/CotEditor)
- [CodeEdit](https://github.com/CodeEditApp/CodeEdit)
- [Trademark dispute context (2026)](https://www.tomshardware.com/tech-industry/notepad-plus-plus-creator-threatens-legal-action-over-macos-port)

---

*Document version 1.0 — ready for review and scope negotiation before implementation begins.*
