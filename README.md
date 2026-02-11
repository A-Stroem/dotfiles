# 🏠 Dotfiles (macOS + WSL2 Ubuntu)

Modern, security-focused dotfiles for MSSP/SOC workflows with Ansible automation, Kubernetes management, and multi-customer environment support.

## ✨ Features

- **🐚 Shell**: zsh with Starship prompt showing customer context, K8s cluster, AWS profile
- **📦 Package Management**: mise for runtime versions, Homebrew/apt for system packages
- **🔐 Secrets**: 1Password CLI integration with direnv for per-project secrets
- **🔒 Security**: gitleaks, trivy, checkov for scanning; GPG commit signing
- **⚙️ Ansible**: Vault helpers, inventory shortcuts, linting
- **☸️ Kubernetes**: kubectx/kubens, context awareness in prompt
- **🔧 Modern CLI**: bat, eza, ripgrep, fd, fzf, zoxide
- **📝 Session Management**: tmux with customer context in status bar

## 🚀 Quick Start

### First Time Setup (WSL2 Ubuntu)

```bash
# 1. Bootstrap system
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/scripts/bootstrap-from-zero-wsl.sh | bash

# 2. Initialize dotfiles
~/.local/bin/chezmoi init --apply git@github.com:YOUR_USERNAME/dotfiles.git

# 3. Restart shell
exec zsh
```

### First Time Setup (macOS)

```bash
# 1. Bootstrap system
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/scripts/bootstrap-from-zero-mac.sh | bash

# 2. Initialize dotfiles
chezmoi init --apply git@github.com:YOUR_USERNAME/dotfiles.git

# 3. Restart shell
exec zsh
```

## 📁 Structure

```
dotfiles/
├── dot_zshrc                               # Main shell config
├── dot_gitconfig                           # Git config (personal)
├── dot_gitconfig-work                      # Git config (work - auto-loaded)
├── dot_gitattributes                       # Git attributes
├── dot_tmux.conf                           # tmux config
├── dot_chezmoiignore                       # Files to not manage
├── dot_chezmoi.toml.tmpl                   # Chezmoi settings
├── dot_config/
│   ├── starship.toml                       # Prompt config
│   ├── mise/config.toml                    # Runtime versions
│   └── direnv/
│       └── direnvrc                        # Shared direnv helpers
├── private_dot_ssh/
│   └── config                              # SSH config (encrypted)
├── run_once_install-core.sh.tmpl          # Core package install
├── run_once_install-1password-cli.sh.tmpl # 1Password CLI install
├── run_once_install-security.sh.tmpl      # Security tools install
└── scripts/
    ├── bootstrap-from-zero-wsl.sh          # WSL bootstrap
    └── bootstrap-from-zero-mac.sh          # macOS bootstrap
```

## 🔧 Post-Install Configuration

### 1. Set Up GPG Signing

```bash
# Generate GPG key
gpg --full-generate-key

# List keys and get your key ID
gpg --list-secret-keys --keyid-format=long

# Configure git
git config --global user.signingkey YOUR_KEY_ID

# Test signing
echo "test" | gpg --clearsign
```

### 2. Configure 1Password CLI

```bash
# Sign in to 1Password
op signin

# Test it works
op item list

# Add secrets to 1Password vaults:
# - Create "Work" vault for work secrets
# - Create "Private" vault for personal secrets
```

### 3. Set Up Work/Personal Git Switching

```bash
# Create work directory
mkdir -p ~/work

# Clone a work repo there
cd ~/work
git clone git@github.com:company/repo.git

# Verify work email is used
cd repo
git config user.email  # Should show work email

# Personal repos outside ~/work/ use personal email
cd ~
git config user.email  # Should show personal email
```

### 4. Update Personal Information

Edit these files with your actual information:

```bash
# Edit git config
chezmoi edit ~/.gitconfig
# Update: name, email

# Edit work git config
chezmoi edit ~/.gitconfig-work
# Update: email

# Apply changes
chezmoi apply
```

## 🔐 Secrets Management

### Project .envrc Example (Customer Project)

```bash
# .envrc in ~/work/customer-acme/

# Set customer context (shows in prompt!)
export CUSTOMER_CONTEXT="acme-corp"

# Load secrets from 1Password
export ELASTIC_API_KEY=$(op read "op://Work/Elastic-ACME/api-key")
export KIBANA_URL=$(op read "op://Work/Elastic-ACME/kibana-url")
export ANSIBLE_VAULT_OP_ITEM="op://Work/Ansible-ACME/vault-password"

# AWS profile for this customer
export AWS_PROFILE="acme-prod"

# K8s context for this customer
kubectl config use-context "acme-prod" 2>/dev/null || true
```

### Ansible Vault with 1Password

```bash
# Store vault password in 1Password
# Then reference it in .envrc:
export ANSIBLE_VAULT_OP_ITEM="op://Work/Ansible-Vault/password"

# Use the helper function
ap-op playbook.yml  # Automatically reads vault password from 1Password
```

## 📝 Daily Workflow

### Making Changes

```bash
# Edit a config
chezmoi edit ~/.zshrc

# See what would change
chezmoi diff

# Apply changes
chezmoi apply

# Commit and push
chezmoi cd
git add .
git commit -m "Add new alias"
git push
exit
```

### Pulling Updates on Another Machine

```bash
# One command to pull and apply
chezmoi update
```

### Adding New Files

```bash
# Add a new config to be managed
chezmoi add ~/.config/nvim/init.vim

# It's now tracked and will sync across machines
```

## 🛠️ Useful Commands

### Shell Aliases

```bash
# Git
gs          # git status
ga          # git add
gc          # git commit
gcb         # fuzzy checkout branch

# Ansible
ap          # ansible-playbook --diff
ave <file>  # ansible-vault edit
avv <file>  # ansible-vault view
ap-op       # ansible-playbook with 1Password vault password

# Kubernetes
k           # kubectl
kx          # kubectx (switch context)
kn          # kubens (switch namespace)
kwhere      # show current context/namespace

# Docker
d           # docker
dc          # docker compose
dcu         # docker compose up
dcd         # docker compose down

# Security
scan-secrets    # gitleaks scan
scan-ansible    # checkov scan for Ansible
safety-check    # run all security scans

# Customer context
set-customer <name>   # Set customer context (shows in prompt)
unset-customer        # Clear customer context
show-customer         # Show current customer
```

### Chezmoi Commands

```bash
chezmoi init                # Initialize chezmoi
chezmoi add <file>          # Add file to be managed
chezmoi edit <file>         # Edit managed file
chezmoi apply               # Apply all changes
chezmoi diff                # Show what would change
chezmoi update              # Pull from git and apply
chezmoi cd                  # Go to source directory
chezmoi managed             # List managed files
```

## 🔒 Security Best Practices

### Pre-Commit Checks

Set up pre-commit hooks in your repositories:

```bash
# In your repo
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: trailing-whitespace
EOF

# Install hooks
pre-commit install
```

### Never Commit These

❌ **NEVER commit:**
- SSH private keys
- API tokens/passwords
- Customer credentials
- `.envrc` files with real secrets
- Ansible vault passwords

✅ **Instead:**
- Store secrets in 1Password
- Reference them via `op read` in `.envrc`
- Use git-crypt for SSH keys if needed
- Keep `.envrc` in `.chezmoiignore`

## 🆘 Troubleshooting

### WSL2 DNS Issues

```bash
# If experiencing DNS problems
sudo rm /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
```

### Shell Not Changing to zsh

```bash
# Manually change shell
chsh -s $(which zsh)
# Then restart terminal
```

### 1Password CLI Not Working

```bash
# Sign in again
op signin

# Check status
op account list
```

### Chezmoi Changes Not Applying

```bash
# Force rerun of scripts
rm ~/.config/chezmoi/chezmoistate.boltdb
chezmoi apply

# Or manually run scripts
bash ~/.local/share/chezmoi/run_once_install-core.sh.tmpl
```

## 📚 Learn More

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Starship Prompt](https://starship.rs/)
- [1Password CLI](https://developer.1password.com/docs/cli/)
- [direnv](https://direnv.net/)
- [mise](https://mise.jdx.dev/)

## 🤝 Contributing

Feel free to fork and customize for your own use!

## 📄 License

MIT License - use freely!
