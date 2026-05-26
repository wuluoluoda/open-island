---
name: open-island-agent-reuse
description: Use when implementing, reviewing, or planning Respect Island features for a specific agent or runtime surface such as Codex, Claude Code, Gemini CLI, Cursor, OpenCode, Kimi CLI, Qoder, Qwen Code, Factory, or CodeBuddy. Keep the immediate agent-specific change working while lightly checking whether session, event, hook, installer, usage, jump-back, or UI patterns should be reusable by other agents.
---

# Respect Island Agent Reuse

## Overview

Keep Respect Island multi-agent without turning every agent-specific feature into a broad refactor. Prefer small reusable seams when they are natural, and keep source-specific behavior explicit when a protocol or product surface truly needs it.

## Reuse Check

Before editing, identify the feature's shape:

- **Adapter-specific**: protocol decoding, config file format, binary discovery, app-specific bridge, or vendor-specific metadata.
- **Shared product behavior**: session lifecycle, attention state, permission/question flow, artifact discovery, usage display, terminal jump-back, health checks, settings rows, diagnostics, or list ordering.
- **Mixed**: adapter-specific input that feeds a shared `AgentEvent`, `AgentSession`, `SessionState`, AppModel, or UI pattern.

Use this classification to keep the patch narrow:

1. Read the current implementation for the target agent and one nearby agent with similar behavior when practical.
2. Reuse existing shared types and flows first: `AgentTool`, `AgentEvent`, `SessionState`, hook installers, `HookInstallationCoordinator`, process discovery, terminal jump target logic, settings row patterns, and presentation helpers.
3. If a new concept is useful beyond one agent, name it generically and pass source-specific details through metadata or adapter code.
4. If the concept is genuinely source-specific, keep the name source-specific and add a short code or test comment only when future readers might otherwise try to generalize it.
5. Do not broaden public support claims in `README.md` or `docs/product.md` unless the behavior is actually implemented and verified for that agent.

## Implementation Bias

- Keep the requested agent working as the first priority.
- Avoid speculative abstractions, large migrations, or forced parity work.
- Prefer adapter-specific decoding with shared downstream events over copying full app/UI flows per agent.
- For UI, prefer source-neutral copy and controls when the behavior is identical; use agent names only when the user needs to understand the source.
- For diagnostics and setup, preserve per-agent config safety and uninstall behavior.

## Verification

When changing code:

- Add or update the target agent's tests.
- If shared state, event, ordering, installer, or UI behavior changes, add a shared test or at least one second-agent fixture when the cost is low.
- In the final summary, mention the reuse decision: what stayed source-specific, and what was shared or left intentionally local.

## Anti-Goals

- Do not delay a focused fix just to design a universal agent framework.
- Do not promise feature parity for agents that were not implemented.
- Do not erase useful Codex, Claude, OpenCode, Cursor, Gemini, or Kimi differences.
