import Foundation

@main
enum Zshift {
  /// Define constants for themes directory
  static let themesDir = "~/.oh-my-zsh/themes/"

  /// Default directory while Bundle loading is fixed.
  static let defaultExcludedDir = "~/Code/configs/zshift/Sources/zshift/Resources/excluded_zsh_themes.txt"

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

  /// Load excluded themes from file
  /// Load excluded themes from file, falling back to default resource if necessary
  static func loadExcludedThemes(from path: String? = nil) -> [String] {
      let contents: String
      
      if let path = path {
          // Try to load from the provided path
          if let fileContents = try? String(contentsOfFile: expandTilde(in: path), encoding: .utf8) {
              contents = fileContents
          } else {
              // If loading from path fails, try to load from the default resource
              guard let url = Bundle.module.url(forResource: "excluded_zsh_themes", withExtension: "txt"),
                    let defaultContents = try? String(contentsOf: url, encoding: .utf8) else {
                  fatalError("Failed to load excluded themes from path and default resource")
              }
              contents = defaultContents
          }
      } else {
          // If no path provided, load from the default resource
          guard let url = Bundle.module.url(forResource: "excluded_zsh_themes", withExtension: "txt"),
                let defaultContents = try? String(contentsOf: url, encoding: .utf8) else {
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
    guard let allThemes = try? FileManager.default.contentsOfDirectory(atPath: Self.expandTilde(in: themesDir)) else {
      fatalError("Failed to list themes at \(themesDir)")
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
    print("Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ", terminator: "")
    guard let excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }
    return excludedThemesPath
  }

  static func main() {
    /// For the script version just load the default
    var excludedThemesPath = ""

    // Maybe add as a resource?
    if excludedThemesPath.count == 0 {
      excludedThemesPath = defaultExcludedDir
    }

    // Load exlcuded themes.
    let excludedThemes = loadExcludedThemes(from: excludedThemesPath)
    // Filter out the bad themes.
    let goodThemes = getAvailableThemes(excludedThemes: excludedThemes)

    // Choose a random good theme.
    guard let randomTheme = getRandomTheme(from: goodThemes) else {
      fatalError("Random theme not there.")
    }

    printSelectedTheme(randomTheme)

    // Construct the command to set the ZSH theme.
    // let zshCommand =
    // "zsh -c 'ZSH_THEME=\(randomTheme.replacingOccurrences(of: ".zsh-theme", with: "")) && source ~/.zshrc'"

    // Execute the command.
    // let task = Process()
    // task.launchPath = "/bin/bash"
    // task.arguments = ["-c", zshCommand]
    // task.launch()
    // task.waitUntilExit()
    // print("Set ZSH theme to: \(randomTheme)")
  }
}
