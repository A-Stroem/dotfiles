# Quick Setup Guide

Step-by-step instructions for setting up a fresh machine. Works on both WSL2 Ubuntu and macOS.

---

## Prerequisites: SSH Key for GitHub

A fresh WSL instance or new Mac won't have an SSH key. You need one before you can clone the dotfiles repo.

Pick **one** of the two options below:

- **Option A** — Generate a local key (simple, but lost when WSL is reset)
- **Option B** — Use 1Password SSH agent (key persists across reinstalls)

### Option A: Local SSH Key (simple)

```bash
# Generate an Ed25519 key
ssh-keygen -t ed25519 -C "33464978+A-Stroem@users.noreply.github.com"

# When prompted:
#   File → press Enter to accept default (~/.ssh/id_ed25519)
#   Passphrase → enter a strong passphrase (or leave empty)

# Start the SSH agent and add the key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy the public key
cat ~/.ssh/id_ed25519.pub          # WSL / Linux
# pbcopy < ~/.ssh/id_ed25519.pub   # macOS (copies to clipboard)
```

Then add the public key to GitHub:

1. Go to [github.com/settings/keys](https://github.com/settings/keys)
2. Click **New SSH key**
3. Title: something like `WSL Ubuntu 2026` or `MacBook Pro`
4. Paste the public key
5. Click **Add SSH key**

### Option B: 1Password SSH Agent (recommended — survives WSL resets)

With 1Password managing your SSH key, you never lose it when resetting WSL or setting up a new machine. 1Password stores the private key in your vault and acts as the SSH agent.

#### Step 1: Generate an SSH key in 1Password

1. Open the **1Password desktop app** (Windows or macOS)
2. Select your vault (Personal or Private)
3. Click **New Item** > **SSH Key**
4. Click **Add Private Key** > **Generate New Key**
5. Choose **Ed25519**, click **Generate**, then **Save**
6. Copy the **public key** from the item and add it to [github.com/settings/keys](https://github.com/settings/keys)

#### Step 2: Enable the 1Password SSH agent

1. Open **1Password** > **Settings** > **Developer**
2. Check **Use the SSH agent**
3. Under **Settings** > **General**, enable **Keep 1Password in the notification area** and **Start at login** (so the agent stays running)

#### Step 3a: Configure WSL2 to use the 1Password agent

The 1Password SSH agent runs on the Windows side. WSL2 needs `npiperelay` and `socat` to bridge to it.

```bash
# Install socat
sudo apt install -y socat
```

Download [npiperelay](https://github.com/jstarks/npiperelay/releases) (the `.exe`), place it somewhere on your Windows PATH (e.g., `C:\Users\<you>\bin\npiperelay.exe`), and make sure that directory is in your Windows PATH.

Create the bridge script `~/.1password-agent-bridge.sh`:

```bash
cat > ~/.1password-agent-bridge.sh << 'SCRIPT'
#!/bin/bash
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

NEEDS_START=true
if [[ -S "$SSH_AUTH_SOCK" ]]; then
  ssh-add -l >/dev/null 2>&1
  if [[ $? -ne 2 ]]; then
    NEEDS_START=false
  fi
fi

if $NEEDS_START; then
  rm -f "$SSH_AUTH_SOCK"
  (setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
fi
SCRIPT
chmod +x ~/.1password-agent-bridge.sh
```

Then source it in your shell. Add this to `~/.zshrc` (or it will be there after chezmoi apply — you can add it manually for the initial clone):

```bash
# 1Password SSH agent bridge (WSL2 → Windows)
[[ -f "$HOME/.1password-agent-bridge.sh" ]] && source "$HOME/.1password-agent-bridge.sh"
```

#### Step 3b: Configure macOS to use the 1Password agent

On macOS, add this to `~/.ssh/config`:

```
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

That's it — no bridge script needed on macOS.

#### Step 4: Verify

Restart your terminal, then:

```bash
ssh-add -l
# Should list your 1Password SSH key

ssh -T git@github.com
# Should print: "Hi A-Stroem! You've successfully authenticated..."
```

Now you're ready to clone — and this key will survive WSL resets, new machines, etc.

---

## WSL2 Ubuntu — Fresh Install

### Step 1: Bootstrap

Open your WSL2 Ubuntu terminal:

```bash
# Option A: Run the bootstrap script directly
curl -fsSL https://raw.githubusercontent.com/A-Stroem/dotfiles/main/scripts/bootstrap-from-zero-wsl.sh | bash

# Option B: Or do it manually
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git ca-certificates
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

### Step 2: Initialize and Apply

```bash
~/.local/bin/chezmoi init --apply git@github.com:A-Stroem/dotfiles.git
```

You will be prompted for:
- **Machine type** — enter `work` or `personal`
- **Your full name** — used in git commits
- **Personal email** — default git email on personal machines
- **Work email** — git email for work repos (or default on work machines)

These are saved in `~/.config/chezmoi/chezmoi.toml` and won't be asked again.

This single command will:
1. Clone the dotfiles repo
2. Prompt for your configuration
3. Copy all configs to `~/`
4. Run install scripts (core packages, security tools, 1Password if personal, work tools if work)

### Step 3: Restart Shell

```bash
exec zsh
```

### Step 4: Post-Install

```bash
# Set up GPG signing
gpg --full-generate-key
gpg --list-secret-keys --keyid-format=long
git config --global user.signingkey YOUR_KEY_ID

# 1Password (personal machines only)
op signin

# Create work directory (personal machines)
mkdir -p ~/work
```

### Step 5: Verify

```bash
# Shell
echo $SHELL                   # Should be /usr/bin/zsh or similar
starship --version
mise --version

# Tools
kubectl version --client
helm version --short
k9s version --short
ansible --version

# Security
gitleaks version
trivy version
checkov --version

# Git
git config user.name
git config user.email
echo "test" | gpg --clearsign  # GPG signing
```

---

## macOS — Fresh Install

### Step 1: Bootstrap

Open Terminal.app:

```bash
# Option A: Run the bootstrap script
curl -fsSL https://raw.githubusercontent.com/A-Stroem/dotfiles/main/scripts/bootstrap-from-zero-mac.sh | bash

# Option B: Or do it manually
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi git
```

### Step 2: Initialize and Apply

```bash
chezmoi init --apply git@github.com:A-Stroem/dotfiles.git
```

Same prompts as WSL (machine type, name, emails). Same single-command setup.

### Step 3: Restart Shell

```bash
exec zsh
```

### Step 4: Post-Install

Same as WSL — GPG key, 1Password signin, work directory.

On macOS, you can also add this to `~/.ssh/config` to persist the key in the macOS Keychain (so you don't have to `ssh-add` after every reboot):

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

### Step 5: Install Nerd Font (for Starship icons)

```bash
# On your host machine (not inside WSL)
bash scripts/download-nerd-font.sh
```

On WSL, Windows Terminal is configured automatically during `chezmoi init --apply` / `chezmoi apply`.
- Existing profiles are preserved.
- A managed `WSL (chezmoi)` profile is added/updated and set as default.
- One-time Windows host setting: in Windows Terminal > Settings > Startup, set **Default terminal application** to **Windows Terminal**.

If Windows Terminal had never been opened before setup, open it once and then run:

```bash
chezmoi apply
```

---

## Syncing to Another Machine

Already set up on one machine? On the new machine, after bootstrapping:

```bash
chezmoi init --apply git@github.com:A-Stroem/dotfiles.git
# Answer prompts for this machine's configuration
exec zsh
```

To pull updates on an already-configured machine:

```bash
chezmoi update
```

---

## Changing Your Configuration

### Re-prompt for machine type / emails

```bash
chezmoi init --prompt --apply
```

### Edit chezmoi config directly

```bash
chezmoi edit-config
# Modify [data] section, then:
chezmoi apply
```

### Edit a managed dotfile

```bash
chezmoi edit ~/.zshrc
chezmoi diff          # Preview
chezmoi apply         # Apply
```

### Commit changes back to git

```bash
chezmoi cd
git add . && git commit -m "Update config" && git push
exit
```

---

## Using Customer Contexts

```bash
cd ~/work/customer-acme

# Create .envrc (see example-personal.envrc or example-work.envrc)
cat > .envrc << 'EOF'
export CUSTOMER_CONTEXT="acme-corp"
export AWS_PROFILE="acme-prod"
# Add secrets via 1Password (personal) or files (work)
EOF

direnv allow
# Your prompt now shows the customer context
```

---

## File Locations

| What | Where |
|------|-------|
| Dotfiles source repo | `~/.local/share/chezmoi/` |
| Applied configs | `~/` (home directory) |
| chezmoi config | `~/.config/chezmoi/chezmoi.toml` |
| chezmoi binary | `~/.local/bin/chezmoi` (Linux) or `$(brew --prefix)/bin/chezmoi` (macOS) |

---

## Common Issues

| Problem | Fix |
|---------|-----|
| `Permission denied (publickey)` during clone | SSH key not set up — see Prerequisites section above |
| SSH key not persisting after reboot (macOS) | Add `UseKeychain yes` to `~/.ssh/config` — see macOS Step 4 |
| Prompts not appearing | Use `chezmoi init --prompt`, not `chezmoi apply` |
| zsh not default shell | `chsh -s $(which zsh)` then restart terminal |
| 1Password not working | `op signin` then `op account list` |
| direnv not loading | `direnv allow .` |
| Install scripts not re-running | Edit the script — `run_onchange_` auto-reruns on change |
| Force full re-run | `rm ~/.config/chezmoi/chezmoistate.boltdb && chezmoi apply` |
| WSL DNS issues | `sudo rm /etc/resolv.conf && echo "nameserver 1.1.1.1" \| sudo tee /etc/resolv.conf` |

---

## Security Reminders

**Never commit:** SSH private keys, API tokens, `.envrc` files with real secrets, vault passwords.

**Always:** Use 1Password or your company's secrets manager, run `safety-check` before pushing, sign commits with GPG.
