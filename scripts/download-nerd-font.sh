#!/usr/bin/env bash
# ============================================================
# Download Nerd Font to Windows Downloads folder (WSL)
# ============================================================

set -euo pipefail

FONT_CHOICE="auto"

usage() {
    cat <<'USAGE'
Usage: download-nerd-font.sh [options]

Options:
  --font <auto|fira|meslo>   Font family to download (default: auto)
  -h, --help                 Show this help text
USAGE
}

normalize_font_choice() {
    case "$(printf '%s' "${1:-auto}" | tr '[:upper:]' '[:lower:]')" in
        auto|fira|firacode|meslo)
            printf '%s\n' "$(printf '%s' "${1:-auto}" | tr '[:upper:]' '[:lower:]')"
            ;;
        *)
            printf '%s\n' "auto"
            ;;
    esac
}

detect_theme() {
    local config_file detected
    config_file="${HOME}/.config/chezmoi/chezmoi.toml"
    detected=""

    if [[ -f "$config_file" ]]; then
        detected="$(sed -nE 's/^[[:space:]]*terminalTheme[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*$/\1/p' "$config_file" | head -n 1 | tr '[:upper:]' '[:lower:]')"
    fi

    case "$detected" in
        dracula|gruvbox)
            printf '%s\n' "$detected"
            ;;
        *)
            printf '%s\n' "gruvbox"
            ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --font)
            [[ $# -ge 2 ]] || { echo "Missing value for --font"; usage; exit 1; }
            FONT_CHOICE="$2"
            shift 2
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

FONT_CHOICE="$(normalize_font_choice "$FONT_CHOICE")"
if [[ "$FONT_CHOICE" == "auto" ]]; then
    if [[ "$(detect_theme)" == "dracula" ]]; then
        FONT_CHOICE="fira"
    else
        FONT_CHOICE="meslo"
    fi
fi

case "$FONT_CHOICE" in
    fira|firacode)
        FONT_LABEL="FiraCode"
        ZIP_NAME="FiraCode.zip"
        EXTRACT_DIR="FiraCode"
        ;;
    meslo)
        FONT_LABEL="Meslo"
        ZIP_NAME="Meslo.zip"
        EXTRACT_DIR="Meslo"
        ;;
    *)
        FONT_LABEL="Meslo"
        ZIP_NAME="Meslo.zip"
        EXTRACT_DIR="Meslo"
        ;;
esac

echo "📦 Downloading ${FONT_LABEL} Nerd Font..."

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "❌ Not running in WSL. This script is for WSL only."
    exit 1
fi

WIN_USERPROFILE=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
WIN_DOWNLOADS="$WIN_USERPROFILE\\Downloads\\NerdFonts"
WSL_DOWNLOADS=$(wslpath "$WIN_DOWNLOADS" 2>/dev/null || echo "$HOME/Downloads/NerdFonts")

mkdir -p "$WSL_DOWNLOADS"

FONT_VERSION="v3.1.1"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${ZIP_NAME}"
ZIP_PATH="$WSL_DOWNLOADS/$ZIP_NAME"
TARGET_DIR="$WSL_DOWNLOADS/$EXTRACT_DIR"

echo "⬇️  Downloading from: $FONT_URL"

if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$ZIP_PATH" "$FONT_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "$ZIP_PATH" "$FONT_URL"
else
    echo "❌ Neither wget nor curl found. Please install one of them."
    exit 1
fi

echo "📦 Extracting fonts..."
unzip -q -o "$ZIP_PATH" -d "$TARGET_DIR"
rm -f "$ZIP_PATH"
find "$TARGET_DIR" -type f ! -name "*.ttf" -delete

echo ""
echo "✅ Fonts downloaded successfully!"
echo "📁 Location: $(wslpath -w "$TARGET_DIR")"

cat > "$WSL_DOWNLOADS/install-fonts.ps1" <<'POSH'
# PowerShell script to install Nerd Fonts
# Run as Administrator

$FontsFolder = "$env:USERPROFILE\Downloads\NerdFonts"
$FONTS = 0x14

Write-Host "Installing Nerd Fonts from $FontsFolder ..." -ForegroundColor Green

$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($FONTS)

Get-ChildItem -Path $FontsFolder -Filter "*.ttf" -Recurse | ForEach-Object {
    Write-Host "Installing: $($_.Name)" -ForegroundColor Cyan
    $objFolder.CopyHere($_.FullName, 0x10)
}

Write-Host ""
Write-Host "✅ Fonts installed successfully!" -ForegroundColor Green
Write-Host "Please restart Windows Terminal and VS Code to apply changes." -ForegroundColor Yellow
POSH

echo ""
echo "🔧 Next steps:"
echo "   1. Open PowerShell as Administrator"
echo "   2. Run: powershell.exe -File $(wslpath -w "$WSL_DOWNLOADS")\\install-fonts.ps1"
echo ""
echo "📝 PowerShell script created: $(wslpath -w "$WSL_DOWNLOADS/install-fonts.ps1")"
