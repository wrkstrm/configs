import Foundation

@main
struct Zshift {

  // Function to expand "~" in file paths
  static func expandPath(_ path: String) -> String {
    NSString(string: path).expandingTildeInPath
  }

  static func main() {
  // Ask for the bad themes file path
  print("Enter the path to your bad themes file (e.g., ~/bad_zsh_themes.txt): ", terminator: "")
  guard let badThemesFile = readLine() else {
      fatalError("Failed to read file path")
  }

    guard let badThemesData = FileManager.default.contents(atPath: Self.expandPath(badThemesFile)),
      let badThemesString = String(data: badThemesData, encoding: .utf8)
    else {
      fatalError("Failed to load bad themes from \(badThemesFile)")
    }
    let badThemes = Set(badThemesString.components(separatedBy: "\n").filter { !$0.isEmpty })

    // Get the list of all available ZSH themes.
    let themesPath = "~/.oh-my-zsh/themes"  // Update if your themes are located elsewhere
    guard let allThemes = try? FileManager.default.contentsOfDirectory(atPath: Self.expandPath(themesPath)) else {
      fatalError("Failed to list themes at \(themesPath)")
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
