// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WorldClocks",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(name: "WorldClocks"),
        .testTarget(name: "WorldClocksTests", dependencies: ["WorldClocks"]),
    ],
    swiftLanguageModes: [.v5]
)
