#!/usr/bin/env bash
# ============================================================
# Bootstrap macOS from zero
# ============================================================

set -euo pipefail

echo "🚀 Bootstrapping macOS environment..."

repair_tap() {
  local tap="$1"

  if brew tap | grep -qx "$tap"; then
    echo "🔧 Retapping ${tap}..."
    brew untap "$tap" || true
  fi

  brew tap "$tap"
}

normalize_homebrew_remotes() {
  local repos repo remote_path current_remote
  repos=()

  repos+=("$(brew --repo)")
  while IFS= read -r repo; do
    repos+=("$(brew --repo "$repo" 2>/dev/null || true)")
  done < <(brew tap)

  for repo in "${repos[@]}"; do
    [[ -z "$repo" || ! -d "$repo/.git" ]] && continue
    current_remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
    if [[ "$current_remote" =~ ^git@github\.com:(.+)$ ]]; then
      remote_path="${BASH_REMATCH[1]}"
      git -C "$repo" remote set-url origin "https://github.com/${remote_path}" || true
    fi
  done
}

update_homebrew() {
  local update_output

  echo "📦 Updating Homebrew..."
  if update_output="$(brew update 2>&1)"; then
    printf '%s\n' "$update_output"
    return 0
  fi

  printf '%s\n' "$update_output"

  if grep -Eq "Not a valid ref: refs/remotes/origin/(main|master)" <<<"$update_output"; then
    echo "⚠️  Detected broken Homebrew tap refs. Attempting auto-repair..."
    repair_tap homebrew/core || true
    if brew tap | grep -qx "homebrew/cask"; then
      repair_tap homebrew/cask || true
    fi
    echo "📦 Retrying Homebrew update..."
    brew update
    return 0
  fi

  echo "⚠️  Homebrew update failed. Continuing bootstrap without update."
  return 0
}

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
  echo "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH for Apple Silicon
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "🔧 Configuring Homebrew for Apple Silicon..."
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew already installed"
fi

# Update Homebrew
normalize_homebrew_remotes
update_homebrew

# Install chezmoi
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "📦 Installing chezmoi..."
  brew install chezmoi
  echo "✅ chezmoi installed"
else
  echo "✅ chezmoi already installed"
fi

# Install git if not present
if ! command -v git >/dev/null 2>&1; then
  echo "📦 Installing git..."
  brew install git
fi

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Initialize your dotfiles:"
echo "     chezmoi init --apply git@github.com:YOUR_USERNAME/dotfiles.git"
echo ""
echo "  2. Or if you don't have a dotfiles repo yet:"
echo "     chezmoi init"
echo "     cd ~/.local/share/chezmoi"
echo "     # Add your dotfiles here, then:"
echo "     git init"
echo "     git add ."
echo "     git commit -m 'Initial dotfiles'"
echo "     git remote add origin git@github.com:YOUR_USERNAME/dotfiles.git"
echo "     git push -u origin main"
echo ""
echo "  3. Restart your shell:"
echo "     exec zsh"
