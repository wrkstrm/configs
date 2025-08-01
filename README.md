# Environment Setup Guide

This guide explains the required environment variables for working with wrkstrm packages and tools. This guide is specifically for M class Macs.

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

3. **Environment Setup**

    Add the following to your `~/.zprofile`:

      ```bash
      # Package Steward Configuration
      # Controls whether to use local dependencies (true) or remote dependencies (false)
      export SPM_USE_LOCAL_DEPS=true
      ```

This environment variable controls dependency resolution behavior:
- `true`: Uses local dependencies for development
- `false`: Uses remote dependencies (useful for CI environments)

### Verify Your Tools

Verify your installations:
```bash
# Check Homebrew
brew --version

# Check Fastlane
fastlane --version

# Check SwiftLint
swiftlint version
```



### Verify Environment Variable

After adding the variable to your `.zprofile`, verify your setup:

```bash
source ~/.zprofile
echo $SPM_USE_LOCAL_DEPS
```

This should output: `true`

## Troubleshooting

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

## Setting up zshift

`zshift` is a small Swift utility that links your `.zshrc` to the shared configuration in this repository.
To run the setup script:

```bash
cd zshift
./setup.sh
```

After running the script, a new `.zshrc` symlink will be created and your configuration reloaded.
