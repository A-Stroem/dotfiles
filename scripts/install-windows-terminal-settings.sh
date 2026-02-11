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
WIN_LOCALAPPDATA=$(cmd.exe /c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r')

# Try multiple possible locations
WT_LOCATIONS=(
    "$WIN_LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState"
    "$WIN_LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\\LocalState"
    "$WIN_LOCALAPPDATA\\Microsoft\\Windows Terminal"
)

WSL_WT_SETTINGS=""

for location in "${WT_LOCATIONS[@]}"; do
    wsl_path=$(wslpath "$location" 2>/dev/null || echo "")
    if [ -n "$wsl_path" ] && [ -d "$wsl_path" ]; then
        WSL_WT_SETTINGS="$wsl_path"
        echo "✅ Found Windows Terminal at: $location"
        break
    fi
done

if [ -z "$WSL_WT_SETTINGS" ]; then
    echo "❌ Windows Terminal settings directory not found."
    echo ""
    echo "🔍 Searched locations:"
    for location in "${WT_LOCATIONS[@]}"; do
        echo "   - $location"
    done
    echo ""
    echo "💡 Troubleshooting:"
    echo "   1. Make sure Windows Terminal is installed"
    echo "   2. Try opening Windows Terminal at least once"
    echo "   3. Check if you're using Windows Terminal Preview (different location)"
    echo ""
    echo "🔍 To find the location manually:"
    echo "   In Windows Terminal, press Ctrl+, (Settings)"
    echo "   Look at the bottom left for 'Open JSON file'"
    exit 1
fi

# Backup existing settings
if [ -f "$WSL_WT_SETTINGS/settings.json" ]; then
    echo "📦 Backing up existing settings..."
    cp "$WSL_WT_SETTINGS/settings.json" "$WSL_WT_SETTINGS/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup created: settings.json.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Copy new settings
echo "📝 Installing new settings..."
if [ ! -f "$HOME/.config/windows-terminal/settings.json" ]; then
    echo "❌ Source settings file not found: $HOME/.config/windows-terminal/settings.json"
    echo "   Run 'chezmoi apply' first to create this file."
    exit 1
fi

cp "$HOME/.config/windows-terminal/settings.json" "$WSL_WT_SETTINGS/settings.json"

echo ""
echo "✅ Windows Terminal settings installed!"
echo "📁 Location: $(wslpath -w "$WSL_WT_SETTINGS")"
echo ""
echo "⚠️  If you haven't installed FiraCode Nerd Font yet:"
echo "   Run: bash ~/.local/share/chezmoi/scripts/download-nerd-font.sh"
echo ""
echo "🔄 Close and restart Windows Terminal to apply changes."
