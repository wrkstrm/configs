import Foundation
import Testing

@testable import Zshift

@Test
func expandTilde() {
  let home = FileManager.default.homeDirectoryForCurrentUser.path
  let expanded = ZShift.expandTilde(in: "~/.zshrc")
  #expect(expanded == "\(home)/.zshrc")
}

@Test
func loadExcludedThemesFromFile() throws {
  let tempDir = FileManager.default.temporaryDirectory
  let fileURL = tempDir.appendingPathComponent("excluded_test.txt")
  let contents = "themeB\nthemeA\n\nthemeA\n"
  try contents.write(to: fileURL, atomically: true, encoding: .utf8)

  let themes = ZShift.loadExcludedThemes(from: fileURL.path)
  #expect(themes == ["themeA", "themeB"])
}

@Test
func appendThemeToFile() throws {
  let tempDir = FileManager.default.temporaryDirectory
  let fileURL = tempDir.appendingPathComponent("append_test.txt")
  let path = fileURL.path

  if FileManager.default.fileExists(atPath: path) {
    try FileManager.default.removeItem(atPath: path)
  }

  try ZShift.append(theme: "first", to: path)
  try ZShift.append(theme: "second", to: path)

  let result = try String(contentsOfFile: path, encoding: .utf8)
  #expect(result == "first\nsecond\n")
}

@Test
func resolveConfigDirOrder() {
  // Prefer ZSHIFT_CONFIG_HOME
  var env = ProcessInfo.processInfo.environment
  env["ZSHIFT_CONFIG_HOME"] = "~/custom"
  env["XDG_CONFIG_HOME"] = "~/xdg"
  let url = ZShiftConfig.resolveConfigDir(env: env)
  #expect(url.path.hasSuffix("/custom"))
}

@Test
func resolveListPathsAndLoading() throws {
  // Use XDG when no flag/env, and fallback to bundle when file missing
  var env = ProcessInfo.processInfo.environment
  env.removeValue(forKey: "ZSHIFT_CONFIG_HOME")
  let (excludedURL, src) = ZShiftConfig.resolveListPath(kind: .excluded, flag: nil, env: env)
  #expect(src == .xdg)
  // Create user file and ensure loader prefers it
  try FileManager.default.createDirectory(
    at: excludedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
  try "foo\nbar\n".write(to: excludedURL, atomically: true, encoding: .utf8)
  let list = ZShiftConfig.loadList(kind: .excluded, flag: nil, env: env)
  #expect(list == ["bar", "foo"])
}
