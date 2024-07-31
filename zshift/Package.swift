// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "zshift",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  targets: [
    .executableTarget(
      name: "zshift"),
    .testTarget(
      name: "zshiftTests",
      dependencies: ["zshift"]),
  ]
)
