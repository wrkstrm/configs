import ArgumentParser
import CommonShell
import Foundation
import SwiftFigletKit

@main
struct ZShift: AsyncParsableCommand {
  static let configuration: CommandConfiguration = .init(
    commandName: "zshift",
    abstract: "🖨️ | Hides and promotes zsh themes.",
    shouldDisplay: false,
    subcommands: [
      Random.self, Like.self, Exclude.self, List.self, Config.self,
      LinkZshrc.self, Doctor.self,
    ],
    defaultSubcommand: Random.self,
    helpNames: .shortAndLong,
  )

  /// Function to expand "~" in file paths
  ///
  /// Alternate version
  ///  guard let range = path.range(of: "~") else {
  ///    return path
  ///  }
  /// return "\(NSHomeDirectory())\(path.replacingCharacters(in: range, with: ""))"
  static func expandTilde(in path: String) -> String {
    NSString(string: path).expandingTildeInPath
  }

  /// Define constants for themes directory
  static let themesDir = "~/.oh-my-zsh/themes/"

  /// Directory where the current executable resides.
  static var executableDirectory: URL {
    // Prefer Bundle.main first; fallback to CommandLine path.
    let mainURL = Bundle.main.bundleURL
    if FileManager.default.fileExists(atPath: mainURL.path) {
      return mainURL.deletingLastPathComponent()
    }
    let argv0 = URL(fileURLWithPath: CommandLine.arguments.first ?? ".")
    return argv0.deletingLastPathComponent()
  }

  /// Try to open the Zshift resource bundle placed next to the executable.
  static func zshiftResourceBundle() -> Bundle? {
    let candidate = executableDirectory.appendingPathComponent(
      "zshift_Zshift.bundle"
    )
    return Bundle(url: candidate)
  }

  /// Locate a resource URL. Try Bundle.module (dev + installed), then adjacent bundle,
  /// then a dev path relative to this source file.
  static func resourceURL(named name: String, withExtension ext: String) -> URL? {
    // 1) SwiftPM resource bundle (works in dev and when installed)
    #if SWIFT_PACKAGE
    if let url = Bundle.module.url(forResource: name, withExtension: ext) {
      return url
    }
    #endif

    // 2) Adjacent runtime bundle (installed layout)
    if let bundle = zshiftResourceBundle(),
      let url = bundle.url(forResource: name, withExtension: ext)
    {
      return url
    }

    // 3) Development layout via file path relative to this source file
    let devURL = URL(fileURLWithPath: #file)
      .deletingLastPathComponent()
      .appendingPathComponent("Resources")
      .appendingPathComponent("\(name).\(ext)")
    if FileManager.default.fileExists(atPath: devURL.path) {
      return devURL
    }
    return nil
  }

  /// Default directory while Bundle loading is fixed.
  static let defaultExcludedFile: String = {
    let fileURL = URL(fileURLWithPath: #file)
      .deletingLastPathComponent()
      .appendingPathComponent("Resources/excluded_zsh_themes.txt")
    return fileURL.path
  }()

  /// Default liked file while Bundle loading is fixed.
  static let defaultLikedFile: String = {
    let fileURL = URL(fileURLWithPath: #file)
      .deletingLastPathComponent()
      .appendingPathComponent("Resources/liked_zsh_themes.txt")
    return fileURL.path
  }()

  /// Load excluded themes from file, falling back to default resource if necessary
  /// NOTE: A fatal error if the file cannot be read.
  /// - Parameter path The path to the file containing the list of excluded themes.
  static func loadExcludedThemes(from path: String? = nil) -> [String] {
    let contents: String

    if let path {
      // Try to load from the provided path
      if let fileContents = try? String(
        contentsOfFile: expandTilde(in: path),
        encoding: .utf8
      ) {
        contents = fileContents
      } else {
        // If loading from path fails, try to load from the default resource
        if let url = resourceURL(
          named: "excluded_zsh_themes",
          withExtension: "txt"
        ),
          let defaultContents = try? String(contentsOf: url, encoding: .utf8)
        {
          contents = defaultContents
        } else {
          contents = ""
        }
      }
    } else {
      // If no path provided, load from the default resource
      if let url = resourceURL(
        named: "excluded_zsh_themes",
        withExtension: "txt"
      ),
        let defaultContents = try? String(contentsOf: url, encoding: .utf8)
      {
        contents = defaultContents
      } else {
        contents = ""
      }
    }

    let excludedThemes = contents.components(separatedBy: .newlines)
    return Set(excludedThemes.filter { !$0.isEmpty }).sorted()
  }

  /// Load excluded themes from file, falling back to default resource if necessary
  /// NOTE: An fatal error if the file cannot be read.
  /// - Parameter path The path to the file containing the list of excluded themes.
  static func loadLikedThemes(from path: String? = nil) -> [String] {
    let contents: String

    if let path {
      // Try to load from the provided path
      if let fileContents = try? String(
        contentsOfFile: expandTilde(in: path),
        encoding: .utf8
      ) {
        contents = fileContents
      } else {
        // If loading from path fails, try to load from the default resource
        if let url = resourceURL(
          named: "liked_zsh_themes",
          withExtension: "txt"
        ),
          let defaultContents = try? String(contentsOf: url, encoding: .utf8)
        {
          contents = defaultContents
        } else {
          contents = ""
        }
      }
    } else {
      // If no path provided, load from the default resource
      if let url = resourceURL(named: "liked_zsh_themes", withExtension: "txt"),
        let defaultContents = try? String(contentsOf: url, encoding: .utf8)
      {
        contents = defaultContents
      } else {
        contents = ""
      }
    }
    let likedThemes: [String] = contents.components(separatedBy: .newlines)
    return Set(likedThemes.filter { !$0.isEmpty }).sorted()
  }

  static func append(theme: String, to path: String) throws {
    let expandedPath: String = Self.expandTilde(in: path)
    let themeToAppend: String = theme + "\n"

    if let fileHandle = FileHandle(forWritingAtPath: expandedPath) {
      defer { fileHandle.closeFile() }
      fileHandle.seekToEndOfFile()
      fileHandle.write(themeToAppend.data(using: .utf8)!)
    } else {
      // If the file doesn't exist, create it
      try themeToAppend.write(
        toFile: expandedPath,
        atomically: true,
        encoding: .utf8
      )
    }
  }
}
