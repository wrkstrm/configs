import ArgumentParser
import CommonShell
import Foundation
import SwiftFigletKit
import WrkstrmLog

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
      let shell = CommonShell()
      let s = try await shell.run(host: .direct, executable: .path(me.path), arguments: ["random"])
      do {
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false)
        if let last = lines.last {
          lastLine = String(last).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if lines.contains(where: { $0.hasPrefix("ZSH_THEME=") }) {
          contract = "prefixed"
        } else {
          contract = "bare"
        }
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
    let (fontExcludedURL, fontExcludedSrc) = ZShiftConfig.resolveFontListPath(
      kind: .excluded,
      flag: nil,
      env: env
    )
    let (fontLikedURL, fontLikedSrc) = ZShiftConfig.resolveFontListPath(
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
    print("- excluded fonts path (\(fontExcludedSrc.rawValue)): \(fontExcludedURL.path)")
    print("- liked fonts path (\(fontLikedSrc.rawValue)): \(fontLikedURL.path)")
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
