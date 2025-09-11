# Environment Setup Guide

This guide explains the required environment variables for working with wrkstrm packages and tools.
This guide is specifically for M class Macs.

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
   brew install swiftformat
   brew install swift-format
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

5. **Repo‑local CLI bin (recommended)**

   Keep installed CLI tools scoped to this repo by using a local, gitignored bin:
   - Installer: `bash .wrkstrm/clia/bin/swift/install-cli-tools.sh`
   - Binaries land in: `.wrkstrm/clia/bin/swift/`
   - Optional PATH: `export PATH="$(pwd)/.wrkstrm/clia/bin/swift:$PATH"`

   Notes:
   - This avoids polluting global PATH while keeping tools reproducible per‑repo.
   - SwiftPM’s `experimental-install` still installs to `~/.swiftpm/bin`; you can use either approach.

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
