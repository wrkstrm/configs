# Agents

This directory houses environment and tooling configs for Swift packages.

## Learned Debugging

- Swiftly toolchain mismatch: If Swiftly does not list the current Xcode toolchain, it cannot target that SDK. Remove the pinned toolchain and rely on Xcode Default. See `README.md › Troubleshooting › Swift toolchains (Swiftly)` for steps.

## Assistant Operating Mode

- Git command approval: do not run any `git` commands without explicit user approval
  (including but not limited to `clone`, `status`, `add`, `commit`, `reset`, `rebase`, `push`,
  `submodule`, `config`). Prefer reading workspace files over invoking `git` when possible.
