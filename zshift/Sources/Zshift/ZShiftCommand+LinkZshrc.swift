import ArgumentParser
import Foundation

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
          print("INFO: Refreshed and de-duplicated zshift config block in .zshrc.")
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
