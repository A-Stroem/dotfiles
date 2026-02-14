# Repo Bootstrap Script

Script: `scripts/bootstrap-repo.sh`

## What it does

1. Validates you are inside a git repository.
2. Sets local git defaults (`pull.rebase`, `rebase.autoStash`, `fetch.prune`, `push.autoSetupRemote`).
3. Creates a baseline `.pre-commit-config.yaml` if it does not exist.
4. Installs `pre-commit` and `git-secrets` hooks if available.
5. Stages all changes, commits, and pushes.

## Syntax

```bash
scripts/bootstrap-repo.sh [options]
```

## Options

- `-m, --message <text>`: Commit message.
- `--no-push`: Skip push.
- `--no-hooks`: Skip hook installation.
- `--no-pre-commit-config`: Skip generating `.pre-commit-config.yaml`.

## Examples

```bash
scripts/bootstrap-repo.sh
scripts/bootstrap-repo.sh -m "docs: refresh onboarding"
scripts/bootstrap-repo.sh --no-push
```
