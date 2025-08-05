import XCTest

@testable import Zshift

final class ZShiftTests: XCTestCase {
  func testExpandTilde() {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let expanded = ZShift.expandTilde(in: "~/.zshrc")
    XCTAssertEqual(expanded, "\(home)/.zshrc")
  }

  func testLoadExcludedThemesFromFile() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent("excluded_test.txt")
    let contents = "themeB\nthemeA\n\nthemeA\n"
    try contents.write(to: fileURL, atomically: true, encoding: .utf8)

    let themes = ZShift.loadExcludedThemes(from: fileURL.path)
    XCTAssertEqual(themes, ["themeA", "themeB"])
  }

  func testAppendThemeToFile() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent("append_test.txt")
    let path = fileURL.path

    if FileManager.default.fileExists(atPath: path) {
      try FileManager.default.removeItem(atPath: path)
    }

    try ZShift.append(theme: "first", to: path)
    try ZShift.append(theme: "second", to: path)

    let result = try String(contentsOfFile: path, encoding: .utf8)
    XCTAssertEqual(result, "first\nsecond\n")
  }
}
