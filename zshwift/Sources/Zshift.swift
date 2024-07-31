import Foundation

@main
struct Zshift {
  // Define constants for themes directory
  static let themesDir = "~/.oh-my-zsh/themes/"

  static let defaultExcludedDir = "~/Code/configs/excluded_zsh_themes.txt"

  // Function to expand "~" in file paths
  static func expandPath(_ path: String) -> String {
    NSString(string: path).expandingTildeInPath
  }

  static func main() {
  // Ask for the bad themes file path
  print("Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ", terminator: "")
  guard var badThemesFile = readLine() else {
      fatalError("Failed to read file path")
  }

  if badThemesFile.count == 0 {
    badThemesFile = defaultExcludedDir
  }

    guard let badThemesData = FileManager.default.contents(atPath: Self.expandPath(badThemesFile)),
      let badThemesString = String(data: badThemesData, encoding: .utf8)
    else {
      fatalError("Failed to load bad themes from \(badThemesFile)")
    }
    let badThemes = Set(badThemesString.components(separatedBy: "\n").filter { !$0.isEmpty })

    // Get the list of all available ZSH themes.
    guard let allThemes = try? FileManager.default.contentsOfDirectory(atPath: Self.expandPath(themesDir)) else {
      fatalError("Failed to list themes at \(themesDir)")
    }

    // Filter out the bad themes.
    let goodThemes = allThemes.filter {
      !badThemes.contains($0.replacingOccurrences(of: ".zsh-theme", with: ""))
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
