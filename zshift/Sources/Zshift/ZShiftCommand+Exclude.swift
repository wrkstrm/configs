import ArgumentParser
import Foundation

struct Exclude: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Exclude a zsh theme or FIGlet font",
    helpNames: .shortAndLong
  )

  @Argument(help: "Name of the theme or FIGlet font to exclude.")
  var name: String

  @Option(
    name: .long,
    help: "Whether to operate on theme or FIGlet font preferences."
  )
  var kind: ZShiftPreferenceKind = .theme

  @Option(name: .long, help: "Path to excluded themes list.")
  var excludedPath: String?

  @Option(
    name: [.customLong("excluded-fonts-path")],
    help: "Path to excluded FIGlet fonts list."
  )
  var excludedFontsPath: String?

  mutating func run() async throws {
    let env = ProcessInfo.processInfo.environment
    switch kind {
    case .theme:
      let excludedThemes = ZShiftConfig.loadList(
        kind: .excluded,
        flag: excludedPath,
        env: env
      )
      guard !excludedThemes.contains(name) else {
        print("Theme '\(name)' is already in your excluded themes.")
        return
      }
      let (destination, _) = ZShiftConfig.resolveListPath(
        kind: .excluded,
        flag: excludedPath,
        env: env
      )
      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try ZShift.append(theme: name, to: destination.path)
      print("Theme '\(name)' has been added to your excluded themes.")

    case .font:
      let excludedFonts = ZShiftConfig.loadFontList(
        kind: .excluded,
        flag: excludedFontsPath,
        env: env
      )
      let canonicalExisting = Set(excludedFonts.map(ZShiftConfig.canonicalFontName))
      let candidate = ZShiftConfig.canonicalFontName(name)
      guard !canonicalExisting.contains(candidate) else {
        print("FIGlet font '\(candidate)' is already in your excluded fonts.")
        return
      }
      let (destination, _) = ZShiftConfig.resolveFontListPath(
        kind: .excluded,
        flag: excludedFontsPath,
        env: env
      )
      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try ZShift.append(theme: candidate, to: destination.path)
      print("FIGlet font '\(candidate)' has been added to your excluded fonts.")
    }
  }
}
