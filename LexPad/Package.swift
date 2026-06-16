// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LexPad",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "LexPad", targets: ["LexPad"]),
        .executable(name: "LexPadBenchmark", targets: ["LexPadBenchmark"]),
        .library(name: "LexPadCore", targets: ["LexPadCore"]),
    ],
    targets: [
        .executableTarget(
            name: "LexPad",
            dependencies: ["LexPadCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
            ]
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
)
