import ArgumentParser
import Foundation
import SwiftFigletKit

@main
struct ZShift: AsyncParsableCommand {
  static let configuration: CommandConfiguration = .init(
    commandName: "zshift",
    abstract: "🖨️ | Hides and promotes zsh themes.",
    shouldDisplay: false,
    subcommands: [Random.self, Like.self, Exclude.self, LinkZshrc.self],
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
  /// NOTE: An fatal error if the file cannot be read.
  /// - Parameter path The path to the file containing the list of excluded themes.
  static func loadExcludedThemes(from path: String? = nil) -> [String] {
    let contents: String

    if let path {
      // Try to load from the provided path
      if let fileContents = try? String(contentsOfFile: expandTilde(in: path), encoding: .utf8) {
        contents = fileContents
      } else {
        // If loading from path fails, try to load from the default resource
        guard let url = Bundle.module.url(forResource: "excluded_zsh_themes", withExtension: "txt"),
          let defaultContents = try? String(contentsOf: url, encoding: .utf8)
        else {
          fatalError("Failed to load excluded themes from path and default resource")
        }
        contents = defaultContents
      }
    } else {
      // If no path provided, load from the default resource
      guard let url = Bundle.module.url(forResource: "excluded_zsh_themes", withExtension: "txt"),
        let defaultContents = try? String(contentsOf: url, encoding: .utf8)
      else {
        fatalError("Failed to load excluded themes from default resource")
      }
      contents = defaultContents
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
      if let fileContents = try? String(contentsOfFile: expandTilde(in: path), encoding: .utf8) {
        contents = fileContents
      } else {
        // If loading from path fails, try to load from the default resource
        guard let url = Bundle.module.url(forResource: "liked_zsh_themes", withExtension: "txt"),
          let defaultContents = try? String(contentsOf: url, encoding: .utf8)
        else {
          fatalError("Failed to load excluded themes from path and default resource")
        }
        contents = defaultContents
      }
    } else {
      // If no path provided, load from the default resource
      guard let url = Bundle.module.url(forResource: "liked_zsh_themes", withExtension: "txt"),
        let defaultContents = try? String(contentsOf: url, encoding: .utf8)
      else {
        print("Failed to load liked themes from default resource, returning empty array.")
        return []
      }
      contents = defaultContents
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
      try themeToAppend.write(toFile: expandedPath, atomically: true, encoding: .utf8)
    }
  }
}

struct Random: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Like a zsh theme",
    helpNames: .shortAndLong,
  )

  /// Get the list of available themes and exclude the ones specified in the file
  static func getAvailableThemes(excludedThemes: [String]) -> [String] {
    // Get the list of all available ZSH themes.
    guard
      let allThemes = try? FileManager.default.contentsOfDirectory(
        atPath: ZShift.expandTilde(in: ZShift.themesDir))
    else {
      fatalError("Failed to list themes at \(ZShift.themesDir)")
    }
    // Filter out the bad themes.
    return ["random"]
      + allThemes.filter {
        !excludedThemes.contains($0.replacingOccurrences(of: ".zsh-theme", with: ""))
      }
  }

  /// Randomly select a theme from the list of available ones
  static func getRandomTheme(from themes: [String]) -> String? {
    themes.randomElement()?.components(separatedBy: "/").last?.replacingOccurrences(
      of: ".zsh-theme", with: "",
    )
  }

  /// Print out the path to the selected theme in zsh-compatible format
  static func printSelectedTheme(_ theme: String) {
    if let font = SFKFont.random() {
      print(string: "ZShift - " + theme, usingFont: font)
    } else {
      print("ERROR: Unable to find Font file resource in bundle.")
    }
    print("ZSH_THEME=\(theme)")
  }

  /// Read input
  static func readInput() -> String {
    print(
      "Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ", terminator: "",
    )
    guard let excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }
    return excludedThemesPath
  }

  func run() async throws {
    /// For the script version just load the default
    var excludedThemesPath = ""

    // Maybe add as a resource?
    if excludedThemesPath.isEmpty {
      excludedThemesPath = ZShift.defaultExcludedFile
    }

    // Load liked themes.
    let likedThemes: [String] = ZShift.loadLikedThemes(from: ZShift.defaultLikedFile)
    // Load liked themes.
    let excludedThemes: [String] = ZShift.loadExcludedThemes(from: excludedThemesPath)
    // Filter out the seen themes.
    var goodThemes: [String] = Self.getAvailableThemes(excludedThemes: excludedThemes + likedThemes)
    if goodThemes.isEmpty {
      goodThemes = likedThemes
    }
    // Choose a random good theme.
    guard let randomTheme = Self.getRandomTheme(from: goodThemes) else {
      fatalError("Random theme not there.")
    }

    Self.printSelectedTheme(randomTheme)
  }
}

struct Like: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Like a zsh theme", helpNames: .shortAndLong,
  )

  @Argument(help: "The theme to like.")
  var likedTheme: String

  /// Read input
  static func readInput() -> String {
    print(
      "Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ", terminator: "",
    )
    guard let excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }
    return excludedThemesPath
  }

  mutating func run() async throws {
    // Load excluded themes.
    let likedThemes = ZShift.loadLikedThemes(from: ZShift.defaultLikedFile)

    // Check if the theme is already liked
    guard !likedThemes.contains(likedTheme) else {
      print("Theme '\(likedTheme)' is already in your liked themes.")
      return
    }
    // Append the new liked theme
    do {
      try ZShift.append(theme: likedTheme, to: ZShift.defaultLikedFile)
    } catch {
      fatalError("Could not save '\(likedTheme)'.")
    }

    print("Theme '\(likedTheme)' has been added to your liked themes.")
  }
}

struct Exclude: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Exclude a zsh theme", helpNames: .shortAndLong,
  )

  @Argument(help: "The theme to exclude.")
  var excludeTheme: String

  mutating func run() async throws {
    // Load excluded themes.
    let excludedThemes = ZShift.loadExcludedThemes(from: ZShift.defaultExcludedFile)

    // Check if the theme is already liked
    guard !excludedThemes.contains(excludeTheme) else {
      print("Theme '\(excludeTheme)' is already in your excluded themes.")
      return
    }
    // Append the new excluded theme
    do {
      try ZShift.append(theme: excludeTheme, to: ZShift.defaultExcludedFile)
    } catch {
      fatalError("Could not exclude '\(excludeTheme)'.")
    }

    print("Theme '\(excludeTheme)' has been added to your excluded themes.")
  }
}

struct LinkZshrc: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "link-zshrc",
    abstract: "A utility to manage zsh configuration.",
  )

  @Option(name: .long, help: "Path to a custom .zshrc file to use instead of the bundled one.")
  var customZshrcPath: String?

  @Flag(name: .long, help: "Backup the existing .zshrc file before overwriting.")
  var backup = false

  func run() async throws {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser
    let userZshrcPath = homeDir.appendingPathComponent(".zshrc")

    print("DEBUG: User .zshrc path: \(userZshrcPath.path)")

    // Backup existing .zshrc if requested
    if backup, FileManager.default.fileExists(atPath: userZshrcPath.path) {
      let backupPath = userZshrcPath.appendingPathExtension("backup")
      try FileManager.default.copyItem(at: userZshrcPath, to: backupPath)
      print("INFO: Existing .zshrc backed up to \(backupPath.path)")
    }
    let zshrcContents: String
    do {
      if let customPath = customZshrcPath {
        let expandedPath = ZShift.expandTilde(in: customPath)
        print("DEBUG: Using custom .zshrc at: \(expandedPath)")
        zshrcContents = try String(contentsOfFile: expandedPath, encoding: .utf8)
      } else {
        print("DEBUG: Attempting to load .zshrc from bundle")
        guard let sharedZshrcPath = Bundle.module.url(forResource: "zshrc", withExtension: "txt")
        else {
          print("ERROR: Unable to find zshrc.txt resource in bundle.")
          throw ExitCode.failure
        }
        zshrcContents = try String(contentsOf: sharedZshrcPath, encoding: .utf8)
        print("DEBUG: Found zshrc.txt at: \(sharedZshrcPath.path)")
      }
    } catch {
      print("ERROR: Failed to load .zshrc: \(error)")
      print("DEBUG: Current working directory: \(FileManager.default.currentDirectoryPath)")
      print("DEBUG: Bundle.module.bundleURL: \(Bundle.module.bundleURL)")
      print(
        "DEBUG: Bundle.module.resourceURL: \(Bundle.module.resourceURL ?? URL(fileURLWithPath: ""))",
      )
      throw ExitCode.failure
    }

    let marker = "# >>> zshift config >>>"
    let endMarker = "# <<< zshift config <<<"
    let contentsToAppend = "\n\(marker)\n\(zshrcContents)\n\(endMarker)\n"

    if let existing = try? String(contentsOf: userZshrcPath, encoding: .utf8),
      existing.contains(marker)
    {
      print("INFO: .zshrc already contains zshift config; skipping append.")
    } else {
      if FileManager.default.fileExists(atPath: userZshrcPath.path),
        let fileHandle = FileHandle(forWritingAtPath: userZshrcPath.path)
      {
        fileHandle.seekToEndOfFile()
        fileHandle.write(contentsToAppend.data(using: .utf8)!)
        fileHandle.closeFile()
      } else {
        try contentsToAppend.write(to: userZshrcPath, atomically: true, encoding: .utf8)
      }
      print("SUCCESS: .zshrc file has been updated.")
    }
  }
}
