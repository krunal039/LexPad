#!/usr/bin/env python3
"""Generate LanguageRegistryData.swift and EditorLanguage.swift from Notepad++ langs.model.xml."""

from __future__ import annotations

import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "LexPad" / "Sources" / "LexPadCore"
NPP_XML_URL = "https://raw.githubusercontent.com/notepad-plus-plus/notepad-plus-plus/master/PowerEditor/src/langs.model.xml"
NPP_XML_LOCAL = Path("/tmp/langs.model.xml")

LEXILLA_EXTRA = {
    "zig": ["zig"],
    "dart": ["dart"],
    "julia": ["jl"],
    "kotlin": ["kt", "kts"],
    "scala": ["scala", "sc"],
    "fsharp": ["fs", "fsi", "fsx"],
    "markdown": ["md", "markdown", "mdown", "mkd", "mdx"],
    "dockerfile": ["dockerfile", "containerfile"],
    "nginx": ["nginx"],
    "apache": ["htaccess", "htpasswd"],
    "graphql": ["graphql", "gql"],
    "protobuf": ["proto"],
    "asciidoc": ["adoc", "asciidoc", "asc"],
    "troff": ["roff", "man"],
    "nix": ["nix"],
    "mysql": ["mysql"],
    "progress": ["p", "w"],
    "sinex": ["snx"],
    "edifact": ["edi"],
    "x12": ["x12"],
    "dataflex": ["src", "pkg"],
    "ecl": ["ecl", "eclxml"],
    "gap": ["g", "gi", "gd", "gap"],
    "magiksf": ["magik"],
    "maxima": ["mac", "max"],
    "metapost": ["mp", "mpx"],
    "modula": ["def", "mod"],
    "nimrod": ["nimrod"],
    "opal": ["opal", "opp"],
    "pov": ["pov"],
    "po": ["po", "pot"],
    "powerpro": ["powerpro"],
    "scriptol": ["sol"],
    "specman": ["e", "ecom"],
    "stata": ["do", "ado"],
    "tads3": ["t", "t2", "t3"],
    "tal": ["tal"],
    "tacl": ["tacl"],
    "tcmd": ["btm"],
    "sorcins": ["sorc"],
    "literatehaskell": ["lhs"],
    "latex": ["latex", "ltx", "bib"],
    "phpscript": ["phps"],
    "syntext": ["syntext", "stx"],
    "log": ["log", "out"],
    "vbscript": ["vbs"],
    "DMIS": ["dmis"],
    "DMAP": ["dmap"],
    "PL/M": ["plm"],
    "SML": ["sig", "fun", "cm"],
    "ave": ["ave"],
    "asy": ["asy"],
    "abaqus": ["inp"],
    "apdl": ["mac"],
    "a68k": ["a68k"],
    "bullant": ["ant"],
    "cil": ["il"],
    "clarion": ["clw"],
    "clarionnocase": ["cww"],
    "conf": ["conf"],
    "crontab": ["cron", "crontab"],
    "indent": ["indent"],
    "kvirc": ["kvs"],
    "lout": ["lt"],
    "lot": ["lot"],
    "fcST": ["iecst", "scl"],
    "flagship": ["prg"],
}

RESERVED_SWIFT = {
    "default", "switch", "case", "return", "import", "class", "struct", "enum",
    "protocol", "extension", "type", "self", "in", "for", "while", "if", "else",
    "func", "var", "let", "true", "false", "nil", "operator", "subscript", "init",
    "deinit", "where", "as", "is", "try", "catch", "throw", "async", "await",
    "some", "any", "repeat", "do", "break", "continue", "fallthrough", "guard",
    "defer", "public", "private", "internal", "fileprivate", "open", "static",
    "final", "override", "required", "convenience", "lazy", "weak", "unowned",
    "mutating", "nonmutating", "indirect", "precedencegroup", "inout",
    "associatedtype", "typealias", "d", "r", "c", "go", "sql", "xml", "html",
    "css", "php", "vb", "ini", "toml", "yaml", "json", "log", "diff", "batch",
    "lua", "perl", "ruby", "python", "swift", "java", "kotlin", "scala", "rust",
    "shell", "markdown", "latex", "cmake", "dockerfile", "makefile", "properties",
    "protobuf", "graphql", "vue", "nginx", "apache", "assembly", "fortran",
    "haskell", "verilog", "vhdl", "objc", "matlab", "tcl", "powershell", "csharp",
    "fsharp", "vbnet", "restructuredtext", "syntext", "plain", "normal", "null",
    "errorlist", "escseq", "indent", "searchresult", "hex", "ihex", "srec", "tehex",
    "cs", "cpp", "props", "asm", "rc", "tex", "gdscript", "typescript", "javascript",
    "registry", "scheme", "spice", "smalltalk", "rebol", "raku", "sas", "nim", "nsis",
    "oscript", "pascal", "postscript", "purebasic", "visualprolog", "txt2tags", "nfo",
    "inno", "kix", "lisp", "mmixal", "mssql", "nncrontab", "gui4cli", "hollywood",
    "freebasic", "forth", "fortran77", "escript", "erlang", "cobol", "caml",
    "coffeescript", "csound", "blitzbasic", "baanc", "avs", "autoit", "asp", "asn1",
    "ada", "actionscript", "json5", "jsp", "bash", "errorlist",
}

DISPLAY_NAMES = {
    "normal": "Plain Text",
    "cs": "C#",
    "cpp": "C++",
    "c": "C",
    "javascript.js": "JavaScript",
    "javascript": "JavaScript (Embedded)",
    "html": "HTML",
    "props": "Properties",
    "vb": "Visual Basic",
    "fortran77": "Fortran 77",
    "makefile": "Makefile",
    "batch": "Batch",
    "bash": "Shell",
    "errorlist": "Error List",
    "escseq": "Escape Sequence",
    "rc": "Resource Script",
    "asn1": "ASN.1",
    "autoit": "AutoIt",
    "baanc": "BaanC",
    "blitzbasic": "BlitzBasic",
    "caml": "OCaml",
    "cobol": "COBOL",
    "coffeescript": "CoffeeScript",
    "actionscript": "ActionScript",
    "asp": "ASP",
    "escript": "eScript",
    "freebasic": "FreeBasic",
    "gui4cli": "Gui4Cli",
    "hollywood": "Hollywood",
    "kix": "KiXtart",
    "lisp": "Lisp",
    "mmixal": "MMIXAL",
    "mssql": "T-SQL",
    "mysql": "MySQL",
    "nncrontab": "nnCron",
    "nsis": "NSIS",
    "objc": "Objective-C",
    "pascal": "Pascal",
    "postscript": "PostScript",
    "purebasic": "PureBasic",
    "rebol": "REBOL",
    "registry": "Registry",
    "smalltalk": "Smalltalk",
    "spice": "Spice",
    "tex": "TeX",
    "txt2tags": "txt2tags",
    "visualprolog": "Visual Prolog",
    "yaml": "YAML",
    "zig": "Zig",
    "dart": "Dart",
    "julia": "Julia",
    "kotlin": "Kotlin",
    "scala": "Scala",
    "fsharp": "F#",
    "markdown": "Markdown",
    "dockerfile": "Dockerfile",
    "nginx": "Nginx",
    "apache": "Apache",
    "graphql": "GraphQL",
    "protobuf": "Protobuf",
    "asciidoc": "AsciiDoc",
    "troff": "Troff",
    "nix": "Nix",
    "progress": "Progress ABL",
    "sinex": "Sinex",
    "syntext": "Syntext",
    "log": "Log",
    "vbscript": "VBScript",
    "ihex": "Intel HEX",
    "srec": "Motorola S-Record",
    "tehex": "Tektronix HEX",
    "gdscript": "GDScript",
    "typescript": "TypeScript",
    "json5": "JSON5",
    "json": "JSON",
    "css": "CSS",
    "ini": "INI",
    "toml": "TOML",
    "xml": "XML",
    "diff": "Diff",
    "d": "D",
    "go": "Go",
    "java": "Java",
    "lua": "Lua",
    "perl": "Perl",
    "php": "PHP",
    "python": "Python",
    "ruby": "Ruby",
    "rust": "Rust",
    "sql": "SQL",
    "swift": "Swift",
    "tcl": "Tcl",
    "verilog": "Verilog",
    "vhdl": "VHDL",
    "haskell": "Haskell",
    "fortran": "Fortran",
    "latex": "LaTeX",
    "matlab": "Matlab",
    "powershell": "PowerShell",
    "r": "R",
    "raku": "Raku",
    "scheme": "Scheme",
    "sas": "SAS",
    "nim": "Nim",
    "oscript": "OScript",
    "erlang": "Erlang",
    "forth": "Forth",
    "asm": "Assembly",
    "ada": "Ada",
    "avs": "AVS",
    "csound": "Csound",
    "inno": "Inno Setup",
    "nfo": "NFO",
    "jsp": "JSP",
    "cmake": "CMake",
}

SPECIAL_MAP = {
    "diff": "diff",
    "html": "html",
    "xml": "xml",
    "css": "css",
    "json": "json",
    "json5": "json",
    "yaml": "yaml",
    "markdown": "markdown",
    "errorlist": "log",
    "syntext": "syntext",
}

# Notepad++ language name -> Lexilla CreateLexer() name
LEXILLA_OVERRIDES: dict[str, str | None] = {
    "normal": None,
    "nfo": None,
    "searchResult": None,
    "syntext": None,
    "html": "hypertext",
    "javascript": "hypertext",
    "javascript.js": "cpp",
    "typescript": "cpp",
    "jsp": "hypertext",
    "asp": "hypertext",
    "php": "hypertext",
    "cs": "cpp",
    "c": "cpp",
    "java": "cpp",
    "go": "cpp",
    "swift": "cpp",
    "objc": "cpp",
    "rc": "cpp",
    "actionscript": "cpp",
    "cobol": "cpp",
    "fortran77": "f77",
    "ini": "props",
    "latex": "latex",
    "tex": "latex",
    "json5": "json",
    "autoit": "au3",
    "baanc": "baan",
    "postscript": "ps",
    "scheme": "lisp",
    "mssql": "mssql",
}


def lexilla_name(npp_name: str) -> str | None:
    if npp_name in LEXILLA_OVERRIDES:
        return LEXILLA_OVERRIDES[npp_name]
    return npp_name


def to_swift_case(name: str) -> str:
    n = name.lower().strip()
    n = re.sub(r"[^a-z0-9]+", "_", n)
    n = re.sub(r"_+", "_", n).strip("_")
    if n and n[0].isdigit():
        n = "lang_" + n
    if n in RESERVED_SWIFT:
        n = n + "_lang"
    return n


def display_name(name: str) -> str:
    return DISPLAY_NAMES.get(name, name.replace(".js", "").replace("_", " ").title())


def comment_style(line: str, start: str, end: str) -> str:
    mapping = {
        "#": "hash",
        "//": "slashSlash",
        ";": "semicolon",
        "--": "doubleDash",
        "%": "percent",
        "!": "bang",
        "'": "apostrophe",
        "|": "pipe",
        "*>": "cobol",
        ";;": "doubleSemicolon",
        "REM": "rem",
        "\\": "backslash",
    }
    if line in mapping:
        return mapping[line]
    if start == "/*" and end == "*/":
        return "block"
    if start == "(*" and end == "*)":
        return "ocaml"
    if start == "<!--" and end == "-->":
        return "html"
    if start == "#CS" and end == "#CE":
        return "autoit"
    if start == "(" and end == ")":
        return "paren"
    return "generic"


def sanitize_keyword(word: str) -> str | None:
    if not word or "=" in word or len(word) > 40:
        return None
    if not re.match(r"^[\w@.$-]+$", word):
        return None
    return word


def swift_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def swift_str_list(items: list[str]) -> str:
    if not items:
        return "[]"
    return "[" + ", ".join(f'"{swift_escape(x)}"' for x in items) + "]"


def ensure_xml() -> Path:
    if not NPP_XML_LOCAL.exists():
        print(f"Downloading {NPP_XML_URL}...")
        urllib.request.urlretrieve(NPP_XML_URL, NPP_XML_LOCAL)
    return NPP_XML_LOCAL


def main() -> int:
    tree = ET.parse(ensure_xml())
    languages: dict[str, dict] = {}

    for lang_el in tree.getroot().findall(".//Language"):
        name = lang_el.get("name", "")
        if not name or name == "searchResult":
            continue
        exts = [e.strip().lower() for e in (lang_el.get("ext") or "").split() if e.strip()]
        case = to_swift_case(name)
        keywords: list[str] = []
        for kw_el in lang_el.findall("Keywords"):
            if kw_el.get("name") in ("instre1", "instre2", "type1"):
                for word in (kw_el.text or "").split():
                    clean = sanitize_keyword(word)
                    if clean and clean not in keywords:
                        keywords.append(clean)
                    if len(keywords) >= 60:
                        break
            if len(keywords) >= 60:
                break
        style = comment_style(
            lang_el.get("commentLine", ""),
            lang_el.get("commentStart", ""),
            lang_el.get("commentEnd", ""),
        )
        special = SPECIAL_MAP.get(name)
        languages[case] = {
            "id": case,
            "npp_name": name,
            "display": display_name(name),
            "exts": exts,
            "keywords": keywords,
            "comment_style": style,
            "special": special,
            "lexilla": lexilla_name(name),
        }

    ext_to_case: dict[str, str] = {}
    for info in languages.values():
        for e in info["exts"]:
            ext_to_case[e] = info["id"]

    for lex_name, exts in LEXILLA_EXTRA.items():
        case = to_swift_case(lex_name)
        if case not in languages:
            languages[case] = {
                "id": case,
                "npp_name": lex_name,
                "display": display_name(lex_name),
                "exts": [],
                "keywords": [],
                "comment_style": "generic",
                "special": SPECIAL_MAP.get(lex_name),
                "lexilla": lexilla_name(lex_name) if lex_name not in LEXILLA_EXTRA else lex_name,
            }
        for e in exts:
            el = e.lower()
            if el not in ext_to_case:
                languages[case]["exts"].append(el)
                ext_to_case[el] = case

    filename_map = {
        "dockerfile": "dockerfile_lang",
        "containerfile": "dockerfile_lang",
        "makefile": "makefile_lang",
        "gnumakefile": "makefile_lang",
        "cmakelists.txt": "cmake_lang",
        "gemfile": "ruby_lang",
        "rakefile": "ruby_lang",
        "vagrantfile": "ruby_lang",
        "podfile": "ruby_lang",
        "brewfile": "ruby_lang",
    }

    sorted_langs = sorted(languages.values(), key=lambda x: x["display"].lower())

    enum_lines = [
        "import Foundation",
        "",
        "public enum EditorLanguage: String, Sendable, CaseIterable {",
    ]
    for info in sorted_langs:
        enum_lines.append(f'    case {info["id"]} = "{swift_escape(info["display"])}"')
    enum_lines += [
        "",
        "    public static func detect(from url: URL) -> EditorLanguage {",
        "        LanguageRegistry.detect(from: url)",
        "    }",
        "}",
    ]

    data_lines = [
        "import Foundation",
        "",
        "/// Auto-generated from Notepad++ langs.model.xml + Lexilla lexers.",
        "/// Regenerate: python3 scripts/generate-language-registry.py",
        "enum LanguageRegistryData {",
        "    struct LanguageSpec {",
        "        let id: EditorLanguage",
        "        let extensions: [String]",
        "        let keywords: [String]",
        "        let commentStyle: CommentStyle",
        "        let specialHighlighter: SpecialHighlighter?",
        "        let lexillaName: String?",
        "    }",
        "",
        "    enum CommentStyle: String {",
        "        case generic, hash, slashSlash, semicolon, doubleDash, percent, bang",
        "        case apostrophe, pipe, cobol, doubleSemicolon, rem, backslash",
        "        case block, ocaml, html, autoit, paren, none",
        "    }",
        "",
        "    enum SpecialHighlighter: String {",
        "        case diff, html, xml, css, json, yaml, markdown, log, syntext",
        "    }",
        "",
        "    static let filenameMap: [String: EditorLanguage] = [",
    ]
    for fn, case in filename_map.items():
        if case in languages:
            data_lines.append(f'        "{fn}": .{case},')
    data_lines.append("    ]")
    data_lines += [
        "",
        "    static let languages: [LanguageSpec] = [",
    ]
    for info in sorted_langs:
        sp = f'.{info["special"]}' if info["special"] else "nil"
        lex = info["lexilla"]
        lex_val = f'"{swift_escape(lex)}"' if lex else "nil"
        data_lines.append(
            f'        LanguageSpec(id: .{info["id"]}, extensions: {swift_str_list(info["exts"])}, '
            f'keywords: {swift_str_list(info["keywords"])}, commentStyle: .{info["comment_style"]}, '
            f"specialHighlighter: {sp}, lexillaName: {lex_val}),"
        )
    data_lines.append("    ]")
    data_lines.append("}")

    registry_lines = [
        "import Foundation",
        "",
        "public enum LanguageRegistry {",
        "    private static let extensionMap: [String: EditorLanguage] = {",
        "        var map: [String: EditorLanguage] = [:]",
        "        for spec in LanguageRegistryData.languages {",
        "            for ext in spec.extensions {",
        "                map[ext.lowercased()] = spec.id",
        "            }",
        "        }",
        "        return map",
        "    }()",
        "",
        "    public static func detect(from url: URL) -> EditorLanguage {",
        "        let filename = url.lastPathComponent.lowercased()",
        "        if let language = LanguageRegistryData.filenameMap[filename] {",
        "            return language",
        "        }",
        "        let ext = url.pathExtension.lowercased()",
        "        if ext.isEmpty { return .normal_lang }",
        "        return extensionMap[ext] ?? .normal_lang",
        "    }",
        "",
        "    static func spec(for language: EditorLanguage) -> LanguageRegistryData.LanguageSpec? {",
        "        LanguageRegistryData.languages.first { $0.id == language }",
        "    }",
        "",
        "    public static var languageCount: Int { LanguageRegistryData.languages.count }",
        "",
        "    public static func lexillaName(for language: EditorLanguage) -> String? {",
        "        spec(for: language)?.lexillaName",
        "    }",
        "}",
    ]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "EditorLanguage.swift").write_text("\n".join(enum_lines) + "\n", encoding="utf-8")
    (OUT_DIR / "LanguageRegistryData.swift").write_text("\n".join(data_lines) + "\n", encoding="utf-8")
    (OUT_DIR / "LanguageRegistry.swift").write_text("\n".join(registry_lines) + "\n", encoding="utf-8")

    print(f"Generated {len(sorted_langs)} languages, {len(ext_to_case)} extensions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
