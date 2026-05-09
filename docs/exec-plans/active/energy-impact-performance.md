# Energy Impact Performance Plan

## Problem

`Open Island Dev` can show high long-running energy impact in Activity Monitor even when the island is mostly idle. The core island experience is display, notification, and jump-back; background work that does not directly support those paths should be quiet by default.

## Intended End State

- Idle sessions do not trigger frequent terminal or jump-target probes.
- The island remains fast for the primary user action: clicking a session to jump back.
- Jump precision is preserved without keeping expensive resolvers hot all the time.
- `attached` / `stale` / `detached` terminal connection precision is treated as secondary metadata, not as a reason for high-frequency background probing.
- Codex rollout file watching is used as a fallback when real-time channels are unavailable, not as duplicate high-frequency work when live events are healthy.
- Session persistence is scheduled only for the agent family that changed.
- Optional surfaces such as shelves, usage details, and settings diagnostics stay out of the always-on path unless explicitly enabled or opened.

## Completed Slice

- Reduced process monitoring cadence from a fixed 2 second loop to active, quiet, and idle cadences.
- Skipped terminal snapshot and jump target resolver work when there are no live sessions and no active agent processes.
- Added tests for monitor sleep cadence.

## Next Slice: Warm Jump Target Cache

Avoid moving all jump-target resolution to the exact click moment, because waiting 1-3 seconds on click is not acceptable. Instead:

- Keep hook/event-provided jump targets as the immediate fallback.
- Stop doing full jump-target precision resolution on every background monitor tick.
- Pre-warm likely jump targets when the user is close to interacting:
  - island opens
  - pointer enters the island
  - notification card appears
  - selected session changes
  - a running, approval, or question event arrives
- Cache resolved jump targets with a short TTL, likely 20-30 seconds.
- On click, use a fresh cached target immediately when available.
- If the cached target is stale, allow only a very short resolution budget, roughly 50-100 ms.
- If the short budget misses, jump with the most recent known target and start a slower repair path only if the jump fails.

This does not conflict with weakening `attached` / `stale` / `detached` monitoring. Those states describe terminal connection precision for display and cleanup; they are not the island's core running / approval / question / completed state. Terminal probing should primarily serve the jump-back interaction, using pre-warm and short-lived cache behavior, rather than continuously proving that every session is still attached.

## Later Slice: Lower-Priority Attachment State Reconciliation

`attached`, `stale`, and `detached` should remain useful when the app needs cleanup or diagnostics, but they should not drive high-frequency terminal checks:

- Let hook and bridge events drive the core visible session phase.
- Reconcile attachment state at a lower cadence when the island is idle.
- Prefer event or process liveness signals over terminal-window precision for normal display.
- Run precise terminal attachment checks when preparing jump targets or when a session is old enough to need cleanup.

## Later Slice: On-Demand Usage Refresh

Codex and Claude usage totals are useful context, but they are not part of the core display, notification, and jump-back loop. If refreshing is effectively immediate, prefer demand-driven refresh over any periodic monitoring:

- Do not poll usage data on a background loop by default.
- Refresh immediately when the user opens the settings or usage surface.
- Refresh immediately when the UI exposes per-conversation token or mtoken cost.
- Use cached values while the usage UI is closed.
- Preserve manual refresh behavior for setup or diagnostics flows.

## Later Slice: Codex Rollout Fallback Gating

Keep rollout file watching available for reliability, but avoid duplicating real-time event work:

- Prefer bridge, hook, or Codex app-server events when those channels are connected and recently healthy.
- Pause or greatly reduce rollout watcher polling for Codex sessions covered by a healthy real-time channel.
- Resume rollout polling as a fallback when the real-time channel disconnects, misses expected state, or has not delivered recent updates.
- Avoid duplicate completion or activity events when both channels report the same session.

## Later Slice: Tool-Scoped Persistence

Avoid scheduling every persistence store after every event:

- Codex events schedule Codex persistence only.
- Claude-family events schedule their relevant Claude-compatible persistence only.
- OpenCode events schedule OpenCode persistence only.
- Cursor events schedule Cursor persistence only.
- Unknown or cross-tool events can fall back to the broader persistence path.
- If applying an event does not change state, skip persistence entirely.

## Verification Path

- Unit test the cache freshness and click-time fallback policy.
- Unit test attachment reconciliation cadence if it receives its own scheduler.
- Unit test usage refresh triggers if the implementation adds an explicit usage-refresh coordinator.
- Unit test rollout fallback gating for healthy and disconnected real-time channels.
- Unit test tool-scoped persistence scheduling and no-op event short-circuiting.
- Run `swift test`.
- Refresh `Open Island Dev.app` with `zsh scripts/launch-dev-app.sh`.
- Confirm the running dev app was refreshed from the intended commit.
- Manually observe Activity Monitor after several idle minutes; the 12 hour energy column is cumulative, so prefer current "Energy Impact" trend after the new process has been running.

## Risks

- Overly stale cached targets could jump to the right app but wrong pane.
- Too much pre-warming would reintroduce the energy cost under a different trigger.
- Terminal-specific resolvers have different latency profiles, so the short-budget behavior may need per-terminal tuning.
