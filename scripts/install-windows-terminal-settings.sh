#!/usr/bin/env bash
# ============================================================
# Install Windows Terminal settings from WSL
# ============================================================

set -euo pipefail

echo "🔧 Installing Windows Terminal settings..."

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "❌ Not running in WSL. This script is for WSL only."
    exit 1
fi

# Find Windows Terminal settings location
WIN_USERPROFILE=$(cmd.exe /c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r')
WT_SETTINGS_DIR="$WIN_USERPROFILE\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalSettings"

# Convert to WSL path
WSL_WT_SETTINGS=$(wslpath "$WT_SETTINGS_DIR" 2>/dev/null)

if [ ! -d "$WSL_WT_SETTINGS" ]; then
    echo "❌ Windows Terminal not found. Please install it from the Microsoft Store."
    exit 1
fi

# Backup existing settings
if [ -f "$WSL_WT_SETTINGS/settings.json" ]; then
    echo "📦 Backing up existing settings..."
    cp "$WSL_WT_SETTINGS/settings.json" "$WSL_WT_SETTINGS/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Copy new settings
echo "📝 Installing new settings..."
cp "$HOME/.config/windows-terminal/settings.json" "$WSL_WT_SETTINGS/settings.json"

echo ""
echo "✅ Windows Terminal settings installed!"
echo ""
echo "⚠️  If you haven't installed FiraCode Nerd Font yet:"
echo "   Run: ~/.local/share/chezmoi/scripts/download-nerd-font.sh"
echo ""
echo "🔄 Restart Windows Terminal to apply changes."
