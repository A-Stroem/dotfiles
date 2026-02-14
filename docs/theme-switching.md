# Theme Switching

Script: `scripts/toggle-theme.sh`

## Supported themes

- `gruvbox`
- `dracula`

## Syntax

```bash
scripts/toggle-theme.sh [dracula|gruvbox|toggle]
```

## Examples

```bash
scripts/toggle-theme.sh
scripts/toggle-theme.sh dracula
scripts/toggle-theme.sh gruvbox
```

## What it updates

- `~/.config/chezmoi/chezmoi.toml` (`data.terminalTheme`)
- Ghostty config (via `chezmoi apply`)
- VS Code settings merge script
- Windows Terminal settings merge script (when run in WSL)
