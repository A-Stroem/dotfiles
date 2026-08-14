---
name: dependency-upgrade
description: Use when checking a web app's npm/yarn dependencies for outdated packages or known vulnerabilities, and want safe patches applied directly plus major/breaking upgrades tested end-to-end in an isolated branch before merging to main.
---

# Dependency Upgrade

Scans a web app's dependencies, applies safe in-range updates directly, and
handles major/breaking upgrades in an isolated branch with full end-to-end
verification before merging. Prioritizes security and stability over
bleeding-edge — never jump straight to a brand-new major without testing it
in isolation first.

## Workflow

### 1. Baseline scan

```bash
npm outdated
npm audit
```

Categorize every finding into three buckets:
- **In-range updates** — `Current` < `Wanted` (satisfies the existing `^`/`~` range in `package.json`). Safe, no code changes expected.
- **Security vulnerabilities** — from `npm audit`. Check whether a fix is available without a major bump.
- **Major/breaking** — `Wanted` < `Latest`, i.e. a new major version outside the current semver range.

### 2. Apply safe updates directly (no branch needed)

```bash
npm audit fix
npm update
```

Then **always verify with `npm ci`, not just `npm install`** — this is the
single most important step. `npm install` silently tolerates an internally
inconsistent lockfile; `npm ci` (what most CI/deploy pipelines actually run)
rejects it outright. Skipping this can push a lockfile that builds locally
but fails in CI/Vercel.

```bash
rm -rf node_modules .next   # or the framework's build cache dir
npm ci                      # must succeed cleanly
npm run build
npm run lint                # note any pre-existing errors as baseline, not regressions
```

If `npm ci` fails after `audit fix`/`update`, regenerate the lockfile fully
(`rm -rf node_modules package-lock.json && npm install`) rather than trying
to hand-fix it.

Commit and push this pass on its own — it's low-risk and doesn't need a
branch. Follow whatever push process the repo's own CLAUDE.md/AGENTS.md
documents (some repos need a specific commit author, a PR, or a staging step
— don't assume a plain `git push` is always correct).

### 3. Handle major/breaking upgrades in a branch

For each major bump (or tightly-coupled group of them — see below):

1. **Create a branch**: `git checkout -b upgrade/<package>-v<major>`
2. **Check for coupled peer dependencies before editing anything**:
   ```bash
   npm view <package>@<target-version> peerDependencies
   ```
   If a related package (e.g. a framework integration/bridge package) still
   peer-depends on the old major, it must be bumped in the same branch or
   the install will fail with an ERESOLVE conflict.
3. **Read the changelog/migration notes** for the target major before
   editing config — look for removed config options, new required peer
   versions, minimum runtime/Node version bumps. `gh release view vX.0.0
   --repo <org>/<repo>` or the package's docs are usually authoritative.
4. **Edit `package.json`**, then do a **full fresh reinstall**, not an
   incremental one:
   ```bash
   rm -rf node_modules package-lock.json .next
   npm install
   ```
   npm's incremental resolver frequently produces confusing, self-contradictory
   ERESOLVE errors when several coupled majors move at once — a full fresh
   resolve avoids that class of problem entirely.

### 4. Test end-to-end before trusting it

```bash
npm ci            # confirms the fresh lockfile is internally consistent
npm run build
npm run lint       # diff against the baseline from step 2 — only NEW errors count
npm run dev &      # or the project's dev command
```

Then **check the running app in a real browser**, not just via `curl`.
`curl`/build success does NOT prove the app works — CSP header blocks, font
loading, and CORS/auth failures only show up as browser console errors, not
build errors. If a Playwright (or similar) browser tool is available:
navigate to the app's key routes (home, and anything the upgraded package
touches — e.g. a CMS studio route after a CMS upgrade) and check
`console_messages` at `error` level. Zero new console errors is the bar.

If something breaks (commonly: a security-header allowlist like CSP now
blocking a new CDN the upgraded package loads from, or a config option that
got removed/renamed), fix it on the branch and re-run this whole step.

### 5. Merge

`main` may have moved since the branch was created (e.g. another safe-update
pass landed). Before merging:

```bash
git fetch origin
git checkout main && git reset origin/main   # realign to canonical history if it had diverged
git merge <branch> --no-ff
```

Lockfile conflicts are expected and are **not** a sign of a real conflict —
take the upgrade branch's version and regenerate:
```bash
git checkout --theirs package-lock.json && git add package-lock.json
rm -rf node_modules .next && npm ci
```

**Re-run all of step 4 again after the merge**, not just before it — a merge
can silently reintroduce a stale lockfile or reveal an interaction the
isolated branch didn't have.

Only push/merge to `main` if this final post-merge verification passes
cleanly. If anything is ambiguous or fails, stop and report instead of
pushing — don't merge a doubtful state into main.

### 6. Report

Summarize: what got bumped and why (including any coupled packages that had
to move together), vulnerability count before/after, what broke and got
fixed, and anything deliberately left alone (e.g. vulnerabilities confined to
devDependency-only CLI/build tooling that never ships to the browser — lower
priority, note but don't chase into more breaking changes).

## Common Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `npm ci` fails but `npm install` worked fine | `audit fix`/`update` left the lockfile's nested dependency graph inconsistent | Regenerate: `rm -rf node_modules package-lock.json && npm install` |
| ERESOLVE conflict that looks self-contradictory (peer satisfied but still rejected) | npm's incremental resolver choking on several coupled major bumps at once | Wipe `node_modules` + lockfile, fresh `npm install` from scratch |
| Install succeeds, browser console shows CSP `script-src`/`font-src`/`connect-src` violations | Upgraded package now loads a script/font/API from a new CDN domain not in the security-header allowlist | Find the header/middleware file (often named `middleware.ts`, `proxy.ts`, or set in `next.config`) and add the domain |
| Browser shows CORS/auth errors after upgrade | Often unrelated to the dependency bump itself — a service-side origin/credentials config gap that only becomes visible once the app loads correctly | Check the service's own dashboard/API for CORS or auth origin config, not just the code |
| `npm audit fix --force` offers to "fix" by installing an *older* version | The audit database matched a version range poorly — this is a downgrade, not a real fix | Don't apply it; prefer bumping the package forward instead, or accept the finding if it's confined to build-only tooling |
| Lint shows errors after the upgrade | Could be a real regression, or pre-existing debt unrelated to the bump | Compare against the baseline lint run from before touching anything; use `git blame` on flagged lines to check if they're old code |

## Notes

- "Prioritize security and stability over bleeding edge" means: always take
  `Wanted` (in-range) versions in the safe pass, and for major bumps prefer
  a major that's been out and stable for a while over a version released in
  the last few days, unless the update is itself a security fix.
- This operates on one repo at a time (the current working directory) — run
  it separately per project.
