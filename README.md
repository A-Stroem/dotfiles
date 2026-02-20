# Dotfiles (macOS + WSL2 Ubuntu)

Security-focused, automation-first dotfiles managed by [chezmoi](https://www.chezmoi.io/).

This repo configures shell, git, dev tooling, security scanners, Kubernetes tooling, and terminal/VS Code theme consistency.

## Features

- zsh + Starship prompt for context-heavy workflows
- Homebrew (macOS) and apt (WSL/Linux) install automation
- Networking toolkit automation (`nslookup`, `tcpdump`, `nmap`, `mtr`, `iperf3`)
- mise runtime management (Node/Python/etc)
- Security tooling: gitleaks, trivy, checkov, pre-commit, git-secrets
- Terminal + editor theming with **Gruvbox** or **Dracula**
- Ghostty config managed by chezmoi
- VS Code settings merge for macOS/Linux/WSL + Windows user settings (from WSL)
- Windows Terminal managed profile merge in WSL

## Prerequisites

- GitHub SSH access configured (`ssh -T git@github.com`)
- 1Password app + SSH agent enabled if you use 1Password-managed keys
- macOS: Homebrew available (bootstrap script installs it if missing)
- WSL: Ubuntu/Debian with sudo access

## Fresh Setup

### macOS

```bash
# From remote script
curl -fsSL https://raw.githubusercontent.com/A-Stroem/dotfiles/main/scripts/bootstrap-from-zero-mac.sh | bash

# Or from local clone
bash /Users/andersstrom/dev/infrastructure/dotfiles/scripts/bootstrap-from-zero-mac.sh

# Apply dotfiles
chezmoi init --apply git@github.com:A-Stroem/dotfiles.git

# Restart shell
exec zsh
```

### WSL2 Ubuntu

```bash
# From remote script
curl -fsSL https://raw.githubusercontent.com/A-Stroem/dotfiles/main/scripts/bootstrap-from-zero-wsl.sh | bash

# Or from local clone
bash /Users/andersstrom/dev/infrastructure/dotfiles/scripts/bootstrap-from-zero-wsl.sh

# Apply dotfiles
~/.local/bin/chezmoi init --apply git@github.com:A-Stroem/dotfiles.git

# Restart shell
exec zsh
```

## Initial Prompts

During first `chezmoi init --apply`, you are prompted for:

- `machineType`: `work` or `personal`
- `name`
- `personalEmail`
- `workEmail`
- `terminalTheme`: `dracula` or `gruvbox`

Values are stored in `~/.config/chezmoi/chezmoi.toml`.

## Theme Management

### Option 1: Choose during bootstrap

Set `terminalTheme` when prompted by chezmoi.

### Option 2: Switch later

```bash
bash ~/.local/share/chezmoi/scripts/toggle-theme.sh
bash ~/.local/share/chezmoi/scripts/toggle-theme.sh dracula
bash ~/.local/share/chezmoi/scripts/toggle-theme.sh gruvbox
```

What theme switch updates:

- `~/.config/ghostty/config`
- VS Code terminal color customizations
- Windows Terminal managed profile/scheme (WSL)

## Post-Install Checklist

```bash
# Verify tools
starship --version
mise --version
command -v nslookup
tcpdump --version
kubectl version --client
helm version --short
k9s version --short

# Security tools
gitleaks version
trivy version
checkov --version

# Git identity
git config user.name
git config user.email
```

Optional:

```bash
# GPG signing
gpg --full-generate-key
git config --global user.signingkey YOUR_KEY_ID

# 1Password CLI signin
op signin
```

## Repository Bootstrap (for any git repo)

Use this helper script to install hooks, commit, and push:

```bash
scripts/bootstrap-repo.sh
scripts/bootstrap-repo.sh -m "chore: update repo tooling"
```

Details: [docs/repo-bootstrap.md](docs/repo-bootstrap.md)

## Tool Documentation

Per-tool usage docs are in `docs/tools/`.

Start here: [docs/README.md](docs/README.md)

## Repository Layout

```text
dotfiles/
├── .chezmoi.toml.tmpl
├── dot_zshrc.tmpl
├── dot_gitconfig.tmpl
├── dot_tmux.conf
├── dot_config/
│   ├── ghostty/config.tmpl
│   ├── starship.toml
│   ├── mise/config.toml
│   └── direnv/direnvrc.tmpl
├── private_dot_ssh/config.tmpl
├── run_onchange_install-core.sh.tmpl
├── run_onchange_install-security.sh.tmpl
├── run_onchange_install-1password-cli.sh.tmpl
├── run_onchange_install-vscode-settings.sh.tmpl
├── run_onchange_install-windows-terminal.sh.tmpl
├── run_zz_print-final-notes.sh.tmpl
├── scripts/
│   ├── bootstrap-from-zero-mac.sh
│   ├── bootstrap-from-zero-wsl.sh
│   ├── bootstrap-repo.sh
│   ├── toggle-theme.sh
│   ├── install-vscode-settings.sh
│   ├── install-windows-terminal-settings.sh
│   └── download-nerd-font.sh
└── docs/
    ├── README.md
    ├── theme-switching.md
    ├── repo-bootstrap.md
    └── tools/
```

## Troubleshooting

### `brew update` fails with git ref or SSH key errors

Run:

```bash
brew untap homebrew/core
brew tap homebrew/core
brew update
```

### GitHub SSH auth fails

```bash
ssh -T git@github.com
ssh -G github.com | rg 'identityagent|identitiesonly'
```

Expected with 1Password: `identityagent` points to `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`.

### Theme did not update

```bash
bash ~/.local/share/chezmoi/scripts/toggle-theme.sh
chezmoi apply --force
```

Restart Ghostty and VS Code.
