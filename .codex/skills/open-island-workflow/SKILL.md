---
name: open-island-workflow
description: Use when working on this Respect Island / open-vibe-island repository, especially tasks that mention Respect Island, Vibe Island, Codex island suite, local dev app testing, repo workflow, branches, worktrees, commits, tags, or performance fixes. Enforces the user's current topic-branch or explicitly requested worktree workflow and repository verification expectations.
---

# Respect Island Workflow

## Overview

Follow the user's current local Respect Island workflow. Create or switch to a topic branch in the current checkout by default; create a git worktree only when the user explicitly asks for one.

## Start

1. Run `git status -sb` in the repository before edits.
2. Read `AGENTS.md`, `CLAUDE.md`, or relevant docs when the task touches workflow, release, app launch, hooks, verification, or integration expectations.
3. If not already on a focused branch, create or switch to a topic branch in the current checkout, for example `fix/performance-hotspots`.
4. When the user explicitly asks for a worktree, treat that worktree's branch as the focused topic branch and apply the same branch, edit, verify, and commit rules inside it.
5. If older repository docs say to create a worktree, treat that as superseded by the default in-checkout branch preference unless the user reaffirms worktrees for the task.

## Editing

1. Read relevant source files before editing.
2. Keep each round to one coherent change.
3. Do not overwrite user changes or use destructive git commands.
4. Use native Swift/macOS patterns already present in the repository.

## Verification

1. Run the most relevant targeted check for the changed area, commonly `swift test`, a narrower test target, `swift build`, or a project script.
2. For local app runtime changes, prefer the repo's dev app script when the user asks to test the app: `zsh scripts/launch-dev-app.sh`.
3. State any verification gap clearly.

## Finish

1. Commit every completed file-changing round on the topic branch, including a worktree-owned branch, with a conventional message.
2. Do not merge, fast-forward, or otherwise integrate the topic branch into `dev`, `main`, or another local testing branch unless the user explicitly asks for that integration.
3. Do not push, tag, or open a PR unless the user asks, or the repository workflow for the exact task explicitly requires it and the user has agreed.
4. Summarize changed files, verification, branch, commit hash, and worktree path when a worktree was used.
5. For a worktree created from `dev`, use the `open-island-dev-worktree-cleanup` skill after successful integration so the worktree is removed instead of left behind.
