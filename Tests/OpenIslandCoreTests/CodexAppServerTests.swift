import Foundation
import Testing
@testable import OpenIslandCore

struct CodexAppServerTests {
    @Test
    func threadListResultDecodesCurrentDataEnvelope() throws {
        let json = """
        {
          "data": [
            {
              "id": "thread-1",
              "sessionId": "thread-1",
              "forkedFromId": "parent-thread",
              "cwd": "/tmp/open-island",
              "name": "Fix Codex detection",
              "preview": "Make Codex.app visible in the island.",
              "modelProvider": "openai",
              "createdAt": 1000,
              "updatedAt": 1100,
              "ephemeral": false,
              "path": "/tmp/rollout-thread-1.jsonl",
              "status": { "type": "notLoaded" },
              "source": "vscode"
            }
          ],
          "nextCursor": null
        }
        """

        let result = try JSONDecoder().decode(
            CodexThreadListResult.self,
            from: Data(json.utf8)
        )

        #expect(result.threads.map(\.id) == ["thread-1"])
        #expect(result.threads.first?.sessionId == "thread-1")
        #expect(result.threads.first?.forkedFromId == "parent-thread")
        #expect(result.threads.first?.status.type == .notLoaded)
        #expect(result.threads.first?.path == "/tmp/rollout-thread-1.jsonl")
    }

    @Test
    func threadListResultStillDecodesLegacyThreadsEnvelope() throws {
        let json = """
        {
          "threads": [
            {
              "id": "thread-2",
              "cwd": "/tmp/open-island",
              "name": "Active Codex thread",
              "preview": "Running.",
              "modelProvider": "openai",
              "createdAt": 1000,
              "updatedAt": 1100,
              "ephemeral": false,
              "path": "/tmp/rollout-thread-2.jsonl",
              "status": { "type": "active", "activeFlags": [] },
              "source": "app-server"
            }
          ]
        }
        """

        let result = try JSONDecoder().decode(
            CodexThreadListResult.self,
            from: Data(json.utf8)
        )

        #expect(result.threads.map(\.id) == ["thread-2"])
        #expect(result.threads.first?.status.type == .active)
        #expect(result.threads.first?.source == .appServer)
    }
}
