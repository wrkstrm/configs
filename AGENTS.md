# Agents

This directory houses environment and tooling configs for Swift packages.

## Learned Debugging

- Swiftly toolchain mismatch: If Swiftly does not list the current Xcode toolchain, it cannot target that SDK. Remove the pinned toolchain and rely on Xcode Default. See `README.md › Troubleshooting › Swift toolchains (Swiftly)` for steps.

## Assistant Operating Mode

- Git command approval: do not run any `git` commands without explicit user approval
  (including but not limited to `clone`, `status`, `add`, `commit`, `reset`, `rebase`, `push`,
  `submodule`, `config`). Prefer reading workspace files over invoking `git` when possible.

## CLIA Canonicals and First Launch

- Canonical loaders: JSON triads under `.clia/agents/**`.
- Canonical MD (human): persona and system‑instructions alongside triads.
- Mirrors: `.generated/agent.md` is non‑canonical; use to validate rendering.
- Default agent: `^codex` unless an explicit agent load is requested via
  `>agentSlug` (e.g., `>clia`, `>carrie`).

Checklist

- `!sync` → reset, thin‑scan, determine scope; load triads; apply sandbox/approvals; announce mode.

Diverge paths

- If in submodule: stage a DocC request with diffs/rationale in parent repo.
- Use CommonShell/CommonProcess; avoid `Foundation.Process`.

DocC link: `code/.clia/docc/agents-onboarding.docc` (preview from repo root).
