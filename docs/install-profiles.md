# Install Profiles

## Overview

Colleagues found the full toolchain heavy — the old setup forced a complete
Kubernetes stack, Docker, a networking toolkit, and Ansible onto every
machine, whether you touched any of them or not. Install profiles fix that:
a trimmed **core** (general shell essentials) always installs, and
everything else is an opt-in toggle answered once at `chezmoi init`.
Capability isn't removed — it's just no longer forced.

## How Profile Prompts Work

Same mechanism as `machineType` (see `WORK_VS_PERSONAL.md`): each profile is
a `promptBoolOnce` prompt in `.chezmoi.toml.tmpl`, asked once during
`chezmoi init` and cached in `~/.config/chezmoi/chezmoi.toml`. Each toggle
gates one `run_onchange_` script — declining a profile makes that script a
no-op (`exit 0`) rather than skipping it entirely, so chezmoi still tracks
it and re-runs it automatically if you ever flip the toggle on.

## Profile Table

| Profile | Prompt variable | Default | Tools installed | Script file |
|---|---|---|---|---|
| Core (always on) | — | — | git, zsh, starship, mise, zoxide, fzf, ripgrep, fd, bat, eza, jq, yq*, direnv, tmux, uv, pipx, curl, wget, tree, htop | `run_onchange_00-install-core.sh.tmpl` |
| Security scanning | `installSecurityTools` | **true** | gitleaks, trivy, checkov, pre-commit, git-secrets | `run_onchange_10-install-security.sh.tmpl` |
| Container tooling | `installContainerTools` | false | Docker Desktop (macOS) / Docker Engine + Compose (Linux) | `run_onchange_20-install-container-tools.sh.tmpl` |
| Kubernetes tooling | `installKubernetesTools` | false | kubectl, kubectx/kubens, helm, k9s | `run_onchange_21-install-kubernetes-tools.sh.tmpl` |
| Networking toolkit | `installNetworkingTools` | false | dig/nslookup, tcpdump, nmap, mtr, iperf3, whois, netcat | `run_onchange_22-install-networking-tools.sh.tmpl` |
| Ansible | `installAnsible` | false | ansible, ansible-lint | `run_onchange_23-install-ansible.sh.tmpl` |
| zellij (local only) | `installZellij` | false | zellij | `run_onchange_24-install-zellij.sh.tmpl` |

\* `yq` is currently only installed on macOS core (Homebrew) — a
pre-existing gap, not fixed by this profile split. Ubuntu's apt repos don't
ship `mikefarah/yq`; add it manually on Linux if you need it.

Security scanning defaults **on** (opt-out) since "security-focused
defaults" is this repo's stated purpose — everything else defaults **off**
(opt-in).

## Changing Your Answers Later

```bash
# Re-run all prompts, including profile toggles
chezmoi init --prompt --apply

# Or edit the cached answers directly
chezmoi edit-config
# Then: chezmoi apply
```

Flipping a single profile on/off only re-runs that profile's script —
chezmoi diffs the rendered script content and skips anything unchanged.

## FAQ

**Q: Why is tmux always installed but zellij isn't?**
A: tmux is on every remote/server box you SSH into (NAS/Pi infra, work
boxes) where you can't necessarily install anything else. zellij is a
nicer local-machine experience, not a remote-compatible default.

**Q: Do profiles interact with machine type (work/personal)?**
A: No — they're independent axes. See `WORK_VS_PERSONAL.md` for the
work/personal split.

**Q: I want a completely custom set of tools, not one of these buckets.**
A: Toggle the profiles you want at `chezmoi init`/`chezmoi edit-config`,
then edit the relevant `run_onchange_2x-*.sh.tmpl` script directly for
anything more specific — there's no deeper granularity than one toggle per
script today.
