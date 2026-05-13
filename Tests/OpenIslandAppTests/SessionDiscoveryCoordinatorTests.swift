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
            now: Date(timeIntervalSince1970: 2_000),
            isSessionTracked: { $0 == "tracked" }
        )

        #expect(threads.map(\.id) == ["tracked"])
        #expect(threads.first?.status.type == .idle)
    }

    @Test
    func codexAppSyncIncludesRecentUntrackedForkedThreadFromAllThreads() throws {
        let forkShell = try codexThread(
            id: "fork-shell",
            status: "notLoaded",
            updatedAt: 1_950,
            forkedFromId: "parent-thread"
        )

        let threads = CodexAppServerCoordinator.syncableThreads(
            loadedThreads: [],
            allThreads: [forkShell],
            now: Date(timeIntervalSince1970: 2_000),
            isSessionTracked: { _ in false }
        )

        #expect(threads.map(\.id) == ["fork-shell"])
        #expect(threads.first?.status.type == .notLoaded)
    }

    @Test
    func codexAppSyncIncludesRecentUntrackedThreadWithForkedRolloutMarker() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("open-island-app-fork-marker-\(UUID().uuidString)", isDirectory: true)
        let rolloutURL = rootURL.appendingPathComponent("rollout-fork.jsonl")

        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let line = """
        {"type":"session_meta","payload":{"id":"fork-shell","forked_from_id":"parent-thread","timestamp":"2026-05-13T08:00:00.000Z","cwd":"/tmp/open-island","originator":"Codex Desktop"}}
        """
        try "\(line)\n".write(to: rolloutURL, atomically: true, encoding: .utf8)

        let forkShell = try codexThread(
            id: "fork-shell",
            status: "notLoaded",
            updatedAt: 1_950,
            path: rolloutURL.path
        )

        let threads = CodexAppServerCoordinator.syncableThreads(
            loadedThreads: [],
            allThreads: [forkShell],
            now: Date(timeIntervalSince1970: 2_000),
            isSessionTracked: { _ in false }
        )

        #expect(threads.map(\.id) == ["fork-shell"])
    }

    @Test
    func codexAppSyncSkipsRecentUntrackedNonForkedThreadFromAllThreads() throws {
        let regularShell = try codexThread(id: "regular-shell", status: "notLoaded", updatedAt: 1_950)

        let threads = CodexAppServerCoordinator.syncableThreads(
            loadedThreads: [],
            allThreads: [regularShell],
            now: Date(timeIntervalSince1970: 2_000),
            isSessionTracked: { _ in false }
        )

        #expect(threads.isEmpty)
    }

    @Test
    func codexAppSyncSkipsOldUntrackedIdleThreadFromAllThreads() throws {
        let idle = try codexThread(id: "untracked", status: "idle", updatedAt: 1_000)

        let threads = CodexAppServerCoordinator.syncableThreads(
            loadedThreads: [],
            allThreads: [idle],
            now: Date(timeIntervalSince1970: 2_000),
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
            now: Date(timeIntervalSince1970: 2_000),
            isSessionTracked: { $0 == "tracked" }
        )

        #expect(threads.map(\.id) == ["tracked"])
        #expect(threads.first?.status.type == .active)
    }

    @Test
    func codexAppRediscoveryEmitsCompletionForTrackedRunningSession() {
        var existing = codexSession(id: "tracked", transcriptPath: "/tmp/tracked.jsonl")
        existing.isCodexAppSession = true
        existing.phase = .running
        existing.summary = "Codex is working..."
        existing.updatedAt = Date(timeIntervalSince1970: 1_000)

        var discovered = existing
        discovered.phase = .completed
        discovered.summary = "Done."
        discovered.updatedAt = Date(timeIntervalSince1970: 1_050)

        let events = SessionDiscoveryCoordinator.rediscoveredCompletionEvents(
            existingSessions: [existing],
            discoveredSessions: [discovered]
        )

        guard case let .sessionCompleted(payload) = events.first else {
            Issue.record("Expected rediscovery to emit a completion event.")
            return
        }

        #expect(events.count == 1)
        #expect(payload.sessionID == "tracked")
        #expect(payload.summary == "Done.")
        #expect(payload.timestamp == Date(timeIntervalSince1970: 1_050))
        #expect(payload.isSessionEnd == false)
    }

    @Test
    func codexAppRediscoveryPreservesActiveStateUntilCompletionEventIsApplied() {
        var existing = codexSession(id: "tracked", transcriptPath: "/tmp/tracked.jsonl")
        existing.isCodexAppSession = true
        existing.phase = .running
        existing.summary = "Codex is working..."
        existing.updatedAt = Date(timeIntervalSince1970: 1_000)

        var discovered = existing
        discovered.phase = .completed
        discovered.summary = "Done."
        discovered.updatedAt = Date(timeIntervalSince1970: 1_050)

        let preserved = SessionDiscoveryCoordinator.preserveActiveStateForRediscoveredCompletions(
            [discovered],
            existingSessions: [existing]
        )

        #expect(preserved.first?.phase == .running)
        #expect(preserved.first?.summary == "Codex is working...")
        #expect(preserved.first?.updatedAt == Date(timeIntervalSince1970: 1_000))
    }

    @Test
    func codexAppRediscoverySkipsStaleCompletion() {
        var existing = codexSession(id: "tracked", transcriptPath: "/tmp/tracked.jsonl")
        existing.isCodexAppSession = true
        existing.phase = .running
        existing.updatedAt = Date(timeIntervalSince1970: 1_100)

        var discovered = existing
        discovered.phase = .completed
        discovered.updatedAt = Date(timeIntervalSince1970: 1_050)

        let events = SessionDiscoveryCoordinator.rediscoveredCompletionEvents(
            existingSessions: [existing],
            discoveredSessions: [discovered]
        )

        #expect(events.isEmpty)
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

private func codexThread(
    id: String,
    status: String,
    updatedAt: Int,
    forkedFromId: String? = nil,
    path: String? = nil
) throws -> CodexThread {
    let forkedFromIdJSON = forkedFromId.map { "\"\($0)\"" } ?? "null"
    let pathJSON = path.map { "\"\($0)\"" } ?? "\"/tmp/rollout-\(id).jsonl\""
    let json = """
    {
      "id": "\(id)",
      "forkedFromId": \(forkedFromIdJSON),
      "cwd": "/tmp/open-island",
      "name": null,
      "preview": "",
      "modelProvider": "openai",
      "createdAt": 1000,
      "updatedAt": \(updatedAt),
      "ephemeral": false,
      "path": \(pathJSON),
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
