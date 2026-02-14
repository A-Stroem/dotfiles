#!/usr/bin/env bash
# ============================================================
# Toggle/apply terminal theme for chezmoi-managed environment
# ============================================================

set -euo pipefail

CHEZMOI_CONFIG="${HOME}/.config/chezmoi/chezmoi.toml"
ACTION="toggle"

usage() {
    cat <<'USAGE'
Usage: toggle-theme.sh [dracula|gruvbox|toggle]

Examples:
  toggle-theme.sh           # switches dracula <-> gruvbox
  toggle-theme.sh dracula   # force dracula
  toggle-theme.sh gruvbox   # force gruvbox
USAGE
}

normalize_theme() {
    case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
        dracula|gruvbox)
            printf '%s\n' "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
            ;;
        *)
            printf '%s\n' "gruvbox"
            ;;
    esac
}

get_config_theme() {
    if [[ -f "$CHEZMOI_CONFIG" ]]; then
        sed -nE 's/^[[:space:]]*terminalTheme[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*$/\1/p' "$CHEZMOI_CONFIG" | head -n 1
    fi
}

detect_current_theme() {
    local theme ghostty_config
    theme="$(normalize_theme "$(get_config_theme)")"
    if [[ -n "$(get_config_theme)" ]]; then
        printf '%s\n' "$theme"
        return
    fi

    ghostty_config="${HOME}/.config/ghostty/config"
    if [[ -f "$ghostty_config" ]]; then
        if grep -qi 'dracula' "$ghostty_config"; then
            printf '%s\n' "dracula"
            return
        fi
        if grep -qi 'gruvbox' "$ghostty_config"; then
            printf '%s\n' "gruvbox"
            return
        fi
    fi

    printf '%s\n' "gruvbox"
}

set_theme_in_chezmoi_config() {
    local target="$1"
    local tmp_file

    mkdir -p "$(dirname "$CHEZMOI_CONFIG")"
    if [[ ! -f "$CHEZMOI_CONFIG" ]]; then
        printf '[data]\n    terminalTheme = "%s"\n' "$target" > "$CHEZMOI_CONFIG"
        return
    fi

    tmp_file="$(mktemp)"
    awk -v theme="$target" '
      BEGIN { replaced = 0; inserted = 0 }
      {
        if ($0 ~ /^[[:space:]]*terminalTheme[[:space:]]*=/) {
          print "    terminalTheme = \"" theme "\""
          replaced = 1
          next
        }

        print

        if (!inserted && !replaced && $0 ~ /^[[:space:]]*\[data\][[:space:]]*$/) {
          print "    terminalTheme = \"" theme "\""
          inserted = 1
        }
      }
      END {
        if (!replaced && !inserted) {
          print ""
          print "[data]"
          print "    terminalTheme = \"" theme "\""
        }
      }
    ' "$CHEZMOI_CONFIG" > "$tmp_file"

    mv "$tmp_file" "$CHEZMOI_CONFIG"
}

if [[ $# -gt 1 ]]; then
    usage
    exit 1
fi

if [[ $# -eq 1 ]]; then
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        dracula|gruvbox|toggle)
            ACTION="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
fi

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "❌ chezmoi is required but not found in PATH"
    exit 1
fi

CURRENT_THEME="$(detect_current_theme)"
if [[ "$ACTION" == "toggle" ]]; then
    if [[ "$CURRENT_THEME" == "dracula" ]]; then
        TARGET_THEME="gruvbox"
    else
        TARGET_THEME="dracula"
    fi
else
    TARGET_THEME="$(normalize_theme "$ACTION")"
fi

if [[ "$CURRENT_THEME" == "$TARGET_THEME" ]]; then
    echo "Theme is already '${TARGET_THEME}'. Nothing to change."
    exit 0
fi

set_theme_in_chezmoi_config "$TARGET_THEME"

echo "Applying theme '${TARGET_THEME}' with chezmoi..."
chezmoi apply

CHEZMOI_SOURCE_DIR="$(chezmoi source-path)"
if [[ -f "$CHEZMOI_SOURCE_DIR/scripts/install-vscode-settings.sh" ]]; then
    bash "$CHEZMOI_SOURCE_DIR/scripts/install-vscode-settings.sh" --theme "$TARGET_THEME" || true
fi

if grep -qi microsoft /proc/version 2>/dev/null && [[ -f "$CHEZMOI_SOURCE_DIR/scripts/install-windows-terminal-settings.sh" ]]; then
    bash "$CHEZMOI_SOURCE_DIR/scripts/install-windows-terminal-settings.sh" --theme "$TARGET_THEME" || true
fi

echo "✅ Theme switched: ${CURRENT_THEME} -> ${TARGET_THEME}"
echo "   Restart Ghostty and VS Code if colors do not refresh immediately."
