// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "UnscrollCore", platforms: [.macOS(.v14), .iOS(.v17)], products: [.library(name: "UnscrollCore", targets: ["UnscrollCore"])], targets: [.target(name: "UnscrollCore", path: "Shared/Core"), .testTarget(name: "UnscrollCoreTests", dependencies: ["UnscrollCore"], path: "Tests/CoreTests")])
