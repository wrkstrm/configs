import Foundation

// Main function

enum Zshift {
  // Define constants for themes directory
  static let themesDir = "~/.oh-my-zsh/themes/"

  static let defaultExcludedDir = "~/Code/configs/excluded_zsh_themes.txt"

  /// Expand tilde in paths to get absolute paths
  /// Alternate version
  ///     guard let range = path.range(of: "~") else {
  ///    return path
  ///  }
  ///  return "\(NSHomeDirectory())\(path.replacingCharacters(in: range, with: ""))"
  static func expandTilde(in path: String) -> String {
    guard let range = path.range(of: "~") else {
      return path
    }
    return "\(NSHomeDirectory())\(path.replacingCharacters(in: range, with: ""))"
  }

  // Load excluded themes from file
  static func loadExcludedThemes(from path: String) -> [String] {
    var excludedThemes: [String] = []
    if let contents = try? String(contentsOfFile: expandTilde(in: path), encoding: .utf8) {
      excludedThemes = contents.components(separatedBy: "\n")
    } else {
      print("\(path) Error: \(path) not found")
    }
    return excludedThemes
  }

  // Get the list of available themes and exclude the ones specified in the file
  static func getAvailableThemes(excludedThemes: [String]) -> [String] {
    var themes: [String] = []
    let themeFiles = try? FileManager.default.contentsOfDirectory(
      atPath: expandTilde(in: themesDir))
    if let themeFiles = themeFiles {
      for themeFile in themeFiles
      where !excludedThemes.contains(themeFile) && themeFile.hasSuffix(".zsh-theme") {
        themes.append(expandTilde(in: "\(Self.themesDir)\(themeFile)"))
      }
    } else {
      print("Error: \(Self.themesDir) not found")
    }
    return themes
  }

  // Randomly select a theme from the list of available ones
  static func getRandomTheme(from themes: [String]) -> String? {
    themes.randomElement()?.components(separatedBy: "/").last?.replacingOccurrences(
      of: ".zsh-theme", with: "")
  }

  // Print out the path to the selected theme in zsh-compatible format
  static func printSelectedTheme(_ theme: String?) {
    if let selectedTheme = theme {
      print("ZSH_THEME=\(selectedTheme.replacingOccurrences(of: "~", with: "$HOME"))")
    } else {
      print("Error: No themes available")
    }
  }

  static func main() {
    guard CommandLine.arguments.count < 3 else {
      print("\(CommandLine.arguments) Too many arguments.")
      return
    }
    let excludedThemesPath: String
    if CommandLine.arguments.count == 2 {
      excludedThemesPath = CommandLine.arguments.last!
    } else {
      // Check the current directory for the default.
      excludedThemesPath = Self.defaultExcludedDir
    }

    // print("Error: Please provide the path to the excluded themes file as an argument.")

    let excludedThemes = loadExcludedThemes(from: excludedThemesPath)
    let availableThemes = getAvailableThemes(excludedThemes: excludedThemes)
    if let selectedTheme = getRandomTheme(from: availableThemes) {
      printSelectedTheme(selectedTheme)
    }
  }
}

Zshift.main()
