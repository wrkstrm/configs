import ArgumentParser
import Foundation

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
        ("excluded_figlet_fonts", "fonts/excluded.txt"),
        ("liked_figlet_fonts", "fonts/liked.txt"),
      ]
      for (name, dest) in items {
        let destURL = dir.appendingPathComponent(dest)
        if FileManager.default.fileExists(atPath: destURL.path) && !force {
          continue
        }
        if let res = ZShift.resourceURL(named: name, withExtension: "txt"),
          let text = try? String(contentsOf: res, encoding: .utf8)
        {
          try FileManager.default.createDirectory(
            at: destURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
          )
          try text.write(to: destURL, atomically: true, encoding: .utf8)
        } else {
          try FileManager.default.createDirectory(
            at: destURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
          )
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
      let (fontExcluded, fontExcludedSrc) = ZShiftConfig.resolveFontListPath(
        kind: .excluded,
        flag: nil,
        env: env
      )
      let (fontLiked, fontLikedSrc) = ZShiftConfig.resolveFontListPath(
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
          let fontExcluded: String
          let fontExcludedSource: String
          let fontLiked: String
          let fontLikedSource: String
          let themesDir: String?
          let themesSource: String?
        }
        let m = Model(
          configDir: configDir.path,
          excluded: excluded.path,
          excludedSource: eSrc.rawValue,
          liked: liked.path,
          likedSource: lSrc.rawValue,
          fontExcluded: fontExcluded.path,
          fontExcludedSource: fontExcludedSrc.rawValue,
          fontLiked: fontLiked.path,
          fontLikedSource: fontLikedSrc.rawValue,
          themesDir: themes?.url.path,
          themesSource: themes?.source.rawValue
        )
        let data = try JSONEncoder().encode(m)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        print("config dir: \(configDir.path)")
        print("excluded: \(excluded.path) [\(eSrc.rawValue)]")
        print("liked:    \(liked.path) [\(lSrc.rawValue)]")
        print("fonts (excluded): \(fontExcluded.path) [\(fontExcludedSrc.rawValue)]")
        print("fonts (liked):    \(fontLiked.path) [\(fontLikedSrc.rawValue)]")
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
