// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BetterThingsKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "BetterThingsKit", targets: ["BetterThingsKit"])
    ],
    targets: [
        .target(name: "BetterThingsKit"),
        .testTarget(name: "BetterThingsKitTests", dependencies: ["BetterThingsKit"])
    ]
)
