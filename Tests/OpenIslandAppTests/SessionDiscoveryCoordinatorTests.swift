import Foundation
import Testing
@testable import OpenIslandApp
import OpenIslandCore

struct SessionDiscoveryCoordinatorTests {
    @Test
    func codexRolloutTargetsExcludeHealthyRealtimeSessions() {
        let sessions = [
            codexSession(id: "covered", transcriptPath: "/tmp/covered.jsonl"),
            codexSession(id: "fallback", transcriptPath: "/tmp/fallback.jsonl"),
        ]

        let targets = SessionDiscoveryCoordinator.codexRolloutWatchTargets(
            for: sessions,
            healthyRealtimeCodexSessionIDs: ["covered"]
        )

        #expect(targets.map(\.sessionID) == ["fallback"])
    }

    @Test
    func codexRolloutTargetsResumeWhenRealtimeHealthExpires() {
        let sessions = [
            codexSession(id: "fallback", transcriptPath: "/tmp/fallback.jsonl"),
        ]

        let targets = SessionDiscoveryCoordinator.codexRolloutWatchTargets(
            for: sessions,
            healthyRealtimeCodexSessionIDs: []
        )

        #expect(targets.map(\.sessionID) == ["fallback"])
    }

    @Test
    func codexRolloutTargetsAllowCodexAppSessionsWhenRealtimeIsStale() {
        var session = codexSession(id: "app", transcriptPath: "/tmp/app.jsonl")
        session.isCodexAppSession = true

        let targets = SessionDiscoveryCoordinator.codexRolloutWatchTargets(
            for: [session],
            healthyRealtimeCodexSessionIDs: []
        )

        #expect(targets.map(\.sessionID) == ["app"])
    }

    @Test
    func codexRolloutTargetsSkipCodexAppSessionsWhenRealtimeIsHealthy() {
        var session = codexSession(id: "app", transcriptPath: "/tmp/app.jsonl")
        session.isCodexAppSession = true

        let targets = SessionDiscoveryCoordinator.codexRolloutWatchTargets(
            for: [session],
            healthyRealtimeCodexSessionIDs: ["app"]
        )

        #expect(targets.isEmpty)
    }

    @Test
    func codexAppFallbackSkipsOldUntrackedHistory() throws {
        let thread = try codexThread(id: "old", status: "notLoaded", updatedAt: 1_000)

        #expect(!CodexAppServerCoordinator.hasRecentUnsyncedFallbackCandidate(
            in: [thread],
            now: Date(timeIntervalSince1970: 2_000),
            isSessionTracked: { _ in false }
        ))
    }

    @Test
    func codexAppFallbackRunsForRecentUntrackedNonActiveThread() throws {
        let thread = try codexThread(id: "recent", status: "notLoaded", updatedAt: 1_950)

        #expect(CodexAppServerCoordinator.hasRecentUnsyncedFallbackCandidate(
            in: [thread],
            now: Date(timeIntervalSince1970: 2_000),
            isSessionTracked: { _ in false }
        ))
    }

    @Test
    func codexAppFallbackSkipsAlreadyTrackedThread() throws {
        let thread = try codexThread(id: "tracked", status: "notLoaded", updatedAt: 1_950)

        #expect(!CodexAppServerCoordinator.hasRecentUnsyncedFallbackCandidate(
            in: [thread],
            now: Date(timeIntervalSince1970: 2_000),
            isSessionTracked: { $0 == "tracked" }
        ))
    }

    @Test
    func codexAppSyncIncludesTrackedIdleThreadFromAllThreads() throws {
        let idle = try codexThread(id: "tracked", status: "idle", updatedAt: 1_950)

        let threads = CodexAppServerCoordinator.syncableThreads(
            loadedThreads: [],
            allThreads: [idle],
            isSessionTracked: { $0 == "tracked" }
        )

        #expect(threads.map(\.id) == ["tracked"])
        #expect(threads.first?.status.type == .idle)
    }

    @Test
    func codexAppSyncSkipsUntrackedIdleThreadFromAllThreads() throws {
        let idle = try codexThread(id: "untracked", status: "idle", updatedAt: 1_950)

        let threads = CodexAppServerCoordinator.syncableThreads(
            loadedThreads: [],
            allThreads: [idle],
            isSessionTracked: { _ in false }
        )

        #expect(threads.isEmpty)
    }

    @Test
    func codexAppSyncDoesNotReplaceNewerLoadedActiveWithOlderIdle() throws {
        let active = try codexThread(id: "tracked", status: "active", updatedAt: 2_000)
        let olderIdle = try codexThread(id: "tracked", status: "idle", updatedAt: 1_950)

        let threads = CodexAppServerCoordinator.syncableThreads(
            loadedThreads: [active],
            allThreads: [olderIdle],
            isSessionTracked: { $0 == "tracked" }
        )

        #expect(threads.map(\.id) == ["tracked"])
        #expect(threads.first?.status.type == .active)
    }

    @Test
    func codexAppSyncDoesNotReemitAlreadyRunningThread() throws {
        let status = try codexStatus(type: "active")

        #expect(!CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            status,
            currentPhase: .running
        ))
        #expect(CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            status,
            currentPhase: .completed
        ))
    }

    @Test
    func codexAppSyncOnlyReemitsChangedActionableState() throws {
        let approval = try codexStatus(type: "active", activeFlags: ["waitingOnApproval"])
        let input = try codexStatus(type: "active", activeFlags: ["waitingOnUserInput"])

        #expect(!CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            approval,
            currentPhase: .waitingForApproval
        ))
        #expect(CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            approval,
            currentPhase: .running
        ))
        #expect(!CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            input,
            currentPhase: .waitingForAnswer
        ))
    }

    @Test
    func codexAppSyncCompletesRunningThreadWhenServerReportsIdle() throws {
        let idle = try codexStatus(type: "idle")

        #expect(CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            idle,
            currentPhase: .running
        ))
        #expect(CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            idle,
            currentPhase: .waitingForApproval
        ))
        #expect(!CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            idle,
            currentPhase: .completed
        ))
        #expect(!CodexAppServerCoordinator.shouldEmitSyncedStatusUpdate(
            idle,
            currentPhase: nil
        ))
    }

    @Test
    func codexAppIdleSyncUsesCompletionNotificationEvent() throws {
        let idle = try codexStatus(type: "idle")
        let timestamp = Date(timeIntervalSince1970: 2_000)
        let event = CodexAppServerCoordinator.syncedStatusEvent(
            idle,
            for: "thread-1",
            timestamp: timestamp
        )

        guard case let .sessionCompleted(payload) = event else {
            Issue.record("Expected idle sync to emit sessionCompleted.")
            return
        }

        #expect(payload.sessionID == "thread-1")
        #expect(payload.summary == "Turn completed.")
        #expect(payload.timestamp == timestamp)
        #expect(payload.isSessionEnd == false)
    }
}

private func codexSession(id: String, transcriptPath: String) -> AgentSession {
    AgentSession(
        id: id,
        title: id,
        tool: .codex,
        phase: .running,
        summary: "Running",
        updatedAt: Date(timeIntervalSince1970: 1_000),
        codexMetadata: CodexSessionMetadata(transcriptPath: transcriptPath)
    )
}

private func codexThread(id: String, status: String, updatedAt: Int) throws -> CodexThread {
    let json = """
    {
      "id": "\(id)",
      "cwd": "/tmp/open-island",
      "name": null,
      "preview": "",
      "modelProvider": "openai",
      "createdAt": 1000,
      "updatedAt": \(updatedAt),
      "ephemeral": false,
      "path": "/tmp/rollout-\(id).jsonl",
      "status": { "type": "\(status)" },
      "source": "vscode",
      "turns": null
    }
    """

    return try JSONDecoder().decode(CodexThread.self, from: Data(json.utf8))
}

private func codexStatus(
    type: String,
    activeFlags: [String]? = nil
) throws -> CodexThreadStatus {
    let flagsJSON = activeFlags.map { flags in
        let values = flags.map { "\"\($0)\"" }.joined(separator: ",")
        return ", \"activeFlags\": [\(values)]"
    } ?? ""
    let json = """
    { "type": "\(type)"\(flagsJSON) }
    """

    return try JSONDecoder().decode(CodexThreadStatus.self, from: Data(json.utf8))
}
