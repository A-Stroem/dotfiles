#!/usr/bin/env bash
# ============================================================
# Merge VS Code terminal/theme settings (macOS/Linux/WSL)
# ============================================================

set -euo pipefail

STRICT_MODE=false
THEME=""

usage() {
    cat <<'USAGE'
Usage: install-vscode-settings.sh [options]

Options:
  --theme <dracula|gruvbox>   Theme to apply (default: detect from chezmoi data)
  --strict                     Exit non-zero on recoverable setup issues
  -h, --help                  Show this help text
USAGE
}

normalize_theme() {
    local value
    value="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
    case "$value" in
        dracula|gruvbox)
            printf '%s\n' "$value"
            ;;
        *)
            printf '%s\n' "gruvbox"
            ;;
    esac
}

detect_theme_from_chezmoi() {
    local config_file detected
    config_file="${HOME}/.config/chezmoi/chezmoi.toml"
    detected=""

    if [[ -f "$config_file" ]]; then
        detected="$(sed -nE 's/^[[:space:]]*terminalTheme[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*$/\1/p' "$config_file" | head -n 1)"
    fi

    normalize_theme "$detected"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --theme)
            [[ $# -ge 2 ]] || { echo "Missing value for --theme"; usage; exit 1; }
            THEME="$2"
            shift 2
            ;;
        --strict)
            STRICT_MODE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if ! command -v python3 >/dev/null 2>&1; then
    echo "WARN: python3 is required for VS Code settings merge; skipping."
    if [ "$STRICT_MODE" = true ]; then
        exit 1
    fi
    exit 0
fi

if [[ -z "$THEME" ]]; then
    THEME="$(detect_theme_from_chezmoi)"
else
    THEME="$(normalize_theme "$THEME")"
fi

merge_settings_file() {
    local settings_file="$1"
    local label="$2"
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"

    mkdir -p "$(dirname "$settings_file")"
    if [ ! -f "$settings_file" ]; then
        printf '{}\n' > "$settings_file"
    fi

    cp "$settings_file" "${settings_file}.backup.${timestamp}"

    if ! python3 - "$settings_file" "$THEME" <<'PY'
import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
theme_key = sys.argv[2].lower()

THEMES = {
    "dracula": {
        "font": "FiraCode Nerd Font",
        "colors": {
            "terminal.background": "#1E1F29",
            "terminal.foreground": "#F8F8F2",
            "terminalCursor.foreground": "#F8F8F2",
            "terminal.selectionBackground": "#44475A",
            "terminal.ansiBlack": "#21222C",
            "terminal.ansiRed": "#FF5555",
            "terminal.ansiGreen": "#50FA7B",
            "terminal.ansiYellow": "#F1FA8C",
            "terminal.ansiBlue": "#BD93F9",
            "terminal.ansiMagenta": "#FF79C6",
            "terminal.ansiCyan": "#8BE9FD",
            "terminal.ansiWhite": "#F8F8F2",
            "terminal.ansiBrightBlack": "#6272A4",
            "terminal.ansiBrightRed": "#FF6E6E",
            "terminal.ansiBrightGreen": "#69FF94",
            "terminal.ansiBrightYellow": "#FFFFA5",
            "terminal.ansiBrightBlue": "#D6ACFF",
            "terminal.ansiBrightMagenta": "#FF92DF",
            "terminal.ansiBrightCyan": "#A4FFFF",
            "terminal.ansiBrightWhite": "#FFFFFF",
        },
    },
    "gruvbox": {
        "font": "MesloLGS Nerd Font",
        "colors": {
            "terminal.background": "#1d2021",
            "terminal.foreground": "#ebdbb2",
            "terminalCursor.foreground": "#ebdbb2",
            "terminal.selectionBackground": "#504945",
            "terminal.ansiBlack": "#282828",
            "terminal.ansiRed": "#cc241d",
            "terminal.ansiGreen": "#98971a",
            "terminal.ansiYellow": "#d79921",
            "terminal.ansiBlue": "#458588",
            "terminal.ansiMagenta": "#b16286",
            "terminal.ansiCyan": "#689d6a",
            "terminal.ansiWhite": "#a89984",
            "terminal.ansiBrightBlack": "#928374",
            "terminal.ansiBrightRed": "#fb4934",
            "terminal.ansiBrightGreen": "#b8bb26",
            "terminal.ansiBrightYellow": "#fabd2f",
            "terminal.ansiBrightBlue": "#83a598",
            "terminal.ansiBrightMagenta": "#d3869b",
            "terminal.ansiBrightCyan": "#8ec07c",
            "terminal.ansiBrightWhite": "#ebdbb2",
        },
    },
}

if theme_key not in THEMES:
    theme_key = "gruvbox"

theme = THEMES[theme_key]
raw = path.read_text(encoding="utf-8-sig")


def strip_jsonc(text: str) -> str:
    out = []
    i = 0
    n = len(text)
    in_str = False
    escaped = False
    in_line_comment = False
    in_block_comment = False
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if in_line_comment:
            if c == "\n":
                in_line_comment = False
                out.append(c)
            i += 1
            continue
        if in_block_comment:
            if c == "*" and nxt == "/":
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue
        if in_str:
            out.append(c)
            if escaped:
                escaped = False
            elif c == "\\":
                escaped = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "/" and nxt == "/":
            in_line_comment = True
            i += 2
            continue
        if c == "/" and nxt == "*":
            in_block_comment = True
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def remove_trailing_commas(text: str) -> str:
    prev = None
    cur = text
    while prev != cur:
        prev = cur
        cur = re.sub(r",(\s*[}\]])", r"\1", cur)
    return cur


cleaned = remove_trailing_commas(strip_jsonc(raw)).strip()
if not cleaned:
    settings = {}
else:
    settings = json.loads(cleaned)
if not isinstance(settings, dict):
    settings = {}

settings.update(
    {
        "terminal.integrated.defaultProfile.linux": "zsh",
        "terminal.integrated.fontFamily": theme["font"],
        "terminal.integrated.fontSize": 13,
        "terminal.integrated.lineHeight": 1.1,
        "terminal.integrated.cursorStyle": "line",
        "terminal.integrated.smoothScrolling": True,
        "terminal.integrated.scrollback": 10000,
    }
)

colors = settings.get("workbench.colorCustomizations")
if not isinstance(colors, dict):
    colors = {}
colors.update(theme["colors"])
settings["workbench.colorCustomizations"] = colors

path.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")
PY
    then
        echo "WARN: Could not parse/merge VS Code settings for ${label}: ${settings_file}"
        if [ "$STRICT_MODE" = true ]; then
            exit 1
        fi
        return 0
    fi

    echo "Updated VS Code settings (${label}) for theme '${THEME}': ${settings_file}"
}

merge_if_present() {
    local settings_file="$1"
    local label="$2"
    local parent_dir
    parent_dir="$(dirname "$settings_file")"

    if [[ -f "$settings_file" || -d "$parent_dir" ]]; then
        merge_settings_file "$settings_file" "$label"
    fi
}

echo "Configuring VS Code settings for theme '${THEME}'..."

# macOS local settings
merge_if_present "$HOME/Library/Application Support/Code/User/settings.json" "macOS user (Code)"
merge_if_present "$HOME/Library/Application Support/Code - Insiders/User/settings.json" "macOS user (Code - Insiders)"

# Linux local settings
merge_if_present "$HOME/.config/Code/User/settings.json" "Linux user (Code)"
merge_if_present "$HOME/.config/Code - Insiders/User/settings.json" "Linux user (Code - Insiders)"

# WSL remote + Windows settings
if grep -qi microsoft /proc/version 2>/dev/null; then
    WSL_REMOTE_SETTINGS="${HOME}/.vscode-server/data/Machine/settings.json"
    merge_settings_file "$WSL_REMOTE_SETTINGS" "WSL remote"

    if command -v cmd.exe >/dev/null 2>&1; then
        WIN_USERPROFILE=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
        if [ -n "$WIN_USERPROFILE" ]; then
            WIN_SETTINGS_WINPATHS=(
                "$WIN_USERPROFILE\\AppData\\Roaming\\Code\\User\\settings.json"
                "$WIN_USERPROFILE\\AppData\\Roaming\\Code - Insiders\\User\\settings.json"
            )
            for win_path in "${WIN_SETTINGS_WINPATHS[@]}"; do
                wsl_path=$(wslpath "$win_path" 2>/dev/null || true)
                if [ -n "$wsl_path" ]; then
                    parent_dir="$(dirname "$wsl_path")"
                    if [ ! -d "$parent_dir" ] && [ ! -f "$wsl_path" ]; then
                        continue
                    fi
                    label="Windows user (Code)"
                    if [[ "$win_path" == *"Code - Insiders"* ]]; then
                        label="Windows user (Code - Insiders)"
                    fi
                    merge_settings_file "$wsl_path" "$label"
                fi
            done
        fi
    fi
fi

echo "VS Code settings merge complete."
