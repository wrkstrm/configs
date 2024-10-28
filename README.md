# Environment Setup Guide

This guide explains the required environment variables for working with wrkstrm packages and tools.

## Required Variables

### Package Management Configuration

Add the following to your `~/.zprofile`:

```bash
# Package Steward Configuration
# Controls whether to use local dependencies (true) or remote dependencies (false)
export SPM_CI_USE_LOCAL_DEPS=true
```

This environment variable controls dependency resolution behavior:
- `true`: Uses local dependencies for development
- `false`: Uses remote dependencies (useful for CI environments)

## Verification

After adding the variable to your `.zprofile`, verify your setup:

```bash
source ~/.zprofile
echo $SPM_CI_USE_LOCAL_DEPS
```

This should output: `true`

## Troubleshooting

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
   echo $SPM_CI_USE_LOCAL_DEPS
   ```
