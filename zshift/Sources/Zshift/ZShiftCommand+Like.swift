import ArgumentParser
import Foundation

struct Like: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Like a zsh theme or FIGlet font",
    helpNames: .shortAndLong
  )

  @Argument(help: "Name of the theme or FIGlet font to like.")
  var name: String

  @Option(
    name: .long,
    help: "Whether to operate on theme or FIGlet font preferences."
  )
  var kind: ZShiftPreferenceKind = .theme

  @Option(name: .long, help: "Path to liked themes list.")
  var likedPath: String?

  @Option(
    name: [.customLong("liked-fonts-path")],
    help: "Path to liked FIGlet fonts list."
  )
  var likedFontsPath: String?

  mutating func run() async throws {
    let env = ProcessInfo.processInfo.environment
    switch kind {
    case .theme:
      let likedThemes = ZShiftConfig.loadList(
        kind: .liked,
        flag: likedPath,
        env: env
      )
      let (destination, _) = ZShiftConfig.resolveListPath(
        kind: .liked,
        flag: likedPath,
        env: env
      )
      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      guard !likedThemes.contains(name) else {
        print("Theme '\(name)' is already in your liked themes.")
        return
      }
      try ZShift.append(theme: name, to: destination.path)
      print("Theme '\(name)' has been added to your liked themes.")

    case .font:
      let likedFonts = ZShiftConfig.loadFontList(
        kind: .liked,
        flag: likedFontsPath,
        env: env
      )
      let canonicalExisting = Set(likedFonts.map(ZShiftConfig.canonicalFontName))
      let candidate = ZShiftConfig.canonicalFontName(name)
      guard !canonicalExisting.contains(candidate) else {
        print("FIGlet font '\(candidate)' is already in your liked fonts.")
        return
      }
      let (destination, _) = ZShiftConfig.resolveFontListPath(
        kind: .liked,
        flag: likedFontsPath,
        env: env
      )
      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try ZShift.append(theme: candidate, to: destination.path)
      print("FIGlet font '\(candidate)' has been added to your liked fonts.")
    }
  }
}
