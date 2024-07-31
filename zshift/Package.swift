// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "zshift",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  targets: [
    .executableTarget(
      name: "zshift",
      resources: [
        .copy("Resources"), // This will copy all files in the Resources folder),
      ]),
    .testTarget(
      name: "zshiftTests",
      dependencies: ["zshift"]),
  ]
)
