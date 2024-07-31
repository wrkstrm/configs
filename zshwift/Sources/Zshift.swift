import Foundation

@main
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
  static func loadExcludedThemes(from path: String) -> Set<String> {
    if let contents = try? String(contentsOfFile: expandTilde(in: path), encoding: .utf8) {
      excludedThemes = contents.components(separatedBy: "\n")
    } else {
      fatalError("Failed to load bad themes from \(excludedThemesPath)")
    }
    return Set(excludedThemes.filter { !$0.isEmpty })
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

  static func main() {
  // Ask for the bad themes file path
  print("Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ", terminator: "")
  guard var excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
  }

  if excludedThemesPath.count == 0 {
    excludedThemesPath = defaultExcludedDir
  }

    let excludedThemes = loadExcludedThemes(from: excludedThemesPath)

    // Get the list of all available ZSH themes.
    guard let allThemes = try? FileManager.default.contentsOfDirectory(atPath: Self.expandPath(themesDir)) else {
      fatalError("Failed to list themes at \(themesDir)")
    }

    // Filter out the bad themes.
    let goodThemes = allThemes.filter {
      !excludedThemes.contains($0.replacingOccurrences(of: ".zsh-theme", with: ""))
    }

    // Choose a random good theme.
    guard let randomTheme = goodThemes.randomElement() else {
      fatalError("No good themes found!")
    }

    // Construct the command to set the ZSH theme.
    let zshCommand =
      "zsh -c 'ZSH_THEME=\(randomTheme.replacingOccurrences(of: ".zsh-theme", with: "")) && source ~/.zshrc'"

    // Execute the command.
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", zshCommand]
    task.launch()
    task.waitUntilExit()

    print("Set ZSH theme to: \(randomTheme)")
  }
}
