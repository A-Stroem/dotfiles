#!/usr/bin/env bash
# ============================================================
# Bootstrap git tooling for a repository, then commit and push
# ============================================================

set -euo pipefail

COMMIT_MESSAGE="chore: bootstrap repository tooling"
PUSH_ENABLED=true
INSTALL_HOOKS=true

usage() {
  cat <<'USAGE'
Usage: bootstrap-repo.sh [options]

Options:
  -m, --message <text>   Commit message (default: chore: bootstrap repository tooling)
      --no-push          Do not push after commit
      --no-hooks         Skip pre-commit/git-secrets hook setup
  -h, --help             Show help

Behavior:
  1. Verifies current directory is a git repository
  2. Sets practical local git defaults
  3. Installs pre-commit and git-secrets hooks when available
  4. Stages all changes, commits, and pushes
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      [[ $# -ge 2 ]] || { echo "Missing value for $1"; usage; exit 1; }
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    --no-push)
      PUSH_ENABLED=false
      shift
      ;;
    --no-hooks)
      INSTALL_HOOKS=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not inside a git repository"
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" == "HEAD" ]]; then
  echo "❌ Detached HEAD is not supported for bootstrap commit/push"
  exit 1
fi

echo "🔧 Bootstrapping git tooling in: $REPO_ROOT"

# Local defaults that help keep history clean and updates safe.
git config --local pull.rebase true
git config --local rebase.autoStash true
git config --local fetch.prune true
git config --local push.autoSetupRemote true

if [[ "$INSTALL_HOOKS" == true ]]; then
  if command -v pre-commit >/dev/null 2>&1; then
    echo "📦 Installing pre-commit hook..."
    pre-commit install --allow-missing-config
  else
    echo "⚠️  pre-commit not found; skipping hook install"
  fi

  if command -v git-secrets >/dev/null 2>&1; then
    echo "📦 Configuring git-secrets..."
    if [[ -f .git/hooks/pre-commit ]] && grep -q "pre-commit" .git/hooks/pre-commit 2>/dev/null; then
      echo "⚠️  Existing pre-commit hook managed by pre-commit; skipping git-secrets hook install"
    else
      git secrets --install || true
    fi
    git secrets --register-aws || true
  else
    echo "⚠️  git-secrets not found; skipping secrets hook install"
  fi
fi

echo "📝 Staging changes..."
git add -A

if git diff --cached --quiet; then
  echo "ℹ️  No staged changes to commit"
else
  echo "✅ Creating commit..."
  git commit -m "$COMMIT_MESSAGE"
fi

if [[ "$PUSH_ENABLED" != true ]]; then
  echo "ℹ️  Push skipped (--no-push)"
  exit 0
fi

echo "🚀 Pushing branch '$CURRENT_BRANCH'..."
if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
  git push
else
  git push -u origin "$CURRENT_BRANCH"
fi

echo "✅ Repository bootstrap complete"
