#!/usr/bin/env bash
# ============================================================
# Install Windows Terminal settings from WSL
# ============================================================

set -euo pipefail

STRICT_MODE=false
SET_DEFAULT_PROFILE=true

usage() {
    cat <<'EOF'
Usage: install-windows-terminal-settings.sh [options]

Options:
  --strict               Exit non-zero on recoverable setup issues
  --no-default-profile   Do not set the managed WSL profile as default
  -h, --help             Show this help text
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict)
            STRICT_MODE=true
            shift
            ;;
        --no-default-profile)
            SET_DEFAULT_PROFILE=false
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo "🔧 Configuring Windows Terminal (non-destructive merge)..."

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
    echo "⚠️  Windows Terminal settings directory not found."
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
    if [ "$STRICT_MODE" = true ]; then
        exit 1
    fi
    exit 0
fi

SETTINGS_FILE="$WSL_WT_SETTINGS/settings.json"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Ensure settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "📝 Creating new Windows Terminal settings file..."
    printf '{}\n' > "$SETTINGS_FILE"
fi

# Backup existing settings
if [ -f "$SETTINGS_FILE" ]; then
    echo "📦 Backing up existing settings..."
    cp "$SETTINGS_FILE" "$WSL_WT_SETTINGS/settings.json.backup.$TIMESTAMP"
    echo "✅ Backup created: settings.json.backup.$TIMESTAMP"
fi

# Merge managed profile and scheme without replacing existing profiles/settings
if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ python3 is required but not found."
    if [ "$STRICT_MODE" = true ]; then
        exit 1
    fi
    exit 0
fi

echo "📝 Merging managed WSL profile into Windows Terminal settings..."
if ! python3 - "$SETTINGS_FILE" "$SET_DEFAULT_PROFILE" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
set_default_profile = sys.argv[2].lower() == "true"

PROFILE_GUID = "{f8f98f0e-cf86-448e-b07e-07b185f9dd86}"
PROFILE_NAME = "WSL (chezmoi)"
SCHEME_NAME = "Dracula (chezmoi)"

managed_profile = {
    "guid": PROFILE_GUID,
    "name": PROFILE_NAME,
    "commandline": "wsl.exe",
    "startingDirectory": "~",
    "colorScheme": SCHEME_NAME,
    "cursorShape": "bar",
    "padding": "8, 8, 8, 8",
    "useAcrylic": False,
    "font": {
        "face": "FiraCode Nerd Font"
    }
}

managed_scheme = {
    "name": SCHEME_NAME,
    "background": "#1E1F29",
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

try:
    raw = settings_path.read_text(encoding="utf-8-sig").strip()
    settings = {} if not raw else json.loads(raw)
except json.JSONDecodeError as exc:
    print(f"JSON parse error in {settings_path}: {exc}", file=sys.stderr)
    sys.exit(2)

if not isinstance(settings, dict):
    settings = {}

profiles = settings.get("profiles")
if not isinstance(profiles, dict):
    profiles = {}
    settings["profiles"] = profiles

profile_list = profiles.get("list")
if not isinstance(profile_list, list):
    profile_list = []
    profiles["list"] = profile_list

existing_index = None
for idx, entry in enumerate(profile_list):
    if not isinstance(entry, dict):
        continue
    if entry.get("guid") == PROFILE_GUID:
        existing_index = idx
        break
    if entry.get("name") == PROFILE_NAME and entry.get("commandline") == "wsl.exe":
        existing_index = idx
        break

if existing_index is None:
    profile_list.append(managed_profile)
else:
    existing = profile_list[existing_index]
    merged = dict(existing)
    merged.update(managed_profile)
    existing_font = existing.get("font")
    if isinstance(existing_font, dict):
        font = dict(existing_font)
        font.update(managed_profile["font"])
        merged["font"] = font
    profile_list[existing_index] = merged

schemes = settings.get("schemes")
if not isinstance(schemes, list):
    schemes = []
    settings["schemes"] = schemes

scheme_index = None
for idx, entry in enumerate(schemes):
    if isinstance(entry, dict) and entry.get("name") == SCHEME_NAME:
        scheme_index = idx
        break

if scheme_index is None:
    schemes.append(managed_scheme)
else:
    merged_scheme = dict(schemes[scheme_index])
    merged_scheme.update(managed_scheme)
    schemes[scheme_index] = merged_scheme

if set_default_profile:
    settings["defaultProfile"] = PROFILE_GUID

settings_path.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")
PY
then
    echo "⚠️  Could not parse/merge Windows Terminal settings."
    echo "   If your settings file contains JSON comments, open it in Windows Terminal once and save it, then re-run this script."
    if [ "$STRICT_MODE" = true ]; then
        exit 1
    fi
    exit 0
fi

echo ""
echo "✅ Windows Terminal settings updated."
echo "   Existing profiles were preserved."
echo "   Managed profile: WSL (chezmoi)"
echo "📁 Location: $(wslpath -w "$WSL_WT_SETTINGS")"
echo ""
echo "⚠️  If you haven't installed FiraCode Nerd Font yet:"
echo "   Run: bash ~/.local/share/chezmoi/scripts/download-nerd-font.sh"
echo ""
echo "🔄 Close and restart Windows Terminal to apply changes."
