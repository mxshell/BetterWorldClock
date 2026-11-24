// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BetterWorldClock",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(name: "BetterWorldClock"),
        .testTarget(name: "BetterWorldClockTests", dependencies: ["BetterWorldClock"]),
    ],
    swiftLanguageModes: [.v5]
)
