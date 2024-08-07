import ArgumentParser
import Figlet
import Foundation

@main
struct Zshift: AsyncParsableCommand {

  static let configuration: CommandConfiguration = {
    return CommandConfiguration(
      abstract: "🖨️ | Hides and promotes zsh themes.",
      shouldDisplay: false,
      subcommands: [Random.self, Like.self],
      defaultSubcommand: Random.self,
      helpNames: .shortAndLong)
  }()

  /// Define constants for themes directory
  static let themesDir = "~/.oh-my-zsh/themes/"

  /// Default directory while Bundle loading is fixed.
  static let defaultExcludedFile =
    "~/Code/configs/zshift/Sources/zshift/Resources/excluded_zsh_themes.txt"

  /// Default liked file while Bundle loading is fixed.
  static let defaultLikedFile =
    "~/Code/configs/zshift/Sources/zshift/Resources/liked_zsh_themes.txt"
}

struct Random: AsyncParsableCommand {

  static var configuration = CommandConfiguration(
    abstract: "Like a zsh theme",
    helpNames: .shortAndLong)

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

  /// Load excluded themes from file, falling back to default resource if necessary
  /// NOTE: An fatal error if the file cannot be read.
  /// - Parameter path The path to the file containing the list of excluded themes.
  static func loadExcludedThemes(from path: String? = nil) -> [String] {
    let contents: String

    if let path = path {
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

  /// Get the list of available themes and exclude the ones specified in the file
  static func getAvailableThemes(excludedThemes: [String]) -> [String] {
    // Get the list of all available ZSH themes.
    guard
      let allThemes = try? FileManager.default.contentsOfDirectory(
        atPath: Self.expandTilde(in: Zshift.themesDir))
    else {
      fatalError("Failed to list themes at \(Zshift.themesDir)")
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
      of: ".zsh-theme", with: "")
  }

  /// Print out the path to the selected theme in zsh-compatible format
  static func printSelectedTheme(_ theme: String) {
    Figlet.say("Zshift - " + theme)
    print("ZSH_THEME=\(theme)")
  }

  /// Read input
  static func readInput() -> String {
    print(
      "Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ", terminator: "")
    guard let excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }
    return excludedThemesPath
  }

  func run() async throws {
    /// For the script version just load the default
    var excludedThemesPath = ""

    // Maybe add as a resource?
    if excludedThemesPath.count == 0 {
      excludedThemesPath = Zshift.defaultExcludedFile
    }

    // Load excluded themes.
    let likedThemes = Self.loadExcludedThemes(from: Zshift.defaultLikedFile)
    // Load liked themes.
    let excludedThemes = Self.loadExcludedThemes(from: excludedThemesPath)
    // Filter out the seen themes.
    var goodThemes = Self.getAvailableThemes(excludedThemes: excludedThemes + likedThemes)
    if goodThemes.count == 0 {
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
  static var configuration = CommandConfiguration(
    abstract: "Like a zsh theme", helpNames: .shortAndLong)

  @Argument(help: "The theme to like.")
  var likedTheme: String

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

  /// Load excluded themes from file, falling back to default resource if necessary
  /// NOTE: An fatal error if the file cannot be read.
  /// - Parameter path The path to the file containing the list of excluded themes.
  static func loadLikedThemes(from path: String? = nil) -> [String] {
    let contents: String

    if let path = path {
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

    let excludedThemes = contents.components(separatedBy: .newlines)
    return Set(excludedThemes.filter { !$0.isEmpty }).sorted()
  }

  static func appendLikedTheme(_ theme: String, to path: String) throws {
    let expandedPath = expandTilde(in: path)
    let themeToAppend = theme + "\n"

    if let fileHandle = FileHandle(forWritingAtPath: expandedPath) {
      defer { fileHandle.closeFile() }
      fileHandle.seekToEndOfFile()
      fileHandle.write(themeToAppend.data(using: .utf8)!)
    } else {
      // If the file doesn't exist, create it
      try themeToAppend.write(toFile: expandedPath, atomically: true, encoding: .utf8)
    }
  }

  /// Get the list of available themes and exclude the ones specified in the file
  static func getAvailableThemes(excludedThemes: [String]) -> [String] {
    // Get the list of all available ZSH themes.
    guard
      let allThemes = try? FileManager.default.contentsOfDirectory(
        atPath: Self.expandTilde(in: Zshift.themesDir))
    else {
      fatalError("Failed to list themes at \(Zshift.themesDir)")
    }
    // Filter out the bad themes.
    return allThemes.filter {
      !excludedThemes.contains($0.replacingOccurrences(of: ".zsh-theme", with: ""))
    }
  }

  /// Randomly select a theme from the list of available ones
  static func getRandomTheme(from themes: [String]) -> String? {
    themes.randomElement()?.components(separatedBy: "/").last?.replacingOccurrences(
      of: ".zsh-theme", with: "")
  }

  /// Print out the path to the selected theme in zsh-compatible format
  static func printSelectedTheme(_ theme: String?) {
    if let selectedTheme = theme {
      print("ZSH_THEME=\(selectedTheme)")
    } else {
      print("Error: No themes available")
    }
  }

  /// Read input
  static func readInput() -> String {
    print(
      "Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ", terminator: "")
    guard let excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }
    return excludedThemesPath
  }

  mutating func run() async throws {
    // Load excluded themes.
    let likedThemes = Self.loadLikedThemes(from: Zshift.defaultLikedFile)

    // Check if the theme is already liked
    guard !likedThemes.contains(likedTheme) else {
      print("Theme '\(likedTheme)' is already in your liked themes.")
      return
    }
    // Append the new liked theme
    do {
      try Self.appendLikedTheme(likedTheme, to: Zshift.defaultLikedFile)
    } catch {
      fatalError("Could not save '\(likedTheme)'.")
    }

    print("Theme '\(likedTheme)' has been added to your liked themes.")

  }
}
