# Dotfiles (macOS + WSL2 Ubuntu)

Modern, security-focused dotfiles managed by [chezmoi](https://www.chezmoi.io/) with automatic work/personal machine detection.

Built for MSSP/SOC workflows: Ansible automation, Kubernetes management, multi-customer environment support, and 1Password secret integration.

## Features

- **Shell**: zsh with Starship prompt showing customer context, K8s cluster, AWS profile
- **Package management**: mise for runtime versions, Homebrew (macOS) / apt (Linux) for system packages
- **Secrets**: 1Password CLI + direnv for per-project secrets (personal machines)
- **Security**: gitleaks, trivy, checkov, pre-commit, git-secrets
- **Ansible**: Vault helpers, inventory shortcuts, linting
- **Kubernetes**: kubectl, kubectx/kubens, helm, k9s (latest versions auto-fetched from GitHub)
- **Modern CLI**: bat, eza, ripgrep, fd, fzf, zoxide
- **Tmux**: Session management with customer context in status bar
- **WSL terminal UX**: Automatic Windows Terminal profile merge (non-destructive) with WSL as default profile

## Quick Start

### Fresh WSL2 Ubuntu Setup

```bash
# 1. Run the bootstrap script (installs curl, git, chezmoi)
curl -fsSL https://raw.githubusercontent.com/A-Stroem/dotfiles/main/scripts/bootstrap-from-zero-wsl.sh | bash

# 2. Initialize dotfiles — you'll be prompted for machine type, name, and emails
~/.local/bin/chezmoi init --apply git@github.com:A-Stroem/dotfiles.git

# 3. Restart your shell
exec zsh
```

On WSL, `chezmoi apply` also merges a managed Windows Terminal WSL profile and sets it as default without overwriting your existing profiles.
Set Windows' **Default terminal application** to **Windows Terminal** once in Windows Terminal > Settings > Startup.

### Fresh macOS Setup

```bash
# 1. Run the bootstrap script (installs Homebrew, git, chezmoi)
curl -fsSL https://raw.githubusercontent.com/A-Stroem/dotfiles/main/scripts/bootstrap-from-zero-mac.sh | bash

# 2. Initialize dotfiles — you'll be prompted for machine type, name, and emails
chezmoi init --apply git@github.com:A-Stroem/dotfiles.git

# 3. Restart your shell
exec zsh
```

During `chezmoi init` you will be prompted for:

| Prompt | Example | Purpose |
|--------|---------|---------|
| Machine type | `work` or `personal` | Controls which tools are installed and which git email is default |
| Your full name | `Anders Stroem` | Used in gitconfig |
| Personal email | `anders@personal.com` | Default git email on personal machines |
| Work email | `anders@company.com` | Default git email on work machines, or `~/work/` repos on personal machines |

These values are saved in `~/.config/chezmoi/chezmoi.toml` and only prompted once. To re-prompt later: `chezmoi init --prompt`.

## Repository Structure

```
dotfiles/
├── .chezmoi.toml.tmpl                         # Chezmoi config template (prompts for machine type, emails)
├── .chezmoiignore                             # Files excluded from home directory
├── dot_zshrc.tmpl                             # Main shell config (templated)
├── dot_gitconfig.tmpl                         # Git config (templated — adapts to work/personal)
├── dot_gitconfig-work                         # Git includeIf config for ~/work/ repos
├── dot_gitattributes                          # Git attributes
├── dot_tmux.conf                              # tmux configuration
├── dot_config/
│   ├── starship.toml                          # Starship prompt config
│   ├── mise/config.toml                       # Runtime version management
│   └── direnv/direnvrc.tmpl                   # Shared direnv helpers (templated)
├── private_dot_ssh/
│   └── config                                 # SSH config
├── run_onchange_install-core.sh.tmpl          # Core packages (apt/brew, kubectl, k9s, helm, etc.)
├── run_onchange_install-security.sh.tmpl      # Security tools (gitleaks, trivy, checkov, pre-commit)
├── run_onchange_install-1password-cli.sh.tmpl # 1Password CLI (personal machines only)
├── run_onchange_install-work-tools.sh.tmpl    # Company-specific tools (work machines only)
├── run_onchange_install-windows-terminal.sh.tmpl # WSL-only Windows Terminal profile merge
├── example-personal.envrc                     # Example .envrc with 1Password integration
├── example-work.envrc                         # Example .envrc with file-based secrets
└── scripts/
    ├── bootstrap-from-zero-wsl.sh             # WSL bootstrap (curl, git, chezmoi)
    ├── bootstrap-from-zero-mac.sh             # macOS bootstrap (Homebrew, git, chezmoi)
    ├── download-nerd-font.sh                  # Nerd Font installer
    └── install-windows-terminal-settings.sh   # Windows Terminal profile merge installer
```

Key naming conventions:
- `dot_` prefix → becomes a dotfile in `~/` (e.g., `dot_zshrc.tmpl` → `~/.zshrc`)
- `.tmpl` suffix → processed as a Go template by chezmoi
- `run_onchange_` prefix → re-runs whenever the script content changes
- `private_dot_` prefix → applied with `0600` permissions

## Post-Install Configuration

### 1. GPG Commit Signing

```bash
gpg --full-generate-key           # Generate key (RSA 4096, 2 year expiry)
gpg --list-secret-keys --keyid-format=long   # Find your key ID
git config --global user.signingkey YOUR_KEY_ID
echo "test" | gpg --clearsign     # Verify it works
```

### 2. 1Password CLI (Personal Machines)

```bash
op signin                         # Sign in
op item list                      # Verify access
```

### 3. Work/Personal Git Switching

On **personal machines**, git email switches automatically:
- Repos in `~/work/` use your work email (via `includeIf` in gitconfig)
- All other repos use your personal email

```bash
mkdir -p ~/work
cd ~/work && git clone git@github.com:company/repo.git
cd repo && git config user.email   # → work email
cd ~ && git config user.email      # → personal email
```

## Secrets Management

### Personal Machines (1Password)

```bash
# Example .envrc in ~/work/customer-acme/
export CUSTOMER_CONTEXT="acme-corp"
export ELASTIC_API_KEY=$(op read "op://Work/Elastic-ACME/api-key")
export AWS_PROFILE="acme-prod"
```

### Work Machines (File/Command-Based)

```bash
# Example .envrc
export API_KEY=$(cat ~/.secrets/api-key)
# Or: export API_KEY=$(company-secrets get api-key)
```

## Daily Workflow

```bash
chezmoi edit ~/.zshrc              # Edit a managed config
chezmoi diff                       # Preview changes
chezmoi apply                      # Apply to home directory
chezmoi update                     # Pull from git + apply (on another machine)

# Commit changes back
chezmoi cd                         # cd into source directory
git add . && git commit -m "Update aliases" && git push
exit
```

## Shell Aliases

### Git
| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gcb` | fuzzy branch checkout |

### Kubernetes
| Alias | Command |
|-------|---------|
| `k` | `kubectl` |
| `kx` | `kubectx` (switch context) |
| `kn` | `kubens` (switch namespace) |
| `kwhere` | Show current context/namespace |

### Ansible
| Alias | Command |
|-------|---------|
| `ap` | `ansible-playbook --diff` |
| `ave` | `ansible-vault edit` |
| `avv` | `ansible-vault view` |
| `ap-op` | ansible-playbook with 1Password vault password |

### Docker
| Alias | Command |
|-------|---------|
| `d` | `docker` |
| `dc` | `docker compose` |
| `dcu` | `docker compose up` |
| `dcd` | `docker compose down` |

### Security
| Alias | Command |
|-------|---------|
| `scan-secrets` | `gitleaks detect` |
| `scan-ansible` | `checkov` scan |
| `safety-check` | Run all security scans |

## Troubleshooting

### chezmoi prompts not appearing

`promptStringOnce` only runs during `chezmoi init`, not `chezmoi apply`. To re-trigger prompts:

```bash
chezmoi init --prompt --apply
```

### WSL2 DNS issues

```bash
sudo rm /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
```

### Shell not changing to zsh

```bash
chsh -s $(which zsh)
# Restart terminal
```

### Windows Terminal did not switch to WSL profile

The merge is automatic on WSL during `chezmoi apply` and preserves existing profiles.

If Windows Terminal was never opened before, open it once and run:

```bash
chezmoi apply
```

Or run the installer directly:

```bash
bash ~/.local/share/chezmoi/scripts/install-windows-terminal-settings.sh
```

### Force re-run of install scripts

Since scripts use `run_onchange_`, they re-run automatically when you edit them. To force a full re-run:

```bash
rm ~/.config/chezmoi/chezmoistate.boltdb
chezmoi apply
```

## Learn More

- [chezmoi documentation](https://www.chezmoi.io/)
- [Starship prompt](https://starship.rs/)
- [1Password CLI](https://developer.1password.com/docs/cli/)
- [direnv](https://direnv.net/)
- [mise](https://mise.jdx.dev/)
