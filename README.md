# dotfiles

## Purpose

Chezmoi-managed development environment for macOS and WSL2 with security-focused defaults.

## Role in Workspace

### Core (always installed)

- zsh + Starship prompt for context-heavy workflows
- Homebrew (macOS) and apt (WSL/Linux) install automation
- mise runtime management (Node/Python/etc)
- Terminal + editor theming with **Gruvbox** or **Dracula**
- Ghostty config managed by chezmoi
- VS Code settings merge for macOS/Linux/WSL + Windows user settings (from WSL)
- Windows Terminal managed profile merge in WSL

### Optional profiles (opt-in at `chezmoi init`)

- Security scanning tools (gitleaks, trivy, checkov, pre-commit, git-secrets) — on by default
- Container tooling (Docker)
- Kubernetes tooling (kubectl, kubectx, helm, k9s)
- Networking toolkit (nslookup/dig, tcpdump, nmap, mtr, iperf3, whois)
- Ansible + ansible-lint
- zellij (local-machine terminal multiplexer; tmux stays in core for remote/server use)

Full breakdown, including which script installs what: see
[docs/install-profiles.md](docs/install-profiles.md).

## Machine Type & Profiles

Setup is driven by two independent sets of prompts at `chezmoi init`, both
changeable later via `chezmoi init --prompt --apply`:

- **Machine type** (`work` or `personal`) — controls git email defaults,
  1Password CLI vs. work-tools installation, and secret-loading strategy.
  See [WORK_VS_PERSONAL.md](WORK_VS_PERSONAL.md).
- **Install profiles** — which optional toolchains (Kubernetes, containers,
  networking, Ansible, security scanning, zellij) get installed on top of
  core. See [docs/install-profiles.md](docs/install-profiles.md).

## Quick Start

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/A-Stroem/dotfiles/main/scripts/bootstrap-from-zero-mac.sh | bash
chezmoi init --apply git@github.com:A-Stroem/dotfiles.git
exec zsh
```

### WSL2

```bash
curl -fsSL https://raw.githubusercontent.com/A-Stroem/dotfiles/main/scripts/bootstrap-from-zero-wsl.sh | bash
~/.local/bin/chezmoi init --apply git@github.com:A-Stroem/dotfiles.git
exec zsh
```

## Common Commands

```bash
# Re-apply config
chezmoi apply

# Re-run prompts (machine type, theme, install profiles)
chezmoi init --prompt --apply

# Switch terminal theme
bash ~/.local/share/chezmoi/scripts/toggle-theme.sh

# Bootstrap hooks/tooling in a repo
scripts/bootstrap-repo.sh
```

## Validation

```bash
# Core (always installed)
starship --version
mise --version

# Security tools (installSecurityTools, default on)
gitleaks version
trivy version
checkov --version

# Kubernetes tools (installKubernetesTools)
kubectl version --client
helm version --short
k9s version --short

# Networking toolkit (installNetworkingTools)
command -v nslookup
tcpdump --version

# Container tooling (installContainerTools)
docker --version

# Ansible (installAnsible)
ansible --version

# zellij (installZellij)
zellij --version
```

## Key Paths

- `scripts/`
- `docs/`
- `dot_config/`

## Related Docs

- [docs/README.md](docs/README.md) — per-tool quick-reference guides
- [docs/install-profiles.md](docs/install-profiles.md) — core vs. opt-in install profiles
- [WORK_VS_PERSONAL.md](WORK_VS_PERSONAL.md) — work vs. personal machine behavior
- [docs/repo-bootstrap.md](docs/repo-bootstrap.md)
- [docs/theme-switching.md](docs/theme-switching.md)
