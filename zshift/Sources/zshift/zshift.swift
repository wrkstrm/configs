import Foundation

@main
enum Zshift {
  // Define constants for themes directory
  static let themesDir = "~/.oh-my-zsh/themes/"

  static let defaultExcludedDir = "~/Code/configs/excluded_zsh_themes.txt"

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
  static func loadExcludedThemes(from path: String) -> [String] {
    guard let contents = try? String(contentsOfFile: expandTilde(in: path), encoding: .utf8) else {
      fatalError("Failed to load bad themes from \(path)")
    }
    let excludedThemes = contents.components(separatedBy: "\n")
    // Probably make a Set to dedupe. Set(excludedThemes.filter { !$0.isEmpty })
    return excludedThemes.filter { !$0.isEmpty }
  }

  // Get the list of available themes and exclude the ones specified in the file
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
    // Ask for the bad themes file path
    print("Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ", terminator: "")
    guard var excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }

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
    printSelectedTheme(selectedTheme)

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
