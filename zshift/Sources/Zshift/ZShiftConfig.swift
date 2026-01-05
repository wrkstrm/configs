import ArgumentParser
import Foundation

// MARK: - Configuration resolution

struct ZShiftConfig {
  enum Kind { case excluded, liked }
  enum FontKind { case excluded, liked }
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
    let canonicalEntries = contents.components(separatedBy: .newlines)
      .map(ZShiftConfig.canonicalFontName)
      .filter { !$0.isEmpty }
    return Array(Set(canonicalEntries)).sorted()
  }

  static func resolveFontListPath(
    kind: FontKind,
    flag: String?,
    env: [String: String] = ProcessInfo.processInfo.environment
  ) -> (url: URL, source: Source) {
    if let flag, !flag.isEmpty {
      return (URL(fileURLWithPath: expand(flag)), .flag)
    }
    switch kind {
    case .excluded:
      if let value = env["ZSHIFT_FONT_EXCLUDED"], !value.isEmpty {
        return (URL(fileURLWithPath: expand(value)), .env)
      }
    case .liked:
      if let value = env["ZSHIFT_FONT_LIKED"], !value.isEmpty {
        return (URL(fileURLWithPath: expand(value)), .env)
      }
    }
    let directory = resolveConfigDir(env: env)
      .appendingPathComponent("zshift", isDirectory: true)
      .appendingPathComponent("fonts", isDirectory: true)
    let fileName: String = {
      switch kind {
      case .excluded: return "excluded.txt"
      case .liked: return "liked.txt"
      }
    }()
    return (directory.appendingPathComponent(fileName), .xdg)
  }

  static func loadFontList(
    kind: FontKind,
    flag: String?,
    env: [String: String] = ProcessInfo.processInfo.environment
  ) -> [String] {
    let (url, _) = resolveFontListPath(kind: kind, flag: flag, env: env)
    let fm = FileManager.default
    let contents: String
    if fm.fileExists(atPath: url.path),
      let text = try? String(contentsOf: url, encoding: .utf8)
    {
      contents = text
    } else {
      let resourceName = (kind == .excluded) ? "excluded_figlet_fonts" : "liked_figlet_fonts"
      if let resourceURL = ZShift.resourceURL(named: resourceName, withExtension: "txt"),
        let text = try? String(contentsOf: resourceURL, encoding: .utf8)
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

  static func canonicalFontName(_ name: String) -> String {
    name.replacingOccurrences(of: "_", with: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
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

enum ZShiftPreferenceKind: String, CaseIterable, ExpressibleByArgument {
  case theme, font
}
