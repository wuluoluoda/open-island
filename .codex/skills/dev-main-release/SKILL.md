---
name: dev-main-release
description: Promote this Respect Island repository's local dev workstream into main and publish/update the GitHub DMG release. Use when the user asks to merge dev into main, promote dev, ship a release, push dev/main remotely, cut a v* release tag, update GitHub Releases assets, or refresh the Respect Island DMG/appcast after dev validation.
---

# Dev Main Release

## Overview

Use this skill for the full dev-to-main release path. Do not stop at a local merge: this workflow must push to the correct remote and must verify that GitHub Releases contains the updated `Respect Island.dmg`.

Primary references when details are needed:
- `docs/releasing.md` for release notes, appcast, Sparkle, and asset expectations.
- `docs/packaging.md` for local packaging, signing, notarization, and required environment variables.
- `.github/workflows/release.yml` for the tag-triggered GitHub DMG/ZIP release workflow.

## Hard Rules

1. Start with `git status -sb`, `git remote -v`, `git branch -vv`, and `git fetch --all --tags --prune`.
2. Preserve user work. If `dev` or `main` is dirty, stop and resolve or ask before continuing.
3. Do not invent a version tag. If the user did not give a release version, inspect the latest `v*` tag and ask for the intended next version unless the user already authorized automatic patch bumps.
4. Push local `dev` before creating or merging the main PR.
5. Prefer a PR from `dev` to `main`. Directly merge/push `main` only if the user explicitly requests direct integration.
6. Push `main` and the final `v*` tag to the release remote. A local-only merge is not complete.
7. Do not report success until the GitHub release exists and has a downloadable `Respect Island.dmg` asset for the intended tag.
8. Treat build checkpoint tags (`build/...`) as local verification markers, not GitHub release tags.

## Remote Selection

Inspect remotes instead of assuming names. In this repository, the release remote is usually the branch upstream for `dev`/`main` and may differ from `origin`.

Use these checks:

```bash
git remote -v
git branch -vv
gh repo view --json nameWithOwner,url
```

If remotes disagree, state the candidate release repo and ask before pushing or tagging. The GitHub Release workflow runs in the repository that receives the `v*` tag.

## Workflow

### 1. Preflight dev

Verify `dev` is the intended source branch:

```bash
git switch dev
git status -sb
git log --oneline --decorate --max-count=20
git log --oneline <dev-upstream>..dev
```

Run targeted verification appropriate to the changes. For app/runtime changes, also refresh the local dev app:

```bash
swift test
zsh scripts/launch-dev-app.sh
```

Use narrower tests when the change is clearly scoped, but record any coverage gap.

### 2. Push dev

Push `dev` to its upstream or selected release remote before integrating:

```bash
git push <remote> dev
```

Confirm the remote branch now contains the intended head:

```bash
git ls-remote <remote> refs/heads/dev
```

### 3. Integrate main

Preferred path:

```bash
gh pr create --base main --head dev --title "<release/integration title>" --body "<summary and verification>"
gh pr checks --watch
gh pr merge --merge --delete-branch=false
git switch main
git pull --ff-only <remote> main
```

If the user explicitly wants direct integration:

```bash
git switch main
git pull --ff-only <remote> main
git merge --ff-only dev || git merge --no-ff dev -m "merge: promote dev to main"
git push <remote> main
```

After either path, verify:

```bash
git status -sb
git log --oneline --decorate --max-count=8
git merge-base --is-ancestor dev main
```

### 4. Cut and push the release tag

Only tag the exact `main` commit intended for release:

```bash
git switch main
git status -sb
git tag -a v<version> -m "Respect Island v<version>"
git push <remote> v<version>
```

This tag push should trigger `.github/workflows/release.yml`, which builds, signs/notarizes when secrets are present, creates `Respect Island.dmg` and `Respect Island.zip`, updates `appcast.xml` via PR when Sparkle signing is available, and creates a draft GitHub Release.

### 5. Watch GitHub release workflow

Find and watch the release run:

```bash
gh run list --workflow Release --limit 10
gh run watch <run-id> --exit-status
```

If it fails, inspect logs before retrying:

```bash
gh run view <run-id> --log-failed
```

Do not create a replacement tag with the same version unless the user confirms the recovery plan. Prefer fixing the failure and rerunning the workflow when possible.

### 6. Verify GitHub DMG and appcast

Verify the release and DMG asset:

```bash
gh release view v<version> --json tagName,isDraft,url,assets
```

The assets list must include `Respect Island.dmg` and `Respect Island.zip`. Download-check the DMG when practical:

```bash
tmpdir="$(mktemp -d)"
gh release download v<version> --pattern 'Respect Island.dmg*' --dir "$tmpdir"
ls -lh "$tmpdir"
shasum -a 256 "$tmpdir"/Respect\ Island.dmg*
```

If the workflow updated `appcast.xml`, verify the appcast PR merged and `main` contains the new version entry. If Sparkle signing was skipped, say that appcast was not updated and why.

If the release should be public instead of draft, publish it only after the DMG asset has been verified:

```bash
gh release edit v<version> --draft=false
```

## Final Response Checklist

Report:

- Source `dev` commit and final `main` commit.
- Remote pushed for `dev`, `main`, and `v<version>`.
- Verification commands and outcomes.
- GitHub Release URL.
- Whether `Respect Island.dmg` and `Respect Island.zip` were present and downloadable.
- Whether `appcast.xml` was updated or skipped.
- Any remaining manual action, such as publishing a draft release.
