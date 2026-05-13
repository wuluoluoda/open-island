# Project Skill Change Log: /Users/wuluoluo/work/code.app.org/open-vibe-island

- Scope: project-local skill changes
- Layout: one project-local file partitioned by skill

## Skill: *-bean

- Scope: project
- Project path: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Current skill name: *-bean
- Name history:
  - *-bean (observed by codex-audit-log)
- Lifecycle history:
  - active (observed by codex-audit-log)

### Entries

#### 2026-05-11T18:39:20+08:00 Suffix project skills with bean

- Kind: skill
- Entry ID: 20260511183920-suffix-project-skills-with-bean
- Repo: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Commit: 3dbf8c0
- Files: /Users/wuluoluo/work/code.app.org/open-vibe-island/.codex/skills/*-bean; /Users/wuluoluo/work/code.app.org/open-vibe-island/AGENTS.md; /Users/wuluoluo/work/code.app.org/open-vibe-island/docs/worktree-workflow.md; /Users/wuluoluo/work/code.codex.org/migration/scripts/generate-discovery-manifest.js; /Users/wuluoluo/work/code.codex.org/migration/manifests/codex-local-migration-20260511-discovery.json
- Summary: Renamed Open Island project skills to use the -bean suffix and updated the migration discovery generator to only treat project skill directories ending in -bean as migratable project skills.
- Reason: Adopt the project-level migration convention that users mark migratable project skills/rules with a -bean suffix.
- Verification: Checked no old project skill names or paths remain with rg --pcre2; verified skill directory names match SKILL.md names and end in -bean; regenerated and schema-validated the discovery manifest.
- Rollback: Revert commit 3dbf8c0 in the Open Island repo and revert/regenerate the migration discovery manifest.

## Skill: log-add

- Scope: project
- Project path: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Current skill name: log-add
- Name history:
  - log-add (observed by codex-audit-log)
- Lifecycle history:
  - active (observed by codex-audit-log)

### Entries

#### 2026-05-12T19:43:02+08:00 Temporary log-add diagnostic skill

- Kind: skill
- Entry ID: 20260512194302-temporary-log-add-diagnostic-skill
- Repo: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Commit: ffc6418
- Project: cwd
- Files: .codex/skills/log-add/SKILL.md,.codex/logs/log-add
- Summary: Registered log-add only in isolated diagnostic worktree diagnose/input-preview-logging, then destroyed it after code inspection identified the input preview path; no raw logs or instrumentation were retained.
- Reason: User requested temporary project diagnostic skill for lingering voice input preview.
- Verification: Diagnostic worktree and branch removed; merge-gate rg found no log-add markers.
- Rollback: No persistent skill files remain; no rollback needed beyond the audit record.

#### 2026-05-12T20:07:08+08:00 Temporary log-add input preview diagnostic

- Kind: skill
- Entry ID: 20260512200708-temporary-log-add-input-preview-diagnostic
- Repo: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Commit: 19a63a5
- Project: cwd
- Files: .codex/skills/log-add/SKILL.md,.codex/logs/log-add,Sources/OpenIslandApp/LogAddDiagnostics.swift
- Summary: Registered log-add in isolated worktree diagnose/input-preview-logging, added metadata-only instrumentation, observed command preview source fields, then destroyed the diagnostic worktree and raw logs before applying the product fix.
- Reason: User confirmed input previews still appeared in the top bar and asked to run the temporary logging diagnostic flow.
- Verification: Diagnostic worktree removed; merge-gate rg for log-add markers returned no results; product tests/build passed after cleanup.
- Rollback: No persistent diagnostic files remain; product fix is isolated in the subsequent dev commit.

## Skill: open-island-workflow

- Scope: project
- Project path: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Current skill name: open-island-workflow
- Name history:
  - open-island-workflow (observed by codex-audit-log)
- Lifecycle history:
  - active (observed by codex-audit-log)

### Entries

#### 2026-05-12T20:18:06+08:00 Open Island commit authorization workflow

- Kind: skill
- Entry ID: 20260512201806-open-island-commit-authorization-workflow
- Repo: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Commit: dead920
- Project: cwd
- Files: .codex/skills/open-island-workflow/SKILL.md,.codex/skills/dev-main-release/SKILL.md
- Summary: Updated project-local workflow guidance so dev product commits are not created without explicit user approval, and promote does not create new product/fix commits during integration.
- Reason: User objected that Codex committed directly to dev without an explicit commit request and asked whether promote should be changed to prevent self-commits.
- Verification: Reviewed open-island-workflow and dev-main-release skills; changes are currently uncommitted pending user confirmation.
- Rollback: Revert or discard the two SKILL.md edits if the stricter commit-authorization policy is not desired.

#### 2026-05-12T21:19:03+08:00 Forbid automatic dev integration

- Kind: skill
- Entry ID: 20260512211903-forbid-automatic-dev-integration
- Repo: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Commit: 5b30e44955f3b8c957f50dd80823a8fb6ad37fb8
- Project: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Files: .codex/skills/open-island-workflow/SKILL.md; AGENTS.md; docs/worktree-workflow.md
- Summary: Updated the Open Island workflow skill and repository instructions to prohibit Codex from merging or fast-forwarding completed topic branches into dev/main/local testing branches without explicit user instruction.
- Reason: User asked to prevent automatic self-integration into dev after development.
- Verification: Ran git diff --check and searched the workflow docs/skill for the new no-auto-merge wording.
- Rollback: Revert commit 5b30e44955f3b8c957f50dd80823a8fb6ad37fb8 in /Users/wuluoluo/work/code.app.org/open-vibe-island.

#### 2026-05-13T23:30:04+08:00 Add Open Island dev worktree cleanup skill

- Kind: skill
- Scope: project
- Skill: open-island-dev-worktree-cleanup, open-island-workflow
- Entry ID: 20260513233004-add-open-island-dev-worktree-cleanup-skill
- Project: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Files: /Users/wuluoluo/work/code.app.org/open-vibe-island/.codex/skills/open-island-dev-worktree-cleanup/SKILL.md;/Users/wuluoluo/work/code.app.org/open-vibe-island/.codex/skills/open-island-workflow/SKILL.md
- Summary: Added a project skill for explicit dev-based worktree cleanup after integration, and updated open-island-workflow so topic branch rules also apply inside explicitly requested worktrees.
- Reason: Ensure worktrees opened from dev are not left behind after their branch is integrated, while preserving the default branch-in-current-checkout workflow.
- Verification: Ran quick_validate.py via uv --with pyyaml for open-island-dev-worktree-cleanup and open-island-workflow; ran git diff --check.
- Rollback: Revert the new open-island-dev-worktree-cleanup skill and restore the previous open-island-workflow wording.

## Skill: dev-main-release

- Scope: project
- Project path: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Current skill name: dev-main-release
- Name history:
  - dev-main-release (observed by codex-audit-log)
- Lifecycle history:
  - active (observed by codex-audit-log)

### Entries

#### 2026-05-12T20:18:06+08:00 Open Island commit authorization workflow

- Kind: skill
- Entry ID: 20260512201806-open-island-commit-authorization-workflow
- Repo: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Commit: dead920
- Project: cwd
- Files: .codex/skills/open-island-workflow/SKILL.md,.codex/skills/dev-main-release/SKILL.md
- Summary: Updated project-local workflow guidance so dev product commits are not created without explicit user approval, and promote does not create new product/fix commits during integration.
- Reason: User objected that Codex committed directly to dev without an explicit commit request and asked whether promote should be changed to prevent self-commits.
- Verification: Reviewed open-island-workflow and dev-main-release skills; changes are currently uncommitted pending user confirmation.
- Rollback: Revert or discard the two SKILL.md edits if the stricter commit-authorization policy is not desired.

## Skill: open-island-agent-reuse

- Scope: project
- Project path: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Current skill name: open-island-agent-reuse
- Name history:
  - open-island-agent-reuse (observed by codex-audit-log)
- Lifecycle history:
  - active (2026-05-13T22:56:56+08:00): Keep the project multi-agent while allowing Codex- or other agent-specific work to stay focused.
  - active (observed by codex-audit-log)

### Entries

#### 2026-05-13T22:56:56+08:00 Add Open Island agent reuse skill

- Kind: skill
- Scope: project
- Skill: open-island-agent-reuse
- Lifecycle: active
- Entry ID: 20260513225656-add-open-island-agent-reuse-skill
- Project: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Files: .codex/skills/open-island-agent-reuse/SKILL.md
- Summary: Added a project-level skill that reminds future agent-specific feature work to consider shared session, event, hook, installer, jump-back, usage, and UI patterns without forcing broad refactors.
- Reason: Keep the project multi-agent while allowing Codex- or other agent-specific work to stay focused.
- Verification: Manual frontmatter sanity check passed; quick_validate.py could not run because PyYAML is unavailable in the local Python environment.
- Rollback: Remove .codex/skills/open-island-agent-reuse/SKILL.md and the matching audit entry if the skill is no longer wanted.

## Skill: open-island-dev-worktree-cleanup

- Scope: project
- Project path: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Current skill name: open-island-dev-worktree-cleanup
- Name history:
  - open-island-dev-worktree-cleanup (observed by codex-audit-log)
- Lifecycle history:
  - active (observed by codex-audit-log)

### Entries

#### 2026-05-13T23:30:04+08:00 Add Open Island dev worktree cleanup skill

- Kind: skill
- Scope: project
- Skill: open-island-dev-worktree-cleanup, open-island-workflow
- Entry ID: 20260513233004-add-open-island-dev-worktree-cleanup-skill
- Project: /Users/wuluoluo/work/code.app.org/open-vibe-island
- Files: /Users/wuluoluo/work/code.app.org/open-vibe-island/.codex/skills/open-island-dev-worktree-cleanup/SKILL.md;/Users/wuluoluo/work/code.app.org/open-vibe-island/.codex/skills/open-island-workflow/SKILL.md
- Summary: Added a project skill for explicit dev-based worktree cleanup after integration, and updated open-island-workflow so topic branch rules also apply inside explicitly requested worktrees.
- Reason: Ensure worktrees opened from dev are not left behind after their branch is integrated, while preserving the default branch-in-current-checkout workflow.
- Verification: Ran quick_validate.py via uv --with pyyaml for open-island-dev-worktree-cleanup and open-island-workflow; ran git diff --check.
- Rollback: Revert the new open-island-dev-worktree-cleanup skill and restore the previous open-island-workflow wording.

