import Foundation

struct Zshift {
  // Define constants for themes directory
  static let themesDir = "~/.oh-my-zsh/themes/"

  static let defaultExcludedDir = "~/Code/configs/excluded_zsh_themes.txt"

  /// Function to expand "~" in file paths
  ///
  /// Alternate version
  ///     guard let range = path.range(of: "~") else {
  ///    return path
  ///  }
  ///  return "\(NSHomeDirectory())\(path.replacingCharacters(in: range, with: ""))"
  static func expandPath(_ path: String) -> String {
    NSString(string: path).expandingTildeInPath
  }

  // Load excluded themes from file
  static func loadExcludedThemes(from path: String) -> [String] {
    var excludedThemes: [String] = []
    if let contents = try? String(contentsOfFile: expandPath(path), encoding: .utf8) {
      excludedThemes = contents.components(separatedBy: "\n")
    } else {
      print("\(path) Error: \(path) not found")
    }
    return excludedThemes
  }

  // Get the list of available themes and exclude the ones specified in the file
  static func getAvailableThemes(excludedThemes: [String]) -> [String] {
    // Get the list of all available ZSH themes.
    guard let allThemes = try? FileManager.default.contentsOfDirectory(atPath: Self.expandPath(themesDir)) else {
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

    // print("Error: Please provide the path to the excluded themes file as an argument.")
    let excludedThemes = loadExcludedThemes(from: excludedThemesPath)
    let availableThemes = getAvailableThemes(excludedThemes: excludedThemes)
    if let selectedTheme = getRandomTheme(from: availableThemes) {
      printSelectedTheme(selectedTheme)
    }

    // Alternative
    // Construct the command to set the ZSH theme.
    // let zshCommand =
    //  "zsh -c 'ZSH_THEME=\(randomTheme.replacingOccurrences(of: ".zsh-theme", with: "")) && source ~/.zshrc'"

    // Execute the command.
    // let task = Process()
    // task.launchPath = "/bin/bash"
    // task.arguments = ["-c", zshCommand]
    // task.launch()
    // task.waitUntilExit()
  }
}
