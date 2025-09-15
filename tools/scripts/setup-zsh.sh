#!/usr/bin/env bash
set -euo pipefail

# setup-zsh.sh — bootstrap a sane ~/.zshrc using the configs submodule
# - Backs up any existing ~/.zshrc
# - Prefer linking via the bundled Swift CLI (zshift)
# - Optionally installs common Zsh extras via Homebrew (fzf, autosuggestions, highlighting)
# - Falls back to writing the bundled zshrc.txt if zshift is unavailable

print_usage() {
  cat <<'USAGE'
Usage: setup-zsh.sh [options]

Options:
  --install-plugins    Install optional plugins via Homebrew (fzf, zsh-autosuggestions, zsh-syntax-highlighting)
  --no-install-plugins Do not install optional plugins
  --link-only          Only (re)link ~/.zshrc using zshift if available; no installs
  --no-backup          Do not create a backup of existing ~/.zshrc
  -y, --yes            Run non-interactively (assume yes)
  -h, --help           Show this help

Notes:
  - This script is intended to run from a clone of wrkstrm/configs (this folder).
  - If Swift is available, we use: swift run -c release zshift link-zshrc
  - Fallback writes the bundled zshrc.txt into ~/.zshrc with clear markers.
USAGE
}

YES=${YES:-}
INSTALL_PLUGINS=true
LINK_ONLY=false
BACKUP=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-plugins) INSTALL_PLUGINS=true; shift ;;
    --no-install-plugins) INSTALL_PLUGINS=false; shift ;;
    --link-only) LINK_ONLY=true; shift ;;
    --no-backup) BACKUP=false; shift ;;
    -y|--yes) YES=1; shift ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; print_usage; exit 1 ;;
  esac
done

prompt_yes() {
  if [[ -n "$YES" ]]; then return 0; fi
  read -r -p "$1 [y/N] " ans || true
  [[ "$ans" =~ ^[Yy]$ ]]
}

# Resolve important paths inside this repo
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIGS_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
ZSHIFT_DIR="$CONFIGS_ROOT/zshift"
ZSHRC_TEMPLATE="$ZSHIFT_DIR/Sources/Zshift/Resources/zshrc.txt"

echo "==> Using configs at: $CONFIGS_ROOT"

backup_if_needed() {
  local target="$HOME/.zshrc"
  if $BACKUP && [[ -f "$target" ]]; then
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    local bak="$target.$ts.bak"
    cp "$target" "$bak"
    echo "==> Backed up existing ~/.zshrc to: $bak"
  fi
}

install_plugins() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "==> Homebrew not found; skipping plugin installs"; return 0
  fi
  echo "==> Installing optional Zsh extras via Homebrew..."
  brew list fzf >/dev/null 2>&1 || brew install fzf || true
  brew list zsh-autosuggestions >/dev/null 2>&1 || brew install zsh-autosuggestions || true
  brew list zsh-syntax-highlighting >/dev/null 2>&1 || brew install zsh-syntax-highlighting || true
  if command -v /opt/homebrew/opt/fzf/install >/dev/null 2>&1; then
    /opt/homebrew/opt/fzf/install --key-bindings --completion --no-update-rc || true
  elif command -v /usr/local/opt/fzf/install >/dev/null 2>&1; then
    /usr/local/opt/fzf/install --key-bindings --completion --no-update-rc || true
  fi
}

link_with_zshift() {
  if ! command -v swift >/dev/null 2>&1; then
    echo "==> Swift not found; cannot run zshift."
    return 1
  fi
  if [[ ! -d "$ZSHIFT_DIR" ]]; then
    echo "==> zshift directory not found at: $ZSHIFT_DIR"
    return 1
  fi
  echo "==> Building and linking .zshrc via zshift (release)..."
  (
    cd "$ZSHIFT_DIR"
    swift run -c release zshift link-zshrc ${BACKUP:+--backup}

    # Ensure zshift binary is installed to ~/.swiftpm/bin for interactive shells
    if command -v swift >/dev/null 2>&1; then
      BIN_DIR=$(swift build -c release --show-bin-path 2>/dev/null || true)
      if [[ -n "$BIN_DIR" && -x "$BIN_DIR/zshift" ]]; then
        mkdir -p "$HOME/.swiftpm/bin"
        cp -f "$BIN_DIR/zshift" "$HOME/.swiftpm/bin/zshift"
        echo "INFO: Installed zshift to $HOME/.swiftpm/bin/zshift"
      fi
    fi
  )
}

fallback_write_template() {
  if [[ ! -f "$ZSHRC_TEMPLATE" ]]; then
    echo "ERROR: zshrc.txt template not found at: $ZSHRC_TEMPLATE" >&2
    return 1
  fi
  backup_if_needed
  local start='### BEGIN wrkstrm-configs (zshrc.txt)'
  local end='### END wrkstrm-configs (zshrc.txt)'
  echo "==> Writing bundled template into ~/.zshrc"
  {
    echo "$start"
    cat "$ZSHRC_TEMPLATE"
    echo "$end"
  } > "$HOME/.zshrc"
}

# Main
if $INSTALL_PLUGINS; then
  install_plugins
fi

if ! $LINK_ONLY; then
  if prompt_yes "Proceed to link ~/.zshrc using zshift (recommended)?"; then
    if ! link_with_zshift; then
      echo "==> Falling back to writing the bundled template..."
      fallback_write_template
    fi
  else
    echo "==> Skipping zshift link; writing bundled template instead."
    fallback_write_template
  fi
else
  if ! link_with_zshift; then
    echo "==> --link-only requested but zshift failed or missing. No changes made."
    exit 1
  fi
fi

echo "==> Done. Start a new shell or run: source ~/.zshrc"
