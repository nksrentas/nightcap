// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Brewtime",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "BrewtimeCore"),
        .executableTarget(name: "Brewtime", dependencies: ["BrewtimeCore"]),
        .testTarget(name: "BrewtimeCoreTests", dependencies: ["BrewtimeCore"]),
    ]
)
