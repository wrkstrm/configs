# Environment Setup Guide

This guide explains the required environment variables for working with wrkstrm packages and tools.
This guide is specifically for M class Macs.

> **Codex harness reminder**
>
> The checked-in Codex CLI harness is a generic profile. New contributors must
> run through the setup steps below and intentionally opt into repo-specific
> behaviors (agents, timers, logging). Do not assume the harness auto-detects
> todo3 conventions; wire them in explicitly during onboarding.

## Installation

### Prerequisites

1. **Homebrew**

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   After installation, make sure Homebrew is in your PATH:

   ```bash
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

2. **Development Tools**

   Install required development tools using Homebrew:

   ```bash
   # Install Fastlane for iOS automation and localization
   brew install fastlane

   # Install linting tools
   brew install swiftlint
   ```

   Install `markdownlint-cli2` globally with npm for Markdown linting:

   ```bash
   npm install -g markdownlint-cli2
   ```

3. **GitHub Local Runner**

   Install GitHub's local runner to execute workflows on your machine. For additional configuration
   options, see
   [GitHub's self-hosted runner documentation](https://docs.github.com/actions/hosting-your-own-runners/about-self-hosted-runners):

   ```bash
   mkdir actions-runner && cd actions-runner
   curl -o actions-runner-osx-arm64.tar.gz -L https://github.com/actions/runner/releases/latest/download/actions-runner-osx-arm64.tar.gz
   tar xzf actions-runner-osx-arm64.tar.gz
   ./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token YOUR_TOKEN
   ./run.sh
   ```

   After starting the runner, confirm it shows as `online` in your repository's **Settings >
   Actions > Runners** page. You can verify the installation at any time:

   ```bash
   ./run.sh --version
   ```

4. **Environment Setup**

   Add the following to your `~/.zprofile`:

   ```bash
   # Package Steward Configuration
   # Controls whether to use local dependencies (true) or remote dependencies (false)
   export SPM_USE_LOCAL_DEPS=true
   ```

This environment variable controls dependency resolution behavior:

- `true`: Uses local dependencies for development
- `false`: Uses remote dependencies (useful for CI environments)

5. **Install CLIs (preferred: experimental‑install)**

   Prefer SwiftPM’s install to the user bin so tools are available consistently:

   ```bash
   # From a package directory that builds an executable target
   # Example: CLIA
   cd code/mono/apple/spm/universal/domain/ai/clia
   swift package experimental-install --configuration release

   # Ensure ~/.swiftpm/bin is in your PATH (e.g., in ~/.zprofile)
   export PATH="$HOME/.swiftpm/bin:$PATH"
   clia --help
   ```

   Optional: repo‑local bin for scoped installs (does not touch user PATH):

   ```bash
   # From the repo root
   mkdir -p .wrkstrm/clia/bin/swift
   export PATH="$(pwd)/.wrkstrm/clia/bin/swift:$PATH" # optional, current shell only

   # Build then link a tool into the local bin (example: CLIA)
   (cd code/mono/apple/spm/universal/domain/ai/clia && swift build -c release)
   ln -sf "$(pwd)/code/mono/apple/spm/universal/domain/ai/clia/.build/release/clia" \
         ".wrkstrm/clia/bin/swift/clia"
   ```

   Notes:
   - Preferred: `experimental-install` to `~/.swiftpm/bin` for user‑level availability.
   - Alternative: repo‑local `.wrkstrm/clia/bin/swift/` to avoid modifying global PATH.

### Verify Your Tools

Verify your installations:

```bash
# Check Homebrew
brew --version

# Check Fastlane
fastlane --version

# Check SwiftLint
swiftlint version

# Check markdownlint
markdownlint-cli2 --version

# Check GitHub Local Runner (run from the actions-runner directory)
./run.sh --version
```

### Verify Environment Variable

After adding the variable to your `.zprofile`, verify your setup:

```bash
source ~/.zprofile
echo $SPM_USE_LOCAL_DEPS
```

This should output: `true`

### Run Markdownlint

Use `markdownlint-cli2` with the repository's configuration to lint Markdown files:

```bash
markdownlint-cli2 --config linting/.markdownlint.jsonc "**/*.md"
```

## Troubleshooting

### Swift toolchains (Swiftly)

- Use the Xcode Default toolchain for Apple SDK builds. A mismatched compiler/SDK (e.g., Swift 6.1.x compiler vs Xcode 26 SDK built with Swift 6.2) will fail with Darwin module errors.
- If `swiftly toolchain list` does not include your current Xcode toolchain, do not force Swiftly; remove the pinned entry (e.g., `swiftly toolchain remove swift-6.1.2-RELEASE`) and rely on Xcode Default.
- Sanity checks: `xcodebuild -version`, `xcrun swift --version`, and ensure `SWIFT_EXEC`/`TOOLCHAINS` are unset.

### **brew issues**

If you encounter any issues:

1. Update Homebrew and all packages:

   ```bash
   brew update && brew upgrade
   ```

2. Check for any Homebrew problems:

   ```bash
   brew doctor
   ```

3. Ensure Homebrew's binary location is in your PATH:

   ```bash
   echo $PATH | grep brew
   ```

### **.zprofile issues**

If the variable isn't being set:

1. Ensure your `.zprofile` is being sourced by adding to `.zshrc`:

   ```bash
   if [ -f "$HOME/.zprofile" ]; then
       source "$HOME/.zprofile"
   fi
   ```

2. Check file permissions:

   ```bash
   chmod 600 ~/.zprofile
   ```

3. Verify the variable after opening a new terminal:

   ```bash
   echo $SPM_USE_LOCAL_DEPS
   ```

## Zsh setup (recommended)

Use the top‑level setup helper to create or update your `~/.zshrc`. It prefers the Swift CLI (zshift)
and installs common Zsh extras by default.

```bash
bash tools/scripts/setup-zsh.sh -y
```

Flags:

- `--install-plugins`: install fzf, zsh‑autosuggestions, zsh‑syntax‑highlighting via Homebrew (default)
- `--no-install-plugins`: skip installing optional plugins
- `--link-only`: only link `~/.zshrc` using zshift (no installs)
- `--no-backup`: skip backup of existing `~/.zshrc`
- `-y/--yes`: non‑interactive mode

If Swift is unavailable, the script falls back to writing the bundled template
(`zshift/Sources/Zshift/Resources/zshrc.txt`) into `~/.zshrc` with clear markers.

## Setting up zshift

`zshift` is a small Swift utility that links your `.zshrc` to the shared configuration in this
repository. To run the setup script:

```bash
cd zshift
./setup.sh
```

After running the script, a new `.zshrc` symlink will be created and your configuration reloaded.

### Zshift configuration

zshift resolves configuration from flags, environment variables, user config files, and bundled
team defaults with a clear precedence. This removes hard‑coded lists and keeps behavior
predictable across hosts.

#### Precedence (highest to lowest)

1. CLI flags (`--excluded-path`, `--liked-path`, `--themes-dir`)
2. Environment variables (`ZSHIFT_EXCLUDED`, `ZSHIFT_LIKED`, `ZSH_THEMES_DIR`)
3. XDG config: `($ZSHIFT_CONFIG_HOME || $XDG_CONFIG_HOME || ~/.config)/zshift/`
4. Bundled team defaults (read-only):
   `Resources/{excluded_zsh_themes.txt, liked_zsh_themes.txt}`
5. Empty (no embedded fallbacks); use `zshift config init` to seed user files

The same precedence applies to FIGlet font lists via `--excluded-fonts-path`, `--liked-fonts-path`, and the `ZSHIFT_FONT_EXCLUDED`/`ZSHIFT_FONT_LIKED` environment variables.

#### Files and locations

- User config directory: `($ZSHIFT_CONFIG_HOME || $XDG_CONFIG_HOME || ~/.config)/zshift/`
- User files (created by `zshift config init`):
  - `excluded.txt`: newline‑delimited theme names to exclude
  - `liked.txt`: newline‑delimited theme names to prefer
  - `fonts/excluded.txt`: newline‑delimited FIGlet fonts to suppress
  - `fonts/liked.txt`: newline‑delimited FIGlet fonts to prefer

#### Environment variables

- `ZSHIFT_EXCLUDED`: path to excluded list file
- `ZSHIFT_LIKED`: path to liked list file
- `ZSHIFT_FONT_EXCLUDED`: path to excluded FIGlet fonts list
- `ZSHIFT_FONT_LIKED`: path to liked FIGlet fonts list
- `ZSH_THEMES_DIR`: path to directory containing `.zsh-theme` files
- `ZSHIFT_CONFIG_HOME`: overrides the config root (defaults to XDG)
- `XDG_CONFIG_HOME`: standard XDG config root (defaults to `~/.config`)
- `ZSHIFT_ZSHRC_TEMPLATE`: optional path used by `link-zshrc` when no flag is passed

#### CLI flags

- `zshift random --excluded-path <path> --liked-path <path> --themes-dir <dir> \`
  `--excluded-fonts-path <path> --liked-fonts-path <path>`
- `zshift like <name> --kind theme|font [--liked-path <path>] [--liked-fonts-path <path>]`
- `zshift exclude <name> --kind theme|font [--excluded-path <path>] [--excluded-fonts-path <path>]`
- `zshift link-zshrc --custom-zshrc <path> [--backup]`

#### Subcommands

- `zshift config init [--config-dir <dir>] [--force]`
  - Seeds `excluded.txt` and `liked.txt` under the user config dir with team defaults.
- `zshift config show [--json]`
  - Prints resolved paths and sources (flag/env/xdg/bundle).
- `zshift list available|liked|excluded|available-fonts|liked-fonts|excluded-fonts [--json] \
  [--themes-dir <dir>] [--excluded-path <p>] [--liked-path <p>] [--excluded-fonts-path <p>] \
  [--liked-fonts-path <p>]`
  - Lists effective theme or FIGlet font entries for scripting or inspection.

#### Quickstart

```bash
# 1) Initialize user config with team defaults
zshift config init

# 2) Pick a theme (excludes liked/excluded lists by default)
zshift random

# 3) Curate your lists
zshift like ys
zshift exclude robbyrussell
# Prefer a FIGlet font
zshift like block --kind font

# 4) Inspect current resolution
zshift config show --json | jq .
```

#### Troubleshooting

- `zshift random` errors with “No themes directory found”:
  - Install Oh My Zsh, or provide `--themes-dir /path/to/themes`, or set `ZSH_THEMES_DIR`.
- Team template not found for `link-zshrc`:
  - Provide `--custom-zshrc` or set `ZSHIFT_ZSHRC_TEMPLATE`, or run `zshift doctor` for hints.
- Use `zshift doctor` to print resolved config dir, list paths and sources, themes dir, and
  bundle availability.

### Banner example (Swift)

zshift uses SwiftFigletKit’s random rendering API to print a themed banner. The equivalent Swift
snippet is:

```swift
import SwiftFigletKit

let theme = "ys" // dynamically chosen by zshift
let font = SFKFonts.randomName() ?? "standard"
let banner = SFKRenderer.render(
  text: "ZShift x " + theme,
  font: .named(font),
  color: .mixedRandom(),
  options: .init(newline: false)
)
let canonicalFont = ZShiftConfig.canonicalFontName(font)
print(banner)
print("FIGLET_FONT=\(canonicalFont)")
print("ZSH_THEME=\(theme)") // the team template expects the theme as the last line
```

### Team‑first zsh shim (recommended)

Keep login shells stable by sourcing the shared team template first, then your personal overrides.
This ensures the figlet banner and theme logic always run, while your aliases and helpers remain.

1. Replace `~/.zshrc` with this minimal shim:

   ```zsh
   #!/usr/bin/env zsh
   # wrkstrm ~/.zshrc shim — team first, then personal overrides.

   : ${ZSHIFT_PATH:="$HOME/todo3/code/mono/apple/spm/configs/zshift"}
   TEAM_CFG="$ZSHIFT_PATH/Sources/Zshift/Resources/zshrc.txt"
   PERSONAL_CFG="$HOME/todo3/code/configs/zshrc"
   LOCAL_CFG="$HOME/.zshrc.local"

   # Team template (figlet/theme/OMZ)
   if [[ -f "$TEAM_CFG" ]]; then
     source "$TEAM_CFG"
   else
     print -u2 -- "wrkstrm: team zshrc not found at $TEAM_CFG (set ZSHIFT_PATH?)"
   fi

   # Personal overrides
   [[ -f "$PERSONAL_CFG" ]] && source "$PERSONAL_CFG"
   [[ -f "$LOCAL_CFG" ]] && source "$LOCAL_CFG"
   ```

2. Persist required environment in `~/.zprofile`:

   ```zsh
   # Team configs location for the shim
   export ZSHIFT_PATH="$HOME/todo3/code/mono/apple/spm/configs/zshift"

   # Ensure repo‑installed SwiftPM tools (e.g., zshift) are on PATH
   export PATH="$HOME/.swiftpm/bin:$PATH"
   ```

3. Open a new Terminal tab or `source ~/.zshrc` and verify:
   - Expect a figlet banner and a final `ZSH_THEME=...` line (template parses this to set the theme).
   - `command -v zshift` should resolve (typically `~/.swiftpm/bin/zshift`).

### Team plugins policy

The team template loads a lean, guarded plugin set:

- Base: `git`, `history-substring-search`.
- Optional (loaded only if present): `zsh-autosuggestions`, `zsh-syntax-highlighting` (last),
  `xcode` (macOS), `vscode` (when `code` is on PATH).
- Explicitly not loaded: `fzf` (to avoid warnings on hosts without fzf).

If you need additional plugins, propose changes to the team template rather than duplicating plugin
setup in personal configs.
