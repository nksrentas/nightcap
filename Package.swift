// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Nightcap",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "NightcapCore"),
        .executableTarget(name: "Nightcap", dependencies: ["NightcapCore"]),
        .testTarget(name: "NightcapCoreTests", dependencies: ["NightcapCore"]),
    ]
)
