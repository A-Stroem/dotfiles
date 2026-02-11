#!/usr/bin/env bash
# ============================================================
# Download Nerd Font to Windows Downloads folder
# ============================================================

set -euo pipefail

echo "📦 Downloading FiraCode Nerd Font..."

# Detect Windows user profile path
if grep -qi microsoft /proc/version 2>/dev/null; then
    # We're in WSL - find Windows Downloads folder
    WIN_USERPROFILE=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
    WIN_DOWNLOADS="$WIN_USERPROFILE\\Downloads\\NerdFonts"
    
    # Convert to WSL path
    WSL_DOWNLOADS=$(wslpath "$WIN_DOWNLOADS" 2>/dev/null || echo "$HOME/Downloads/NerdFonts")
    
    echo "📁 Creating directory: $WSL_DOWNLOADS"
    mkdir -p "$WSL_DOWNLOADS"
    
    # Download FiraCode Nerd Font
    FONT_VERSION="v3.1.1"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/FiraCode.zip"
    
    echo "⬇️  Downloading from: $FONT_URL"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$WSL_DOWNLOADS/FiraCode.zip" "$FONT_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$WSL_DOWNLOADS/FiraCode.zip" "$FONT_URL"
    else
        echo "❌ Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    echo "📦 Extracting fonts..."
    unzip -q -o "$WSL_DOWNLOADS/FiraCode.zip" -d "$WSL_DOWNLOADS/FiraCode"
    
    # Remove the zip file
    rm "$WSL_DOWNLOADS/FiraCode.zip"
    
    # Remove unnecessary files (keep only TTF files)
    find "$WSL_DOWNLOADS/FiraCode" -type f ! -name "*.ttf" -delete
    
    echo ""
    echo "✅ Fonts downloaded successfully!"
    echo ""
    echo "📁 Location: $(wslpath -w "$WSL_DOWNLOADS/FiraCode")"
    echo ""
    echo "🔧 Next steps:"
    echo "   1. Open PowerShell as Administrator"
    echo "   2. Run this command:"
    echo ""
    echo "      powershell.exe -File $(wslpath -w "$WSL_DOWNLOADS")/install-fonts.ps1"
    echo ""
    echo "   Or manually:"
    echo "   - Open the folder above in Windows Explorer"
    echo "   - Select all .ttf files"
    echo "   - Right-click → 'Install for all users'"
    
    # Create PowerShell install script
    cat > "$WSL_DOWNLOADS/install-fonts.ps1" << 'POSH'
# PowerShell script to install Nerd Fonts
# Run as Administrator

$FontsFolder = "$env:USERPROFILE\Downloads\NerdFonts\FiraCode"
$FONTS = 0x14

Write-Host "Installing FiraCode Nerd Font..." -ForegroundColor Green

$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($FONTS)

Get-ChildItem -Path $FontsFolder -Filter "*.ttf" | ForEach-Object {
    Write-Host "Installing: $($_.Name)" -ForegroundColor Cyan
    $objFolder.CopyHere($_.FullName, 0x10)
}

Write-Host ""
Write-Host "✅ Fonts installed successfully!" -ForegroundColor Green
Write-Host "Please restart Windows Terminal to apply changes." -ForegroundColor Yellow
POSH
    
    echo ""
    echo "📝 PowerShell script created: $(wslpath -w "$WSL_DOWNLOADS/install-fonts.ps1")"
    
else
    echo "❌ Not running in WSL. This script is for WSL only."
    exit 1
fi
