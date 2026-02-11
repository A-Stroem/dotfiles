# 🔄 Updated Dotfiles - Work vs Personal Machines

## What Changed

I've updated your dotfiles to automatically detect and configure differently for **work** vs **personal** machines. Here's what's new:

## New/Updated Files

### Machine Detection
- ✨ **dot_chezmoi.toml.tmpl** - Auto-detects work/personal, prompts if unclear
- ✨ **WORK_VS_PERSONAL.md** - Complete guide on how this works

### Templated Configs (adapt based on machine type)
- 🔄 **dot_gitconfig.tmpl** (was dot_gitconfig) - Uses correct email per machine
- 🔄 **dot_zshrc.tmpl** (was dot_zshrc) - Conditional 1Password helpers
- 🔄 **dot_config/direnv/direnvrc.tmpl** (was direnvrc) - Different secret loading

### Conditional Installation
- 🔄 **run_once_install-1password-cli.sh.tmpl** - Only installs on personal machines
- ✨ **run_once_install-work-tools.sh.tmpl** - Only runs on work machines (customize this!)

### Examples
- ✨ **example-work.envrc** - Shows file-based secrets for work
- 🔄 **example-personal.envrc** - Shows 1Password integration for personal

## Key Differences

### Personal Machines (Your WSL2 + Mac)

**What you get:**
- ✅ 1Password CLI installed automatically
- ✅ Personal email in git by default
- ✅ `~/work/` directory (repos here use work email)
- ✅ 1Password helper functions: `op-read`, `op-list-work`, `ap-op`
- ✅ Direnv uses `op_load` function

**Example commands:**
```bash
# Load secret from 1Password
export API_KEY=$(op read "op://Work/API/key")

# Run Ansible with vault from 1Password
ap-op playbook.yml

# List 1Password items
op-list-work
```

### Work Machines (Your MSSP Work Laptop)

**What you get:**
- ✅ Work email in git only
- ✅ NO 1Password CLI (your company likely has its own system)
- ✅ File-based or command-based secret loading
- ✅ Placeholder for company-specific tools
- ✅ Direnv uses `secret_file_load` and `secret_cmd_load` functions

**Example commands:**
```bash
# Load secret from file
export API_KEY=$(cat ~/.secrets/api-key)

# Run Ansible with vault file
ap-vault .vault_pass playbook.yml

# Company secrets management (example)
export API_KEY=$(company-secrets get api-key)
```

## How It Works

### First Run

When you run `chezmoi init`, it checks your hostname:

```bash
# Auto-detects WORK if hostname contains:
work-laptop, company-*, etc.

# Auto-detects PERSONAL if hostname contains:
home-*, personal-*, etc.

# Otherwise prompts:
Machine type (work/personal): _
```

### Verification

After applying:
```bash
# Check machine type
echo $MACHINE_TYPE
# Output: "work" or "personal"

# Check git email
git config user.email
```

## Migration Steps

### If You Already Have Dotfiles Applied

1. **Pull new files:**
```bash
chezmoi update
```

2. **You'll be prompted:**
```
Machine type (work/personal): personal  # or work
```

3. **Verify it worked:**
```bash
echo $MACHINE_TYPE
git config user.email
```

### First Time Setup

No change! Just follow the same steps as before. The machine detection happens automatically.

## Customizing Work Tools

**Important:** Edit `run_once_install-work-tools.sh.tmpl` to add your company's required tools:

```bash
# Add your company tools here
if ! command -v company-vpn >/dev/null 2>&1; then
  echo "📦 Installing company VPN..."
  # Your install command
fi
```

## What To Update Before Committing

1. **dot_chezmoi.toml.tmpl** - Update email addresses:
```toml
{{- if $isWork }}
email = "anders@YOUR-COMPANY.com"  # ← Change this
{{- else }}
email = "anders@YOUR-PERSONAL.com"  # ← Change this
{{- end }}
```

2. **dot_gitconfig-work** - Update work email (this file is still used on personal machines for ~/work/ repos)

3. **run_once_install-work-tools.sh.tmpl** - Add your company's tools

## Benefits

✅ **Same git repo for all machines** - One source of truth
✅ **No more 1Password on work laptop** - Company won't complain
✅ **Automatic email switching** - Never commit with wrong email again
✅ **Company tools only where needed** - Clean separation
✅ **Easy testing** - Change machine type anytime with `chezmoi edit-config`

## File Structure Summary

```
dotfiles/
├── dot_chezmoi.toml.tmpl              ← Detects machine type
├── dot_gitconfig.tmpl                 ← Templated (was dot_gitconfig)
├── dot_gitconfig-work                 ← Still used on personal for ~/work/
├── dot_zshrc.tmpl                     ← Templated (was dot_zshrc)
├── dot_config/
│   └── direnv/
│       └── direnvrc.tmpl              ← Templated (was direnvrc)
├── run_once_install-1password-cli.sh.tmpl  ← Conditional
├── run_once_install-work-tools.sh.tmpl     ← New! Customize this
├── example-personal.envrc             ← 1Password pattern
├── example-work.envrc                 ← File/command pattern
└── WORK_VS_PERSONAL.md                ← Complete guide
```

## Testing

### Test on Personal Machine
```bash
chezmoi apply -v
echo $MACHINE_TYPE  # Should be "personal"
which op  # Should find 1Password CLI
op-list-work  # Should work
```

### Test on Work Machine
```bash
chezmoi apply -v
echo $MACHINE_TYPE  # Should be "work"
which op  # Should not find it
git config user.email  # Should be work email
```

## Questions?

- Read `WORK_VS_PERSONAL.md` for detailed documentation
- Check `example-personal.envrc` and `example-work.envrc` for patterns
- The templating is automatic - just commit and use!
