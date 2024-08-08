// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "zshift",
  platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v12), .watchOS(.v10), .macCatalyst(.v14)],
    products: [
    .executable(name: "zshift", targets: ["Zshift"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
    .package(path: "../../clis/Figlet")
  ],
  targets: [
    .executableTarget(
      name: "Zshift",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SwiftFigletKit", package: "Figlet")
      ],
      resources: [
        .process("Resources"), // This will copy all files in the Resources folder),
      ]),
    .testTarget(
      name: "zshiftTests",
      dependencies: ["Zshift"]),
  ]
)
