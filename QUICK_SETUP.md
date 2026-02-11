# 🚀 Quick Setup Guide

## Part 1: First Time Setup on WSL2 Ubuntu

### Step 1: Download All Dotfiles
Download all artifact files from Claude into a folder on your computer.

### Step 2: Bootstrap WSL2
```bash
# Open WSL2 Ubuntu terminal
# Update system
sudo apt update && sudo apt upgrade -y

# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

### Step 3: Initialize Chezmoi
```bash
# Initialize chezmoi
chezmoi init
cd ~/.local/share/chezmoi
```

### Step 4: Copy Dotfiles
Copy all the downloaded files into `~/.local/share/chezmoi/` maintaining the structure:
- `dot_*` files go in the root
- `dot_config/` directory with starship.toml, mise/, direnv/
- `private_dot_ssh/` directory with config
- `run_once_*` scripts in root
- `scripts/` directory with bootstrap scripts

### Step 5: Update Personal Info
```bash
# Edit with your information
vim ~/.local/share/chezmoi/dot_gitconfig
# Change: name and email

vim ~/.local/share/chezmoi/dot_gitconfig-work
# Change: work email
```

### Step 6: Create Git Repo
```bash
# Still in ~/.local/share/chezmoi
git init
git add .
git commit -m "Initial dotfiles: zsh, tmux, starship, security"

# Create repo on GitHub, then:
git remote add origin git@github.com:YOUR_USERNAME/dotfiles.git
git branch -M main
git push -u origin main
```

### Step 7: Apply Dotfiles
```bash
cd ~
chezmoi apply -v

# This will:
# - Copy all dot_* files to ~/
# - Run all installation scripts
# - Set up your environment

# Restart shell
exec zsh
```

### Step 8: Post-Install Configuration
```bash
# 1. Generate GPG key for commit signing
gpg --full-generate-key
# Choose RSA 4096, valid for 2 years
# Use your work email

# 2. Configure git to use GPG key
gpg --list-secret-keys --keyid-format=long
# Note the key ID (after rsa4096/)
git config --global user.signingkey YOUR_KEY_ID

# 3. Set up 1Password CLI
op signin
# Follow prompts to sign in

# 4. Create work directory
mkdir -p ~/work

# 5. Create SSH sockets directory
mkdir -p ~/.ssh/sockets

# 6. Generate SSH key if needed
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### Step 9: Test Everything
```bash
# Test shell
which zsh
echo $SHELL

# Test tools
starship --version
mise --version
direnv version
tmux -V
kubectl version --client
ansible --version

# Test 1Password
op item list

# Test git signing
echo "test" | gpg --clearsign

# Test security tools
gitleaks version
trivy version
checkov --version
```

---

## Part 2: Setup on macOS

### Step 1: Bootstrap macOS
```bash
# Open Terminal.app
# Run bootstrap script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi
```

### Step 2: Pull and Apply Dotfiles
```bash
# One command to set everything up!
chezmoi init --apply git@github.com:YOUR_USERNAME/dotfiles.git

# Restart shell
exec zsh
```

### Step 3: macOS-Specific Setup
```bash
# Install Ghostty (if using)
brew install --cask ghostty

# Set up 1Password CLI
op signin

# Set up GPG (same as WSL)
gpg --full-generate-key
gpg --list-secret-keys --keyid-format=long
git config --global user.signingkey YOUR_KEY_ID
```

---

## Part 3: Daily Usage

### Making Changes
```bash
# Edit a config
chezmoi edit ~/.zshrc

# Apply changes
chezmoi apply

# Commit to git
chezmoi cd
git add .
git commit -m "Update aliases"
git push
exit
```

### Syncing to Another Machine
```bash
chezmoi update
```

### Using Customer Contexts
```bash
# In a customer project directory
cd ~/work/customer-acme

# Create .envrc (copy from example.envrc)
cp /path/to/example.envrc .envrc

# Edit with customer-specific secrets
vim .envrc

# Allow direnv to load it
direnv allow

# Your prompt now shows: 🏢 acme-corp
```

### Security Scanning Before Commits
```bash
# In any repo
safety-check

# Or individual scans
scan-secrets      # gitleaks
scan-ansible      # checkov
trivy fs .        # trivy
```

---

## Common Issues

### Issue: zsh not default shell
```bash
chsh -s $(which zsh)
# Restart terminal
```

### Issue: 1Password CLI not working
```bash
op signin
op account list
```

### Issue: direnv not loading
```bash
direnv allow .
```

### Issue: kubectl context not switching
```bash
kubectl config get-contexts
kubectl config use-context <name>
```

---

## File Locations Reference

| What | Where |
|------|-------|
| Dotfiles source (git repo) | `~/.local/share/chezmoi/` |
| Actual configs | `~/` (home directory) |
| Chezmoi binary | `~/.local/bin/chezmoi` (Linux) or `/opt/homebrew/bin/chezmoi` (macOS) |
| SSH config | `~/.ssh/config` |
| Git config | `~/.gitconfig` |
| zsh config | `~/.zshrc` |

---

## Next Steps

1. ✅ Set up GPG signing
2. ✅ Configure 1Password CLI  
3. ✅ Create work directory structure
4. ✅ Add SSH keys to GitHub/GitLab
5. ✅ Set up pre-commit hooks in projects
6. ✅ Test customer context switching
7. ✅ Configure any work-specific tools

---

## Important Security Reminders

❌ **NEVER commit:**
- SSH private keys (unless using git-crypt)
- API tokens/passwords
- `.envrc` files with real secrets
- Ansible vault passwords
- Customer credentials

✅ **ALWAYS:**
- Use 1Password for secrets
- Run `safety-check` before pushing
- Sign your commits with GPG
- Use customer context for clarity
- Keep `.envrc` in `.gitignore`

---

**Need help?** Check the full README.md for detailed documentation.
