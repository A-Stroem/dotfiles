# 🏢 Work vs Personal Machine Configuration

## Overview

Your dotfiles now automatically detect and configure differently based on whether you're on a **work** or **personal** machine. This means:

- **Personal machines**: Get 1Password CLI, personal email, work/personal repo separation
- **Work machines**: Skip 1Password, use work email only, company-specific tools

## How Machine Detection Works

### Automatic Detection

When you first run `chezmoi init`, it checks your hostname:

```bash
# Detected as WORK if hostname contains:
- "work"
- "company"

# Detected as PERSONAL if hostname contains:
- "home"
- "personal"

# Otherwise, you'll be prompted:
Machine type (work/personal): _
```

### Manual Override

If your hostname doesn't match, chezmoi will ask you on first run. Your choice is saved in `~/.config/chezmoi/chezmoi.toml`.

To change later:
```bash
chezmoi edit-config

# Change this line:
isWork = false  # or true
isPersonal = true  # or false
```

## What's Different Per Machine Type

### Personal Machines

✅ **Installed:**
- 1Password CLI
- Personal git email as default
- `~/work/` directory for work repos (uses work email automatically)
- 1Password helper functions (`op-read`, `op-list-work`, etc.)
- Ansible vault integration with 1Password

✅ **Git behavior:**
- Default email: `personal@example.com`
- Repos in `~/work/`: automatically use `work@company.com`

### Work Machines

✅ **Installed:**
- Work-specific tools (customize in `run_once_install-work-tools.sh.tmpl`)
- Work git email only
- No 1Password (company likely has its own secrets management)
- Ansible vault from file instead of 1Password

❌ **NOT installed:**
- 1Password CLI
- 1Password helper functions

✅ **Git behavior:**
- Default email: `work@company.com`
- No special `~/work/` directory logic

## File Differences

### Files That Are Templated

These files behave differently based on machine type:

| File | Personal | Work |
|------|----------|------|
| `dot_gitconfig.tmpl` | Uses personal email, includeIf for ~/work/ | Uses work email only |
| `dot_zshrc.tmpl` | Includes 1Password helpers | No 1Password functions |
| `run_once_install-1password-cli.sh.tmpl` | Installs 1Password | Skips (no-op) |
| `run_once_install-work-tools.sh.tmpl` | Skips (no-op) | Installs company tools |

### Files That Are The Same

These work identically on both:
- All core tools (kubectl, ansible, etc.)
- Security scanning (gitleaks, trivy, checkov)
- tmux, starship, mise, direnv configs
- SSH config

## Setup Examples

### Example 1: Personal Laptop (WSL2)

```bash
# Hostname: home-desktop or personal-laptop
chezmoi init --apply git@github.com:YOUR_USERNAME/dotfiles.git

# Automatic detection → PERSONAL mode
# Result:
# - 1Password CLI installed
# - Personal email in git
# - Can use: op-read, ap-op commands
# - ~/work/ directory created for work repos
```

### Example 2: Work Laptop

```bash
# Hostname: work-laptop or company-macbook
chezmoi init --apply git@github.com:YOUR_USERNAME/dotfiles.git

# Automatic detection → WORK mode
# Result:
# - NO 1Password CLI
# - Work email in git
# - 1Password functions not available
# - Uses company secrets management instead
```

### Example 3: Ambiguous Hostname

```bash
# Hostname: anders-laptop (ambiguous)
chezmoi init --apply git@github.com:YOUR_USERNAME/dotfiles.git

# Prompted:
Machine type (work/personal): personal

# Your choice is saved for future runs
```

## Customizing Work-Specific Tools

Edit `run_once_install-work-tools.sh.tmpl` to add company tools:

```bash
{{- if .isWork -}}
#!/usr/bin/env bash
set -euo pipefail

# Example: Install company VPN
if ! command -v company-vpn >/dev/null 2>&1; then
  echo "📦 Installing company VPN..."
  # Your install commands
fi

# Example: Install company CLI
if ! command -v company-cli >/dev/null 2>&1; then
  echo "📦 Installing company CLI..."
  brew install company/tap/company-cli
fi

# Example: Configure company SSO
if [ ! -f ~/.aws/config ]; then
  echo "📦 Configuring AWS SSO..."
  aws configure sso
fi
{{- end -}}
```

## Testing Your Configuration

### Check Current Machine Type

```bash
# After applying dotfiles
echo $MACHINE_TYPE
# Output: "work" or "personal"

# Check git email
git config user.email
# Personal: personal@example.com
# Work: work@company.com
```

### Test 1Password (Personal Only)

```bash
# This should work on personal machines:
op-list-work

# On work machines, you'll see:
# ❌ 1Password CLI not installed
```

### Test Ansible Vault

```bash
# Personal machines:
ap-op playbook.yml  # Uses 1Password

# Work machines:
ap-vault .vault_pass playbook.yml  # Uses file
```

## Secrets Management Per Machine

### Personal Machines

Use 1Password for everything:

```bash
# .envrc in project
export API_KEY=$(op read "op://Work/Project/api-key")
export DB_PASSWORD=$(op read "op://Work/DB/password")
```

### Work Machines

Use whatever your company uses:

```bash
# Option 1: Vault files (gitignored)
export API_KEY=$(cat ~/.secrets/api-key)

# Option 2: Company secrets management
export API_KEY=$(company-secrets get api-key)

# Option 3: AWS Secrets Manager
export API_KEY=$(aws secretsmanager get-secret-value --secret-id api-key --query SecretString --output text)
```

## Migration Guide

### Moving Between Machine Types

If you got the machine type wrong:

```bash
# 1. Edit chezmoi config
chezmoi edit-config

# 2. Change machine type
isWork = true  # Change this
isPersonal = false  # and this

# 3. Re-apply everything
chezmoi apply -v

# 4. Re-run installation scripts
rm ~/.config/chezmoi/chezmoistate.boltdb
chezmoi apply -v
```

## FAQ

**Q: Can I use the same git repo for both work and personal machines?**  
A: Yes! That's the whole point. The templates adapt automatically.

**Q: What if my company provides 1Password?**  
A: You can still use it on work machines. Just manually install 1Password CLI and the functions will work.

**Q: How do I test my dotfiles without applying them?**  
A: Use `chezmoi diff` to see what would change.

**Q: Can I have more than 2 machine types?**  
A: Yes! Modify `.chezmoi.toml.tmpl` to add `isHomeServer`, `isCloud`, etc.

**Q: Will my secrets sync between machines?**  
A: NO! Secrets should never be in git. Each machine loads secrets from its own source (1Password on personal, company system on work).

## Security Reminder

✅ **DO commit:**
- Templates that reference secrets
- Scripts that load secrets
- Config files with secret patterns

❌ **DON'T commit:**
- Actual secrets or passwords
- `.envrc` files with real values
- API keys or tokens
- SSH private keys (unless encrypted with git-crypt)

Both machine types follow the same security practices - they just load secrets from different sources.
