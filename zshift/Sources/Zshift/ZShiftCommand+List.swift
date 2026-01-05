import ArgumentParser
import Foundation
import SwiftFigletKit

// MARK: - List

struct List: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List available, liked, or excluded themes or FIGlet fonts",
    helpNames: .shortAndLong
  )

  enum Category: String, ExpressibleByArgument, CaseIterable {
    case available, liked, excluded
    case availableFonts = "available-fonts"
    case likedFonts = "liked-fonts"
    case excludedFonts = "excluded-fonts"
  }

  @Argument(
    help:
      "What to list: \(Category.allCases.map { $0.rawValue }.joined(separator: ", "))"
  )
  var category: Category

  @Flag(name: .long, help: "Emit JSON output")
  var json = false

  @Option(name: .long) var excludedPath: String?
  @Option(name: .long) var likedPath: String?
  @Option(name: .long) var themesDir: String?
  @Option(name: [.customLong("excluded-fonts-path")]) var excludedFontsPath: String?
  @Option(name: [.customLong("liked-fonts-path")]) var likedFontsPath: String?

  func run() async throws {
    let env = ProcessInfo.processInfo.environment
    switch category {
    case .available:
      let likedThemes = ZShiftConfig.loadList(kind: .liked, flag: likedPath, env: env)
      let excludedThemes = ZShiftConfig.loadList(
        kind: .excluded,
        flag: excludedPath,
        env: env
      )
      guard
        let themesURL = ZShiftConfig.resolveThemesDir(
          flag: themesDir,
          env: env
        )?.url
      else {
        throw ExitCode.failure
      }
      let themes = Random.getAvailableThemes(
        excludedThemes: excludedThemes + likedThemes,
        themesDir: themesURL.path
      ).filter { $0 != "random" }
      if json {
        let data = try JSONEncoder().encode(themes)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        themes.forEach { print($0) }
      }

    case .liked:
      let list = ZShiftConfig.loadList(kind: .liked, flag: likedPath, env: env)
      if json {
        let data = try JSONEncoder().encode(list)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        list.forEach { print($0) }
      }

    case .excluded:
      let list = ZShiftConfig.loadList(
        kind: .excluded,
        flag: excludedPath,
        env: env
      )
      if json {
        let data = try JSONEncoder().encode(list)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        list.forEach { print($0) }
      }

    case .availableFonts:
      let likedFonts = ZShiftConfig.loadFontList(
        kind: .liked,
        flag: likedFontsPath,
        env: env
      )
      let excludedFonts = ZShiftConfig.loadFontList(
        kind: .excluded,
        flag: excludedFontsPath,
        env: env
      )
      let exclusions = Set((likedFonts + excludedFonts).map(ZShiftConfig.canonicalFontName))
      let fonts = SFKFonts.listNames().filter {
        !exclusions.contains(ZShiftConfig.canonicalFontName($0))
      }
      if json {
        let data = try JSONEncoder().encode(fonts)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        fonts.forEach { print($0) }
      }

    case .likedFonts:
      let fonts = ZShiftConfig.loadFontList(
        kind: .liked,
        flag: likedFontsPath,
        env: env
      )
      if json {
        let data = try JSONEncoder().encode(fonts)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        fonts.forEach { print($0) }
      }

    case .excludedFonts:
      let fonts = ZShiftConfig.loadFontList(
        kind: .excluded,
        flag: excludedFontsPath,
        env: env
      )
      if json {
        let data = try JSONEncoder().encode(fonts)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        fonts.forEach { print($0) }
      }
    }
  }
}
