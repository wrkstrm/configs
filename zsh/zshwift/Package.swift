// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "zshwift",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  targets: [
    .executableTarget(
      name: "zshwift")
  ]
)
