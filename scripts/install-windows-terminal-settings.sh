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

WT_SETTINGS_FILE="$WSL_WT_SETTINGS/settings.json"

# Backup existing settings
if [ -f "$WT_SETTINGS_FILE" ]; then
    echo "📦 Backing up existing settings..."
    backup_file="$WT_SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$WT_SETTINGS_FILE" "$backup_file"
    echo "✅ Backup created: $(basename "$backup_file")"
else
    echo "❌ Windows Terminal settings.json not found at: $WT_SETTINGS_FILE"
    echo "   Open Windows Terminal once so it can generate settings.json, then rerun this script."
    exit 1
fi

echo "🎨 Applying cosmetic settings (without replacing your profiles)..."
python3 - "$WT_SETTINGS_FILE" <<'PY'
import json
import sys

settings_path = sys.argv[1]

with open(settings_path, "r", encoding="utf-8") as f:
    settings = json.load(f)

profiles = settings.setdefault("profiles", {})
defaults = profiles.setdefault("defaults", {})

# Cosmetic defaults only
defaults.setdefault("font", {})["face"] = "FiraCode Nerd Font"
defaults["colorScheme"] = "Dracula (Dotfiles)"
defaults["cursorShape"] = "bar"
defaults["padding"] = "8, 8, 8, 8"
defaults["useAcrylic"] = False

schemes = settings.setdefault("schemes", [])
scheme_name = "Dracula (Dotfiles)"
dracula_scheme = {
    "name": scheme_name,
    "background": "#14151D",
    "foreground": "#F8F8F2",
    "selectionBackground": "#44475A",
    "cursorColor": "#F8F8F2",
    "black": "#21222C",
    "red": "#FF5555",
    "green": "#50FA7B",
    "yellow": "#F1FA8C",
    "blue": "#BD93F9",
    "purple": "#FF79C6",
    "cyan": "#8BE9FD",
    "white": "#F8F8F2",
    "brightBlack": "#6272A4",
    "brightRed": "#FF6E6E",
    "brightGreen": "#69FF94",
    "brightYellow": "#FFFFA5",
    "brightBlue": "#D6ACFF",
    "brightPurple": "#FF92DF",
    "brightCyan": "#A4FFFF",
    "brightWhite": "#FFFFFF",
}

existing_scheme = next((scheme for scheme in schemes if scheme.get("name") == scheme_name), None)
if existing_scheme is None:
    schemes.append(dracula_scheme)
else:
    existing_scheme.update(dracula_scheme)

profile_list = profiles.setdefault("list", [])
wsl_profile = next(
    (
        profile
        for profile in profile_list
        if profile.get("guid") == "{2c4de342-38b7-51cf-b940-2309a097f518}"
        or profile.get("name") == "Ubuntu (WSL)"
    ),
    None,
)

if wsl_profile is None:
    wsl_profile = {
        "guid": "{2c4de342-38b7-51cf-b940-2309a097f518}",
        "name": "Ubuntu (WSL)",
        "source": "Windows.Terminal.Wsl",
        "startingDirectory": "~",
    }
    profile_list.append(wsl_profile)
else:
    wsl_profile.setdefault("source", "Windows.Terminal.Wsl")
    wsl_profile.setdefault("startingDirectory", "~")

default_profile = None
for profile in profile_list:
    if profile.get("source") == "Windows.Terminal.Wsl" and profile.get("guid"):
        default_profile = profile["guid"]
        break

if default_profile:
    settings["defaultProfile"] = default_profile

with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("✅ Applied cosmetic settings and preserved existing profile definitions.")
if default_profile:
    print(f"✅ Default profile set to WSL profile: {default_profile}")
else:
    print("⚠️ No WSL profile GUID found; defaultProfile left unchanged.")
PY

echo ""
echo "✅ Windows Terminal settings updated!"
echo "📁 Location: $(wslpath -w "$WSL_WT_SETTINGS")"
echo ""
echo "⚠️  If you haven't installed FiraCode Nerd Font yet:"
echo "   Run: bash ~/.local/share/chezmoi/scripts/download-nerd-font.sh"
echo ""
echo "🔄 Close and restart Windows Terminal to apply changes."
