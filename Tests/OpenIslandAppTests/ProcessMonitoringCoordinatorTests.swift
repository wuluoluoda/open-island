import Foundation
import Testing
@testable import OpenIslandApp
import OpenIslandCore

struct ProcessMonitoringCoordinatorTests {
    @Test
    func monitorSleepDurationStaysFastDuringStartup() {
        #expect(ProcessMonitoringCoordinator.monitorSleepDuration(
            for: [],
            isResolvingInitialLiveSessions: true
        ) == .seconds(2))
    }

    @Test
    func monitorSleepDurationBacksOffWhenIdle() {
        #expect(ProcessMonitoringCoordinator.monitorSleepDuration(
            for: [],
            isResolvingInitialLiveSessions: false
        ) == .seconds(8))
    }

    @Test
    func monitorSleepDurationStaysFastForActiveWork() {
        #expect(ProcessMonitoringCoordinator.monitorSleepDuration(
            for: [
                AgentSession(
                    id: "running",
                    title: "Running",
                    tool: .codex,
                    phase: .running,
                    summary: "Working",
                    updatedAt: .now
                ),
            ],
            isResolvingInitialLiveSessions: false
        ) == .seconds(2))
    }

    @Test
    func monitorSleepDurationUsesQuietCadenceForCompletedSessions() {
        #expect(ProcessMonitoringCoordinator.monitorSleepDuration(
            for: [
                AgentSession(
                    id: "completed",
                    title: "Completed",
                    tool: .codex,
                    phase: .completed,
                    summary: "Done",
                    updatedAt: .now
                ),
            ],
            isResolvingInitialLiveSessions: false
        ) == .seconds(5))
    }

    @Test
    func cachedJumpTargetFreshnessHonorsTTL() {
        let resolvedAt = Date(timeIntervalSince1970: 1_000)

        #expect(ProcessMonitoringCoordinator.cachedJumpTargetIsFresh(
            resolvedAt: resolvedAt,
            now: resolvedAt.addingTimeInterval(29.9)
        ))
        #expect(!ProcessMonitoringCoordinator.cachedJumpTargetIsFresh(
            resolvedAt: resolvedAt,
            now: resolvedAt.addingTimeInterval(30.1)
        ))
    }

    @Test
    @MainActor
    func jumpClickUsesFreshCachedTarget() {
        let coordinator = ProcessMonitoringCoordinator()
        let resolvedAt = Date(timeIntervalSince1970: 2_000)
        let sessionTarget = jumpTarget(title: "older")
        let cachedTarget = jumpTarget(title: "fresh")
        let session = AgentSession(
            id: "session",
            title: "Session",
            tool: .codex,
            origin: .demo,
            phase: .running,
            summary: "Running",
            updatedAt: resolvedAt,
            jumpTarget: sessionTarget
        )

        coordinator.cacheJumpTarget(cachedTarget, for: session.id, resolvedAt: resolvedAt)

        #expect(coordinator.jumpTargetForClick(
            session,
            now: resolvedAt.addingTimeInterval(5)
        ) == cachedTarget)
    }

    @Test
    @MainActor
    func jumpClickFallsBackToKnownSessionTargetWhenCacheIsStale() {
        let coordinator = ProcessMonitoringCoordinator()
        let resolvedAt = Date(timeIntervalSince1970: 3_000)
        let sessionTarget = jumpTarget(title: "current")
        let staleTarget = jumpTarget(title: "stale")
        let session = AgentSession(
            id: "session",
            title: "Session",
            tool: .codex,
            origin: .demo,
            phase: .running,
            summary: "Running",
            updatedAt: resolvedAt,
            jumpTarget: sessionTarget
        )

        coordinator.cacheJumpTarget(staleTarget, for: session.id, resolvedAt: resolvedAt)

        #expect(coordinator.jumpTargetForClick(
            session,
            now: resolvedAt.addingTimeInterval(31)
        ) == sessionTarget)
    }
}

private func jumpTarget(title: String) -> JumpTarget {
    JumpTarget(
        terminalApp: "Ghostty",
        workspaceName: "open-island",
        paneTitle: title,
        workingDirectory: "/tmp/open-island",
        terminalSessionID: title
    )
}
