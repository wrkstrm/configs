// swift-tools-version:6.1
import Foundation
import PackageDescription

ConfigurationService.local.dependencies = [
  .package(name: "swift-figlet-kit", path: "../swift-figlet-kit/zshift")
]

ConfigurationService.remote.dependencies = [
  .package(url: "https://github.com/wrkstrm/SwiftFigletKit.git", from: "1.0.0")
]

let package = Package(
  name: "zshift",
  platforms: [
    .iOS(.v17),
    .macOS(.v15),
    .macCatalyst(.v15),
  ],
  products: [
    // Case sensitivy git error requires a lowercase `S`.
    .executable(name: "zshift", targets: ["Zshift"])
  ],
  dependencies: ConfigurationService.inject.dependencies + [
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      from: "1.6.0"
    ),
    .package(name: "CommonShell", path: "../../universal/common/domain/system/common-shell"),
  ],
  targets: [
    .executableTarget(
      name: "Zshift",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SwiftFigletKit", package: "swift-figlet-kit"),
        .product(name: "CommonShell", package: "CommonShell"),
      ],
      resources: [
        .process("Resources")  // This will copy all files in the Resources folder),
      ]
    ),
    .testTarget(
      name: "ZshiftTests",
      dependencies: ["Zshift"]
    ),
  ],
)

// MARK: - Configuration Service

@MainActor
public struct ConfigurationService {
  public static let version = "1.0.0"

  public var swiftSettings: [SwiftSetting] = []
  var dependencies: [PackageDescription.Package.Dependency] = []

  public static let inject: ConfigurationService =
    ProcessInfo.useLocalDeps ? .local : .remote

  static var local: ConfigurationService = .init(swiftSettings: [.local])

  static var remote: ConfigurationService = .init()
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let local: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Foundation extensions

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] == "true"
  }
}

// CONFIG_SERVICE_END_V1_HASH:{{CONFIG_HASH}}
