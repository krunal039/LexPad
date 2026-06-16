// swift-tools-version: 5.9
import Foundation
import PackageDescription

let packageDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let repoRoot = packageDir.deletingLastPathComponent()
let vendor = repoRoot.appendingPathComponent("Vendor")
let scintillaFramework = vendor
    .appendingPathComponent("scintilla/cocoa/Scintilla/build/Release")
    .path
let scintillaFrameworkBinary = scintillaFramework + "/Scintilla.framework/Scintilla"
let lexillaInclude = vendor.appendingPathComponent("lexilla/include").path
let lexillaLib = vendor.appendingPathComponent("lexilla/bin").path
let scintillaInclude = vendor.appendingPathComponent("scintilla/include").path
let scintillaCocoa = vendor.appendingPathComponent("scintilla/cocoa").path

let scintillaBuilt = FileManager.default.fileExists(atPath: scintillaFrameworkBinary)

var lexPadDependencies: [Target.Dependency] = ["LexPadCore"]
var lexPadLinkerSettings: [LinkerSetting] = [
    .linkedFramework("AppKit"),
]

if scintillaBuilt {
    lexPadDependencies.append("ScintillaBridge")
    lexPadLinkerSettings.append(.unsafeFlags([
        "-Xlinker", "-rpath", "-Xlinker", "@loader_path",
    ]))
}

let package = Package(
    name: "LexPad",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "LexPad", targets: ["LexPad"]),
        .executable(name: "LexPadBenchmark", targets: ["LexPadBenchmark"]),
        .library(name: "LexPadCore", targets: ["LexPadCore"]),
    ],
    targets: {
        var targets: [Target] = [
            .executableTarget(
                name: "LexPad",
                dependencies: lexPadDependencies,
                swiftSettings: scintillaBuilt ? [.define("LEXPAD_HAS_SCINTILLA")] : [],
                linkerSettings: lexPadLinkerSettings
            ),
            .executableTarget(
                name: "LexPadBenchmark",
                dependencies: ["LexPadCore"]
            ),
            .target(
                name: "LexPadCore",
                linkerSettings: [
                    .linkedFramework("AppKit"),
                ]
            ),
            .testTarget(
                name: "LexPadTests",
                dependencies: ["LexPadCore"]
            ),
        ]

        if scintillaBuilt {
            targets.append(
                .target(
                    name: "ScintillaBridge",
                    path: "Sources/ScintillaBridge",
                    publicHeadersPath: "include",
                    cxxSettings: [
                        .unsafeFlags([
                            "-I", scintillaInclude,
                            "-I", scintillaCocoa,
                            "-I", lexillaInclude,
                            "-F", scintillaFramework,
                            "-std=c++17",
                        ]),
                    ],
                    linkerSettings: [
                        .unsafeFlags([
                            "-F", scintillaFramework,
                            "-framework", "Scintilla",
                            "-L", lexillaLib,
                            "-llexilla",
                            "-lc++",
                        ]),
                    ]
                )
            )
        }

        return targets
    }()
)
