// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MarkdownReader",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "MarkdownReader", targets: ["MarkdownReader"]),
    ],
    targets: [
        .executableTarget(
            name: "MarkdownReader",
            dependencies: ["ScrollMap"],
            path: "Sources/MarkdownReader",
            resources: [.copy("Resources")]
        ),
        .target(name: "ScrollMap"),
        .testTarget(name: "ScrollMapTests", dependencies: ["ScrollMap"]),
    ]
)
