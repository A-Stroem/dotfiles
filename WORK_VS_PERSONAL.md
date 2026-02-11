# Work vs Personal Machine Configuration

## Overview

These dotfiles automatically adapt based on whether you're on a **work** or **personal** machine. The machine type is set once during `chezmoi init` and controls:

- Which git email is used by default
- Whether 1Password CLI is installed
- Whether work-specific tools are installed
- Which secret-loading helpers are available in direnv/zsh

## How Machine Detection Works

When you run `chezmoi init`, the `.chezmoi.toml.tmpl` template prompts you:

```
Machine type (work or personal): _
Your full name: _
Personal email address: _
Work email address: _
```

Your answers are saved to `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    machineType = "personal"
    name = "Anders Stroem"
    personalEmail = "anders@personal.com"
    workEmail = "anders@company.com"
    isWork = false
    isPersonal = true
```

To change these values later:

```bash
# Re-run prompts
chezmoi init --prompt --apply

# Or edit directly
chezmoi edit-config
# Then: chezmoi apply
```

## What Differs Per Machine Type

### Personal Machines

| Area | Behavior |
|------|----------|
| **Git email** | Personal email by default; work email for repos in `~/work/` |
| **1Password CLI** | Installed automatically |
| **zsh helpers** | `op-read`, `op-list-work`, `ap-op` (1Password integration) |
| **direnv** | Uses `op_load` function for secrets |
| **Work tools** | Skipped |

### Work Machines

| Area | Behavior |
|------|----------|
| **Git email** | Work email for all repos |
| **1Password CLI** | Not installed |
| **zsh helpers** | File/command-based vault helpers (`ap-vault`) |
| **direnv** | Uses `secret_file_load` / `secret_cmd_load` |
| **Work tools** | `run_onchange_install-work-tools.sh.tmpl` runs (customize this) |

### Files That Are The Same on Both

Core tools, security scanning, tmux, starship, mise, SSH config — all identical regardless of machine type.

## Templated Files

These files use chezmoi's Go template system to produce different output based on `.isWork` / `.isPersonal`:

| Source File | What Changes |
|-------------|-------------|
| `dot_gitconfig.tmpl` | Default email, `includeIf` for `~/work/` |
| `dot_zshrc.tmpl` | 1Password helper functions present or absent |
| `dot_config/direnv/direnvrc.tmpl` | Secret-loading strategy |
| `run_onchange_install-1password-cli.sh.tmpl` | Installs on personal, no-op on work |
| `run_onchange_install-work-tools.sh.tmpl` | Installs on work, no-op on personal |

## Customizing Work Tools

Edit `run_onchange_install-work-tools.sh.tmpl` to add your company's required tools:

```bash
# Example: add inside the {{- if .isWork -}} block
if ! command -v company-vpn >/dev/null 2>&1; then
  echo "Installing company VPN..."
  # your install commands
fi
```

Since the script uses `run_onchange_`, it will automatically re-run next time you `chezmoi apply` after editing it.

## Secrets Management

### Personal: 1Password

```bash
# .envrc in a project directory
export API_KEY=$(op read "op://Work/Project/api-key")
export DB_PASSWORD=$(op read "op://Work/DB/password")
```

### Work: File or Command-Based

```bash
# .envrc using files
export API_KEY=$(cat ~/.secrets/api-key)

# Or company secrets manager
export API_KEY=$(company-secrets get api-key)

# Or AWS Secrets Manager
export API_KEY=$(aws secretsmanager get-secret-value --secret-id api-key --query SecretString --output text)
```

## FAQ

**Q: Can I use the same git repo for both machine types?**
A: Yes — that's the whole point. Templates adapt automatically.

**Q: What if my company also provides 1Password?**
A: Manually install 1Password CLI on the work machine and the helper functions will work.

**Q: How do I test changes without applying?**
A: `chezmoi diff` shows what would change.

**Q: Can I add more machine types (e.g., homeserver, cloud)?**
A: Yes — add new prompt variables to `.chezmoi.toml.tmpl` and use them in templates.

**Q: Will secrets sync between machines?**
A: No. Secrets are never in git. Each machine loads from its own source.
