#!/usr/bin/env bash
# ============================================================
# Bootstrap macOS from zero
# ============================================================

set -euo pipefail

echo "🚀 Bootstrapping macOS environment..."

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
echo "📦 Updating Homebrew..."
brew update

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
