import ArgumentParser
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

// MARK: - Configuration resolution

struct ZShiftConfig {
  enum Kind { case excluded, liked }
  enum Source: String { case flag, env, xdg, bundle, probe, empty }

  static func expand(_ path: String) -> String { ZShift.expandTilde(in: path) }

  static func resolveConfigDir(
    env: [String: String] = ProcessInfo.processInfo.environment
  ) -> URL {
    let fm = FileManager.default
    if let custom = env["ZSHIFT_CONFIG_HOME"], !custom.isEmpty {
      return URL(fileURLWithPath: expand(custom), isDirectory: true)
    }
    if let xdg = env["XDG_CONFIG_HOME"], !xdg.isEmpty {
      return URL(fileURLWithPath: expand(xdg), isDirectory: true)
    }
    let home = fm.homeDirectoryForCurrentUser
    return home.appendingPathComponent(".config", isDirectory: true)
  }

  static func resolveListPath(
    kind: Kind,
    flag: String?,
    env: [String: String] = ProcessInfo.processInfo.environment
  ) -> (url: URL, source: Source) {
    if let flag, !flag.isEmpty {
      return (URL(fileURLWithPath: expand(flag)), .flag)
    }
    switch kind {
    case .excluded:
      if let p = env["ZSHIFT_EXCLUDED"], !p.isEmpty {
        return (URL(fileURLWithPath: expand(p)), .env)
      }
    case .liked:
      if let p = env["ZSHIFT_LIKED"], !p.isEmpty {
        return (URL(fileURLWithPath: expand(p)), .env)
      }
    }
    let base = resolveConfigDir(env: env).appendingPathComponent(
      "zshift",
      isDirectory: true
    )
    let file = (kind == .excluded) ? "excluded.txt" : "liked.txt"
    return (base.appendingPathComponent(file), .xdg)
  }

  static func loadList(
    kind: Kind,
    flag: String?,
    env: [String: String] = ProcessInfo.processInfo.environment
  ) -> [String] {
    let (url, _) = resolveListPath(kind: kind, flag: flag, env: env)
    let fm = FileManager.default
    let contents: String
    if fm.fileExists(atPath: url.path),
      let text = try? String(contentsOf: url, encoding: .utf8)
    {
      contents = text
    } else {
      // Fallback to bundled team defaults
      let name =
        (kind == .excluded) ? "excluded_zsh_themes" : "liked_zsh_themes"
      if let res = ZShift.resourceURL(named: name, withExtension: "txt"),
        let text = try? String(contentsOf: res, encoding: .utf8)
      {
        contents = text
      } else {
        contents = ""
      }
    }
    return Set(
      contents.components(separatedBy: .newlines).filter { !$0.isEmpty }
    ).sorted()
  }

  static func resolveThemesDir(
    flag: String?,
    env: [String: String] = ProcessInfo.processInfo.environment
  ) -> (url: URL, source: Source)? {
    let fm = FileManager.default
    if let flag, !flag.isEmpty {
      let u = URL(fileURLWithPath: expand(flag), isDirectory: true)
      return (u, .flag)
    }
    if let p = env["ZSH_THEMES_DIR"], !p.isEmpty {
      return (URL(fileURLWithPath: expand(p), isDirectory: true), .env)
    }
    // Probe $ZSH/themes then ~/.oh-my-zsh/themes
    if let zsh = env["ZSH"], !zsh.isEmpty {
      let u = URL(fileURLWithPath: expand(zsh), isDirectory: true)
        .appendingPathComponent("themes", isDirectory: true)
      if fm.fileExists(atPath: u.path) { return (u, .probe) }
    }
    let u = URL(
      fileURLWithPath: ZShift.expandTilde(in: ZShift.themesDir),
      isDirectory: true
    )
    if fm.fileExists(atPath: u.path) { return (u, .probe) }
    return nil
  }
}

struct Random: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Load a zsh theme",
    helpNames: .shortAndLong,
  )

  @Option(name: .long, help: "Path to excluded themes list.")
  var excludedPath: String?

  @Option(name: .long, help: "Path to liked themes list.")
  var likedPath: String?

  @Option(name: .long, help: "Directory containing .zsh-theme files.")
  var themesDir: String?

  @Option(
    name: .long,
    help:
      "Output format for the selected theme. Choices: \(EmitFormat.allCases.map { $0.rawValue }.joined(separator: ", "))"
  )
  var emit: EmitFormat = .bare

  /// Get the list of available themes and exclude the ones specified in the file
  static func getAvailableThemes(excludedThemes: [String], themesDir: String)
    -> [String]
  {
    // Get the list of all available ZSH themes.
    guard
      let allThemes = try? FileManager.default.contentsOfDirectory(
        atPath: ZShift.expandTilde(in: themesDir)
      )
    else {
      fatalError("Failed to list themes at \(themesDir)")
    }
    // Filter out the bad themes.
    return ["random"]
      + allThemes.filter {
        $0.hasSuffix(".zsh-theme")
          && !excludedThemes.contains(
            $0.replacingOccurrences(of: ".zsh-theme", with: "")
          )
      }
  }

  /// Randomly select a theme from the list of available ones
  static func getRandomTheme(from themes: [String]) -> String? {
    themes.randomElement()?.components(separatedBy: "/").last?
      .replacingOccurrences(
        of: ".zsh-theme",
        with: "",
      )
  }

  enum EmitFormat: String, CaseIterable, ExpressibleByArgument {
    case bare, prefixed
  }

  /// Print out the path to the selected theme in zsh-compatible format
  static func printSelectedTheme(_ theme: String, emit: EmitFormat) {
    // Use SwiftFigletKit high-level random banner API; it handles fallbacks.
    let banner = SFKRenderer.renderRandomBanner(
      text: "ZShift x " + theme,
      options: .init(newline: false)
    )
    Swift.print(banner, terminator: "")
    // Print theme in requested format
    switch emit {
    case .bare:
      print(theme)
    case .prefixed:
      print("ZSH_THEME=\(theme)")
    }
  }

  /// Read input
  static func readInput() -> String {
    print(
      "Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ",
      terminator: "",
    )
    guard let excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }
    return excludedThemesPath
  }

  func run() async throws {
    let env = ProcessInfo.processInfo.environment
    // Resolve configuration
    let likedThemes: [String] = ZShiftConfig.loadList(
      kind: .liked,
      flag: likedPath,
      env: env
    )
    let excludedThemes: [String] = ZShiftConfig.loadList(
      kind: .excluded,
      flag: excludedPath,
      env: env
    )
    guard
      let themesURL = ZShiftConfig.resolveThemesDir(flag: themesDir, env: env)?
        .url
    else {
      fatalError(
        "No themes directory found. Set --themes-dir or ZSH_THEMES_DIR, or install Oh My Zsh."
      )
    }
    // Filter out the seen themes.
    var goodThemes: [String] = Self.getAvailableThemes(
      excludedThemes: excludedThemes + likedThemes,
      themesDir: themesURL.path
    )
    if goodThemes.isEmpty {
      goodThemes = likedThemes
    }
    // Choose a random good theme.
    guard let randomTheme = Self.getRandomTheme(from: goodThemes) else {
      fatalError("Random theme not there.")
    }

    Self.printSelectedTheme(randomTheme, emit: emit)
  }
}

struct Like: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Like a zsh theme",
    helpNames: .shortAndLong,
  )

  @Argument(help: "The theme to like.")
  var likedTheme: String

  @Option(name: .long, help: "Path to liked themes list.")
  var likedPath: String?

  /// Read input
  static func readInput() -> String {
    print(
      "Enter the path to your bad themes file (e.g., ~/excluded_zsh_themes.txt): ",
      terminator: "",
    )
    guard let excludedThemesPath = readLine() else {
      fatalError("Failed to read file path")
    }
    return excludedThemesPath
  }

  mutating func run() async throws {
    let env = ProcessInfo.processInfo.environment
    // Load current liked (effective)
    let likedThemes = ZShiftConfig.loadList(
      kind: .liked,
      flag: likedPath,
      env: env
    )
    let (destURL, _) = ZShiftConfig.resolveListPath(
      kind: .liked,
      flag: likedPath,
      env: env
    )
    // Ensure parent directory exists
    try FileManager.default.createDirectory(
      at: destURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    // Check if the theme is already liked
    guard !likedThemes.contains(likedTheme) else {
      print("Theme '\(likedTheme)' is already in your liked themes.")
      return
    }
    // Append the new liked theme
    do {
      try ZShift.append(theme: likedTheme, to: destURL.path)
    } catch {
      fatalError("Could not save '\(likedTheme)'.")
    }

    print("Theme '\(likedTheme)' has been added to your liked themes.")
  }
}

struct Exclude: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Exclude a zsh theme",
    helpNames: .shortAndLong,
  )

  @Argument(help: "The theme to exclude.")
  var excludeTheme: String

  @Option(name: .long, help: "Path to excluded themes list.")
  var excludedPath: String?

  mutating func run() async throws {
    let env = ProcessInfo.processInfo.environment
    // Load current excluded (effective)
    let excludedThemes = ZShiftConfig.loadList(
      kind: .excluded,
      flag: excludedPath,
      env: env
    )
    let (destURL, _) = ZShiftConfig.resolveListPath(
      kind: .excluded,
      flag: excludedPath,
      env: env
    )
    // Ensure parent directory exists
    try FileManager.default.createDirectory(
      at: destURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    // Check if the theme is already liked
    guard !excludedThemes.contains(excludeTheme) else {
      print("Theme '\(excludeTheme)' is already in your excluded themes.")
      return
    }
    // Append the new excluded theme
    do {
      try ZShift.append(theme: excludeTheme, to: destURL.path)
    } catch {
      fatalError("Could not exclude '\(excludeTheme)'.")
    }

    print("Theme '\(excludeTheme)' has been added to your excluded themes.")
  }
}

#if os(macOS) || os(Linux)
struct LinkZshrc: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "link-zshrc",
    abstract: "A utility to manage zsh configuration.",
  )

  @Option(
    name: .long,
    help: "Path to a custom .zshrc file to use instead of the bundled one."
  )
  var customZshrcPath: String?

  @Flag(
    name: .long,
    help: "Backup the existing .zshrc file before overwriting."
  )
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
      if let customPath = customZshrcPath
        ?? ProcessInfo.processInfo.environment["ZSHIFT_ZSHRC_TEMPLATE"]
      {
        let expandedPath = ZShift.expandTilde(in: customPath)
        print("DEBUG: Using custom .zshrc at: \(expandedPath)")
        zshrcContents = try String(
          contentsOfFile: expandedPath,
          encoding: .utf8
        )
      } else {
        print(
          "DEBUG: Attempting to load .zshrc from adjacent bundle or dev resources"
        )
        if let sharedZshrcPath = ZShift.resourceURL(
          named: "zshrc",
          withExtension: "txt"
        ),
          let text = try? String(contentsOf: sharedZshrcPath, encoding: .utf8)
        {
          zshrcContents = text
          print("DEBUG: Found zshrc.txt at: \(sharedZshrcPath.path)")
        } else {
          print(
            "WARN: Bundled zshrc.txt not found; writing a minimal placeholder."
          )
          zshrcContents =
            "# zshift: zshrc template not found; run 'zshift doctor' or provide --custom-zshrc\n"
        }
      }
    } catch {
      print("ERROR: Failed to load .zshrc: \(error)")
      print(
        "DEBUG: Current working directory: \(FileManager.default.currentDirectoryPath)"
      )
      throw ExitCode.failure
    }

    let marker = "# >>> zshift config >>>"
    let endMarker = "# <<< zshift config <<<"
    // Legacy fallback markers used by setup.sh template writer
    let legacyBegin = "### BEGIN wrkstrm-configs (zshrc.txt)"
    let legacyEnd = "### END wrkstrm-configs (zshrc.txt)"
    let contentsToAppend = "\n\(marker)\n\(zshrcContents)\n\(endMarker)\n"

    if let existing = try? String(contentsOf: userZshrcPath, encoding: .utf8) {
      func replaceBlock(begin: String, end: String, in text: String) -> String? {
        let ns = text as NSString
        let b = ns.range(of: begin)
        let e = ns.range(of: end)
        guard b.location != NSNotFound, e.location != NSNotFound, e.location > b.location else {
          return nil
        }
        let before = String(text.prefix(b.location))
        let afterStart = e.location + e.length
        let after = String(text.suffix(max(0, text.count - afterStart)))
        return before + contentsToAppend + after
      }

      var updatedAny = existing
      if let legacyUpdated = replaceBlock(begin: legacyBegin, end: legacyEnd, in: updatedAny) {
        updatedAny = legacyUpdated
      }
      if let primaryUpdated = replaceBlock(begin: marker, end: endMarker, in: updatedAny) {
        updatedAny = primaryUpdated
      }
      // Detect whether the file already contains any known block markers
      let hasLegacy = existing.contains(legacyBegin) && existing.contains(legacyEnd)
      let hasPrimary = existing.contains(marker) && existing.contains(endMarker)
      let changed = (updatedAny != existing)

      if hasLegacy || hasPrimary {
        // There is already a block present; ensure only a single primary block remains.
        // Start from updatedAny (which may equal existing if content hasn't changed)
        var deduped = updatedAny
        while true {
          let ns = deduped as NSString
          let firstB = ns.range(of: marker)
          let firstE = ns.range(of: endMarker)
          guard firstB.location != NSNotFound, firstE.location != NSNotFound else { break }
          // Search for any subsequent blocks after firstE
          let searchRange = NSRange(
            location: firstE.location + firstE.length,
            length: max(0, ns.length - (firstE.location + firstE.length)))
          let nextB = ns.range(of: marker, options: [], range: searchRange)
          if nextB.location == NSNotFound { break }
          let nextE = ns.range(
            of: endMarker, options: [],
            range: NSRange(location: nextB.location, length: ns.length - nextB.location))
          if nextE.location == NSNotFound { break }
          // Remove the extra block
          let before = ns.substring(to: nextB.location)
          let after = ns.substring(from: nextE.location + nextE.length)
          deduped = before + after
        }
        if deduped != existing {
          try deduped.write(to: userZshrcPath, atomically: true, encoding: .utf8)
          print("INFO: Refreshed and de‑duplicated zshift config block in .zshrc.")
        } else if changed {
          // Content changed but count did not; write changes
          try updatedAny.write(to: userZshrcPath, atomically: true, encoding: .utf8)
          print("INFO: Refreshed existing zshift config block in .zshrc.")
        } else {
          print("INFO: zshift config block already up to date; no changes.")
        }
      } else if changed {
        // No existing markers; append a new block
        try (existing + contentsToAppend).write(
          to: userZshrcPath,
          atomically: true,
          encoding: .utf8
        )
        print("SUCCESS: .zshrc file has been updated.")
      } else {
        // No markers found, and replacement did not change (unlikely); append block for safety
        try (existing + contentsToAppend).write(
          to: userZshrcPath,
          atomically: true,
          encoding: .utf8
        )
        print("SUCCESS: .zshrc file has been updated.")
      }
    } else {
      if FileManager.default.fileExists(atPath: userZshrcPath.path),
        let fileHandle = FileHandle(forWritingAtPath: userZshrcPath.path)
      {
        fileHandle.seekToEndOfFile()
        fileHandle.write(contentsToAppend.data(using: .utf8)!)
        fileHandle.closeFile()
      } else {
        try contentsToAppend.write(
          to: userZshrcPath,
          atomically: true,
          encoding: .utf8
        )
      }
      print("SUCCESS: .zshrc file has been updated.")
    }
  }
}
#endif  // os(macOS) || os(Linux)

// MARK: - Doctor

struct Doctor: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "doctor",
    abstract: "Minimal environment checks for zshift banner + template."
  )

  func run() async throws {
    let env = ProcessInfo.processInfo.environment
    let home = FileManager.default.homeDirectoryForCurrentUser.path

    // Paths and env
    let zshiftPathEnv = env["ZSHIFT_PATH"] ?? "<unset>"
    let pathVar = env["PATH"] ?? ""
    let hasSwiftPMBin = pathVar.split(separator: ":").contains {
      $0 == "\(home)/.swiftpm/bin"
    }
    let zshiftBinaryInSwiftPM = FileManager.default.fileExists(
      atPath: "\(home)/.swiftpm/bin/zshift"
    )

    // Team template availability
    let templateURL = ZShift.resourceURL(named: "zshrc", withExtension: "txt")

    // Bundles adjacency
    let execDir = ZShift.executableDirectory
    let zshiftBundle = execDir.appendingPathComponent("zshift_Zshift.bundle")
    let figletBundle = execDir.appendingPathComponent(
      "SwiftFigletKit_SwiftFigletKit.bundle"
    )
    let hasZshiftBundle = FileManager.default.fileExists(
      atPath: zshiftBundle.path
    )
    let hasFigletBundle = FileManager.default.fileExists(
      atPath: figletBundle.path
    )

    // Detect zshift output contract (bare theme vs prefixed with ZSH_THEME=)
    let contract: String
    var lastLine: String = ""
    do {
      // Invoke the current executable with "random" to capture output
      let me = URL(fileURLWithPath: CommandLine.arguments.first ?? "zshift")
      let p = Process()
      p.executableURL = me
      p.arguments = ["random"]
      let pipe = Pipe()
      p.standardOutput = pipe
      p.standardError = Pipe()
      try p.run()
      p.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let s = String(data: data, encoding: .utf8) {
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false)
        if let last = lines.last {
          lastLine = String(last).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if lines.contains(where: { $0.hasPrefix("ZSH_THEME=") }) {
          contract = "prefixed"
        } else {
          contract = "bare"
        }
      } else {
        contract = "unknown"
      }
    } catch {
      contract = "unknown"
    }

    // Resolved config
    let (excludedURL, excludedSrc) = ZShiftConfig.resolveListPath(
      kind: .excluded,
      flag: nil,
      env: env
    )
    let (likedURL, likedSrc) = ZShiftConfig.resolveListPath(
      kind: .liked,
      flag: nil,
      env: env
    )
    let themesResolved = ZShiftConfig.resolveThemesDir(flag: nil, env: env)
    let configDir = ZShiftConfig.resolveConfigDir(env: env)

    // Figlet fonts availability via library API
    let fontNames = SFKFonts.listNames()

    // Fast-mode flags
    let fast = env["WRKSTRM_FAST_SHELL"] ?? "<unset>"
    let ci = env["CI"] ?? "<unset>"

    func yn(_ b: Bool) -> String { b ? "yes" : "no" }

    print("zshift doctor:\n")
    print("- ZSHIFT_PATH: \(zshiftPathEnv)")
    print("- PATH has ~/.swiftpm/bin: \(yn(hasSwiftPMBin))")
    print("- zshift in ~/.swiftpm/bin: \(yn(zshiftBinaryInSwiftPM))")
    print("- config dir: \(configDir.path)")
    print("- excluded path (\(excludedSrc.rawValue)): \(excludedURL.path)")
    print("- liked path (\(likedSrc.rawValue)): \(likedURL.path)")
    if let themesResolved {
      print(
        "- themes dir (\(themesResolved.source.rawValue)): \(themesResolved.url.path)"
      )
    } else {
      print("- themes dir: <not found>")
    }
    if let templateURL {
      print("- team template (zshrc.txt): \(templateURL.path)")
    } else {
      print("- team template (zshrc.txt): <not found>")
    }
    print(
      "- adjacent zshift bundle: \(yn(hasZshiftBundle)) @ \(zshiftBundle.path)"
    )
    print(
      "- adjacent SwiftFigletKit bundle: \(yn(hasFigletBundle)) @ \(figletBundle.path)"
    )
    print("- figlet fonts available: \(fontNames.count) font(s)")
    print("- fast-mode flags: WRKSTRM_FAST_SHELL=\(fast), CI=\(ci)")
    print("- zshift output contract: \(contract)")
    if !lastLine.isEmpty { print("- zshift random last line: \(lastLine)") }
  }
}

// MARK: - List

struct List: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List available, liked, or excluded themes",
    helpNames: .shortAndLong
  )

  enum Category: String, ExpressibleByArgument, CaseIterable {
    case available, liked, excluded
  }

  @Argument(
    help:
      "What to list: \(Category.allCases.map { $0.rawValue }.joined(separator: ", "))"
  )
  var category: Category

  @Flag(name: .long, help: "Emit JSON output")
  var json = false

  @Option(name: .long) var excludedPath: String?
  @Option(name: .long) var likedPath: String?
  @Option(name: .long) var themesDir: String?

  func run() async throws {
    let env = ProcessInfo.processInfo.environment
    switch category {
    case .available:
      let liked = ZShiftConfig.loadList(kind: .liked, flag: likedPath, env: env)
      let excluded = ZShiftConfig.loadList(
        kind: .excluded,
        flag: excludedPath,
        env: env
      )
      guard
        let themesURL = ZShiftConfig.resolveThemesDir(
          flag: themesDir,
          env: env
        )?.url
      else {
        throw ExitCode.failure
      }
      let all = Random.getAvailableThemes(
        excludedThemes: excluded + liked,
        themesDir: themesURL.path
      )
      let withoutRandom = all.filter { $0 != "random" }
      if json {
        let data = try JSONEncoder().encode(withoutRandom)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        withoutRandom.forEach { print($0) }
      }
    case .liked:
      let list = ZShiftConfig.loadList(kind: .liked, flag: likedPath, env: env)
      if json {
        let data = try JSONEncoder().encode(list)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        list.forEach { print($0) }
      }
    case .excluded:
      let list = ZShiftConfig.loadList(
        kind: .excluded,
        flag: excludedPath,
        env: env
      )
      if json {
        let data = try JSONEncoder().encode(list)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        list.forEach { print($0) }
      }
    }
  }
}

// MARK: - Config (init/show)

struct Config: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "config",
    abstract: "Initialize or inspect zshift config",
    subcommands: [Init.self, Show.self]
  )

  struct Init: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Write user config with team defaults"
    )

    @Option(name: .long, help: "Config directory root (defaults to XDG)")
    var configDir: String?

    @Flag(name: .long, help: "Overwrite existing files")
    var force = false

    func run() async throws {
      let env = ProcessInfo.processInfo.environment
      let root: URL
      if let configDir, !configDir.isEmpty {
        root = URL(
          fileURLWithPath: ZShift.expandTilde(in: configDir),
          isDirectory: true
        )
      } else {
        root = ZShiftConfig.resolveConfigDir(env: env)
      }
      let dir = root.appendingPathComponent("zshift", isDirectory: true)
      try FileManager.default.createDirectory(
        at: dir,
        withIntermediateDirectories: true
      )
      // Copy defaults if present
      let items: [(String, String)] = [
        ("excluded_zsh_themes", "excluded.txt"),
        ("liked_zsh_themes", "liked.txt"),
      ]
      for (name, dest) in items {
        let destURL = dir.appendingPathComponent(dest)
        if FileManager.default.fileExists(atPath: destURL.path) && !force {
          continue
        }
        if let res = ZShift.resourceURL(named: name, withExtension: "txt"),
          let text = try? String(contentsOf: res, encoding: .utf8)
        {
          try text.write(to: destURL, atomically: true, encoding: .utf8)
        } else {
          try "".write(to: destURL, atomically: true, encoding: .utf8)
        }
      }
      print("OK: wrote zshift config at \(dir.path)")
    }
  }

  struct Show: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Show resolved config paths"
    )

    @Flag(name: .long, help: "Emit JSON output")
    var json = false

    func run() async throws {
      let env = ProcessInfo.processInfo.environment
      let configDir = ZShiftConfig.resolveConfigDir(env: env)
      let (excluded, eSrc) = ZShiftConfig.resolveListPath(
        kind: .excluded,
        flag: nil,
        env: env
      )
      let (liked, lSrc) = ZShiftConfig.resolveListPath(
        kind: .liked,
        flag: nil,
        env: env
      )
      let themes = ZShiftConfig.resolveThemesDir(flag: nil, env: env)
      if json {
        struct Model: Codable {
          let configDir: String
          let excluded: String
          let excludedSource: String
          let liked: String
          let likedSource: String
          let themesDir: String?
          let themesSource: String?
        }
        let m = Model(
          configDir: configDir.path,
          excluded: excluded.path,
          excludedSource: eSrc.rawValue,
          liked: liked.path,
          likedSource: lSrc.rawValue,
          themesDir: themes?.url.path,
          themesSource: themes?.source.rawValue
        )
        let data = try JSONEncoder().encode(m)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        print("config dir: \(configDir.path)")
        print("excluded: \(excluded.path) [\(eSrc.rawValue)]")
        print("liked:    \(liked.path) [\(lSrc.rawValue)]")
        if let themes {
          print("themes:   \(themes.url.path) [\(themes.source.rawValue)]")
        } else {
          print("themes:   <not found>")
        }
      }
    }
  }
}

// MARK: - Embedded defaults (universal, no bundle required)

// Embedded defaults removed to avoid hard-coded theme lists and templates.
