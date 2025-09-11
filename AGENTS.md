# Agents

This directory houses environment and tooling configs for Swift packages.

## Learned Debugging

- Swiftly toolchain mismatch: If Swiftly does not list the current Xcode toolchain, it cannot target that SDK. Remove the pinned toolchain and rely on Xcode Default. See `README.md › Troubleshooting › Swift toolchains (Swiftly)` for steps.
