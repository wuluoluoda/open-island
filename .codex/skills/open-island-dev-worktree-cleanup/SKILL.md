---
name: open-island-dev-worktree-cleanup
description: Use when working in this Open Island repository and the user explicitly asks to create or use a git worktree from local dev instead of the normal in-checkout topic branch, or asks to merge/integrate/clean up that dev-based worktree. Ensures the worktree is removed after the work is integrated.
---

# Open Island Dev Worktree Cleanup

## Scope

Use this only for explicit worktree requests, especially wording such as "当前 dev 开一个工作树", "从 dev 建工作树", "worktree from dev", or cleanup after integrating such a worktree.

## Create From Dev

1. In the main development checkout, run `git status -sb`.
2. If the checkout has unrelated dirty changes, avoid touching them. Prefer a sibling worktree from the current local `dev` commit.
3. Create a focused sibling worktree:

```bash
git worktree add /Users/wuluoluo/work/code.app.org/open-vibe-island-<topic> -b <branch-name> dev
```

4. State the source commit, worktree path, and branch before editing.

## Work Inside The Worktree

Apply the same rules as a normal topic branch:

1. Start with `git status -sb`.
2. Read relevant files before editing.
3. Keep one coherent slice.
4. Verify the change.
5. Commit before stopping.
6. Do not integrate into `dev`, `main`, or another branch unless the user explicitly asks.

## After Integration

When the user explicitly asks to merge, promote, or otherwise integrate the worktree branch:

1. Confirm the worktree branch is committed and verification is known.
2. Perform only the requested integration target.
3. After the integration succeeds, remove the worktree:

```bash
git worktree remove /Users/wuluoluo/work/code.app.org/open-vibe-island-<topic>
```

4. Delete the local branch after it is safely merged when that matches the requested integration flow:

```bash
git branch -d <branch-name>
```

5. If the branch was pushed, delete the remote branch only when the user asked for remote cleanup or the PR merge flow already authorized branch deletion.

If integration has not happened yet, leave the worktree in place and state that cleanup is pending after merge.
