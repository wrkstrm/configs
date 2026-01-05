import ArgumentParser
import Foundation
import SwiftFigletKit

struct Random: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Load a zsh theme",
    helpNames: .shortAndLong
  )

  @Option(name: .long, help: "Path to excluded themes list.")
  var excludedPath: String?

  @Option(name: .long, help: "Path to liked themes list.")
  var likedPath: String?

  @Option(
    name: [.customLong("excluded-fonts-path")],
    help: "Path to excluded FIGlet fonts list."
  )
  var excludedFontsPath: String?

  @Option(
    name: [.customLong("liked-fonts-path")],
    help: "Path to liked FIGlet fonts list."
  )
  var likedFontsPath: String?

  @Option(name: .long, help: "Directory containing .zsh-theme files.")
  var themesDir: String?

  @Option(
    name: .long,
    help:
      "Output format for the selected theme and FIGlet font. Choices: \(EmitFormat.allCases.map { $0.rawValue }.joined(separator: ", "))"
  )
  var emit: EmitFormat = .bare

  /// Get the list of available themes and exclude the ones specified in the file
  static func getAvailableThemes(excludedThemes: [String], themesDir: String)
    -> [String]
  {
    guard
      let allThemes = try? FileManager.default.contentsOfDirectory(
        atPath: ZShift.expandTilde(in: themesDir)
      )
    else {
      fatalError("Failed to list themes at \(themesDir)")
    }
    return ["random"]
      + allThemes.filter {
        $0.hasSuffix(".zsh-theme")
          && !excludedThemes.contains(
            $0.replacingOccurrences(of: ".zsh-theme", with: "")
          )
      }
  }

  /// Randomly select a theme from the list of available ones
  static func getRandomTheme(from themes: [String]) -> String? {
    themes.randomElement()?.components(separatedBy: "/").last?
      .replacingOccurrences(
        of: ".zsh-theme",
        with: ""
      )
  }

  static func chooseFigletFont(
    likedFonts: [String],
    excludedFonts: [String]
  ) -> String? {
    let allFonts = SFKFonts.listNames()
    guard !allFonts.isEmpty else { return nil }

    var canonicalMap: [String: String] = [:]
    for name in allFonts {
      let canonical = ZShiftConfig.canonicalFontName(name)
      if canonicalMap[canonical] == nil {
        canonicalMap[canonical] = name
      }
    }
    let excluded = Set(excludedFonts.map(ZShiftConfig.canonicalFontName))
    let liked = Set(likedFonts.map(ZShiftConfig.canonicalFontName))

    let freshPool = allFonts.filter {
      let canonical = ZShiftConfig.canonicalFontName($0)
      return !excluded.contains(canonical) && !liked.contains(canonical)
    }

    var candidates = freshPool
    if candidates.isEmpty {
      let likedMatches = liked.compactMap { canonicalMap[$0] }
      if !likedMatches.isEmpty {
        candidates = likedMatches
      } else {
        candidates = allFonts.filter {
          let canonical = ZShiftConfig.canonicalFontName($0)
          return !excluded.contains(canonical)
        }
      }
    }

    return candidates.randomElement()
  }

  enum EmitFormat: String, CaseIterable, ExpressibleByArgument {
    case bare, prefixed
  }

  /// Print out the selected theme along with optional FIGlet font metadata
  static func printSelectedTheme(_ theme: String, font: String?, emit: EmitFormat) {
    let banner: String
    if let font, !font.isEmpty {
      banner = SFKRenderer.render(
        text: "ZShift x " + theme,
        font: .named(font),
        color: .mixedRandom(),
        options: .init(newline: false)
      )
    } else {
      banner = SFKRenderer.renderRandomBanner(
        text: "ZShift x " + theme,
        options: .init(newline: false)
      )
    }
    if banner.hasSuffix("\n") {
      Swift.print(banner, terminator: "")
    } else {
      Swift.print(banner)
    }
    let fontValue = font?.isEmpty == false ? font! : "random"
    let canonicalFont =
      fontValue == "random"
      ? "random"
      : ZShiftConfig.canonicalFontName(fontValue)
    print("FIGLET_FONT=\(canonicalFont)")
    switch emit {
    case .bare:
      print(theme)

    case .prefixed:
      print("ZSH_THEME=\(theme)")
    }
  }

  /// Read input
  static func readInput() -> String {
    print(
      "Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ",
      terminator: ""
    )
    guard let excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }
    return excludedThemesPath
  }

  func run() async throws {
    let env = ProcessInfo.processInfo.environment
    let likedThemes: [String] = ZShiftConfig.loadList(
      kind: .liked,
      flag: likedPath,
      env: env
    )
    let excludedThemes: [String] = ZShiftConfig.loadList(
      kind: .excluded,
      flag: excludedPath,
      env: env
    )
    let likedFonts: [String] = ZShiftConfig.loadFontList(
      kind: .liked,
      flag: likedFontsPath,
      env: env
    )
    let excludedFonts: [String] = ZShiftConfig.loadFontList(
      kind: .excluded,
      flag: excludedFontsPath,
      env: env
    )
    guard
      let themesURL = ZShiftConfig.resolveThemesDir(flag: themesDir, env: env)?.url
    else {
      fatalError(
        "No themes directory found. Set --themes-dir or ZSH_THEMES_DIR, or install Oh My Zsh."
      )
    }
    var goodThemes: [String] = Self.getAvailableThemes(
      excludedThemes: excludedThemes + likedThemes,
      themesDir: themesURL.path
    )
    if goodThemes.isEmpty {
      goodThemes = likedThemes
    }
    guard let randomTheme = Self.getRandomTheme(from: goodThemes) else {
      fatalError("Random theme not there.")
    }
    let chosenFont = Self.chooseFigletFont(
      likedFonts: likedFonts,
      excludedFonts: excludedFonts
    )
    Self.printSelectedTheme(randomTheme, font: chosenFont, emit: emit)
  }
}
