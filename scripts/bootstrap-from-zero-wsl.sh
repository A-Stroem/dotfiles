#!/usr/bin/env bash
# ============================================================
# Bootstrap WSL Ubuntu from zero
# ============================================================

set -euo pipefail

echo "🚀 Bootstrapping WSL Ubuntu environment..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install minimal dependencies
echo "📦 Installing minimal dependencies..."
sudo apt install -y curl git ca-certificates

# Install chezmoi
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "📦 Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  
  # Add to PATH for this session
  export PATH="$HOME/.local/bin:$PATH"
  
  echo "✅ chezmoi installed to ~/.local/bin/chezmoi"
else
  echo "✅ chezmoi already installed"
fi

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Initialize your dotfiles:"
echo "     ~/.local/bin/chezmoi init --apply git@github.com:YOUR_USERNAME/dotfiles.git"
echo ""
echo "  2. Or if you don't have a dotfiles repo yet:"
echo "     ~/.local/bin/chezmoi init"
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
