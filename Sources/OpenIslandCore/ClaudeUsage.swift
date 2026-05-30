import Foundation

public struct ClaudeUsageWindow: Equatable, Codable, Sendable {
    public var usedPercentage: Double
    public var resetsAt: Date?

    public init(usedPercentage: Double, resetsAt: Date?) {
        self.usedPercentage = usedPercentage
        self.resetsAt = resetsAt
    }

    public var roundedUsedPercentage: Int {
        Int(usedPercentage.rounded())
    }
}

public struct ClaudeUsageSnapshot: Equatable, Codable, Sendable {
    public var fiveHour: ClaudeUsageWindow?
    public var sevenDay: ClaudeUsageWindow?
    public var tokenUsage: ClaudeTokenUsageSnapshot?
    public var cachedAt: Date?

    public init(
        fiveHour: ClaudeUsageWindow?,
        sevenDay: ClaudeUsageWindow?,
        tokenUsage: ClaudeTokenUsageSnapshot? = nil,
        cachedAt: Date? = nil
    ) {
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.tokenUsage = tokenUsage
        self.cachedAt = cachedAt
    }

    public var isEmpty: Bool {
        fiveHour == nil && sevenDay == nil && tokenUsage?.isEmpty != false
    }
}

public struct ClaudeTokenUsageWindow: Equatable, Codable, Sendable, Identifiable {
    public var id: String
    public var label: String
    public var totalTokens: Int
    public var inputTokens: Int
    public var cacheCreationInputTokens: Int
    public var cacheReadInputTokens: Int
    public var outputTokens: Int
    public var estimatedCostCNY: Double?

    public init(
        id: String,
        label: String,
        totalTokens: Int = 0,
        inputTokens: Int = 0,
        cacheCreationInputTokens: Int = 0,
        cacheReadInputTokens: Int = 0,
        outputTokens: Int = 0,
        estimatedCostCNY: Double? = nil
    ) {
        self.id = id
        self.label = label
        self.totalTokens = totalTokens
        self.inputTokens = inputTokens
        self.cacheCreationInputTokens = cacheCreationInputTokens
        self.cacheReadInputTokens = cacheReadInputTokens
        self.outputTokens = outputTokens
        self.estimatedCostCNY = estimatedCostCNY
    }

    public var isEmpty: Bool {
        totalTokens <= 0
    }

    fileprivate mutating func add(_ usage: ClaudeTranscriptTokenUsage) {
        inputTokens += usage.inputTokens
        cacheCreationInputTokens += usage.cacheCreationInputTokens
        cacheReadInputTokens += usage.cacheReadInputTokens
        outputTokens += usage.outputTokens
        totalTokens += usage.totalTokens
        if let cost = usage.estimatedCostCNY {
            estimatedCostCNY = (estimatedCostCNY ?? 0) + cost
        }
    }
}

public struct ClaudeTokenUsageSnapshot: Equatable, Codable, Sendable {
    public var fiveHour: ClaudeTokenUsageWindow?
    public var sevenDay: ClaudeTokenUsageWindow?
    public var capturedAt: Date?
    public var sourceFileCount: Int
    public var latestModel: String?

    public init(
        fiveHour: ClaudeTokenUsageWindow?,
        sevenDay: ClaudeTokenUsageWindow?,
        capturedAt: Date?,
        sourceFileCount: Int,
        latestModel: String? = nil
    ) {
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.capturedAt = capturedAt
        self.sourceFileCount = sourceFileCount
        self.latestModel = latestModel
    }

    public var isEmpty: Bool {
        fiveHour?.isEmpty != false && sevenDay?.isEmpty != false
    }
}

public enum ClaudeUsageLoader {
    public static let defaultCacheURL = URL(fileURLWithPath: "/tmp/open-island-rl.json")
    public static let legacyCacheURL = URL(fileURLWithPath: "/tmp/vibe-island-rl.json")
    public static let defaultTranscriptRootURL = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".claude", isDirectory: true)
        .appendingPathComponent("projects", isDirectory: true)
    private static let deepSeekPricingByModel: [String: ClaudeTranscriptPricing] = [
        // Official DeepSeek API CNY pricing checked on 2026-05-30.
        "deepseek-v4-flash": .init(cacheHitInputPerMillion: 0.02, cacheMissInputPerMillion: 1, outputPerMillion: 2),
        "deepseek-chat": .init(cacheHitInputPerMillion: 0.02, cacheMissInputPerMillion: 1, outputPerMillion: 2),
        "deepseek-reasoner": .init(cacheHitInputPerMillion: 0.02, cacheMissInputPerMillion: 1, outputPerMillion: 2),
        "deepseek-v4-pro": .init(cacheHitInputPerMillion: 0.025, cacheMissInputPerMillion: 3, outputPerMillion: 6),
    ]

    public static func load() throws -> ClaudeUsageSnapshot? {
        try load(from: [defaultCacheURL, legacyCacheURL], transcriptRootURL: defaultTranscriptRootURL)
    }

    public static func load(
        from urls: [URL],
        transcriptRootURL: URL
    ) throws -> ClaudeUsageSnapshot? {
        let rateLimitSnapshot = try load(from: urls)
        let tokenUsage = try loadTokenUsage(fromRootURL: transcriptRootURL)

        guard rateLimitSnapshot != nil || tokenUsage != nil else {
            return nil
        }

        return ClaudeUsageSnapshot(
            fiveHour: rateLimitSnapshot?.fiveHour,
            sevenDay: rateLimitSnapshot?.sevenDay,
            tokenUsage: tokenUsage,
            cachedAt: rateLimitSnapshot?.cachedAt ?? tokenUsage?.capturedAt
        )
    }

    public static func load(from url: URL) throws -> ClaudeUsageSnapshot? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let payload = object as? [String: Any] else {
            return nil
        }

        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let cachedAt = attributes?[.modificationDate] as? Date
        let snapshot = ClaudeUsageSnapshot(
            fiveHour: usageWindow(for: "five_hour", in: payload),
            sevenDay: usageWindow(for: "seven_day", in: payload),
            cachedAt: cachedAt
        )

        return snapshot.isEmpty ? nil : snapshot
    }

    public static func load(from urls: [URL]) throws -> ClaudeUsageSnapshot? {
        let candidates = urls
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map { url in
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let modificationDate = attributes?[.modificationDate] as? Date ?? .distantPast
                return (url, modificationDate)
            }
            .sorted { lhs, rhs in
                lhs.1 > rhs.1
            }

        for (url, _) in candidates {
            if let snapshot = try load(from: url) {
                return snapshot
            }
        }

        return nil
    }

    public static func loadTokenUsage(
        fromRootURL rootURL: URL = defaultTranscriptRootURL,
        now: Date = .now,
        fileManager: FileManager = .default
    ) throws -> ClaudeTokenUsageSnapshot? {
        guard fileManager.fileExists(atPath: rootURL.path),
              let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else {
            return nil
        }

        var fiveHour = ClaudeTokenUsageWindow(id: "5h", label: "5h")
        var sevenDay = ClaudeTokenUsageWindow(id: "7d", label: "7d")
        var latestModel: String?
        var latestUsageAt: Date?
        var sourceFiles = 0
        let fiveHourStart = now.addingTimeInterval(-5 * 60 * 60)
        let sevenDayStart = now.addingTimeInterval(-7 * 24 * 60 * 60)

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl",
                  let resourceValues = try? fileURL.resourceValues(
                    forKeys: [.contentModificationDateKey, .isRegularFileKey]
                  ),
                  resourceValues.isRegularFile == true else {
                continue
            }

            if let modifiedAt = resourceValues.contentModificationDate,
               modifiedAt < sevenDayStart {
                continue
            }

            guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }

            sourceFiles += 1
            var seenMessageIDs: Set<String> = []

            contents.enumerateLines { line, _ in
                guard let sample = tokenUsageSample(from: line),
                      sample.timestamp >= sevenDayStart,
                      sample.timestamp <= now else {
                    return
                }

                if let messageID = sample.messageID {
                    guard seenMessageIDs.insert(messageID).inserted else {
                        return
                    }
                }

                sevenDay.add(sample.usage)
                if sample.timestamp >= fiveHourStart {
                    fiveHour.add(sample.usage)
                }

                if latestUsageAt == nil || sample.timestamp > latestUsageAt ?? .distantPast {
                    latestUsageAt = sample.timestamp
                    latestModel = sample.model
                }
            }
        }

        let snapshot = ClaudeTokenUsageSnapshot(
            fiveHour: fiveHour.isEmpty ? nil : fiveHour,
            sevenDay: sevenDay.isEmpty ? nil : sevenDay,
            capturedAt: latestUsageAt,
            sourceFileCount: sourceFiles,
            latestModel: latestModel
        )

        return snapshot.isEmpty ? nil : snapshot
    }

    private static func usageWindow(for key: String, in payload: [String: Any]) -> ClaudeUsageWindow? {
        guard let window = payload[key] as? [String: Any],
              let rawPercentage = number(from: window["used_percentage"]) ?? number(from: window["utilization"]) else {
            return nil
        }

        return ClaudeUsageWindow(
            usedPercentage: rawPercentage,
            resetsAt: date(from: window["resets_at"])
        )
    }

    private static func number(from value: Any?) -> Double? {
        switch value {
        case let value as NSNumber:
            value.doubleValue
        case let value as String:
            Double(value)
        default:
            nil
        }
    }

    private static func date(from value: Any?) -> Date? {
        switch value {
        case let value as NSNumber:
            return Date(timeIntervalSince1970: value.doubleValue)
        case let value as String:
            if let seconds = Double(value) {
                return Date(timeIntervalSince1970: seconds)
            }
            let formatterWithFractionalSeconds = ISO8601DateFormatter()
            formatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatterWithFractionalSeconds.date(from: value) {
                return date
            }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) {
                return date
            }
            return nil
        default:
            return nil
        }
    }

    private static func tokenUsageSample(from line: String) -> ClaudeTranscriptUsageSample? {
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["type"] as? String == "assistant",
              let timestamp = date(from: object["timestamp"]),
              let message = object["message"] as? [String: Any],
              let usageObject = message["usage"] as? [String: Any] else {
            return nil
        }

        let usage = ClaudeTranscriptTokenUsage(
            inputTokens: integer(from: usageObject["input_tokens"]) ?? 0,
            cacheCreationInputTokens: integer(from: usageObject["cache_creation_input_tokens"]) ?? 0,
            cacheReadInputTokens: integer(from: usageObject["cache_read_input_tokens"]) ?? 0,
            outputTokens: integer(from: usageObject["output_tokens"]) ?? 0,
            pricing: pricing(for: message["model"])
        )
        guard usage.totalTokens > 0 else {
            return nil
        }

        return ClaudeTranscriptUsageSample(
            messageID: string(from: message["id"]),
            timestamp: timestamp,
            model: string(from: message["model"]),
            usage: usage
        )
    }

    private static func integer(from value: Any?) -> Int? {
        switch value {
        case let number as NSNumber:
            number.intValue
        case let string as String:
            Int(string)
        default:
            nil
        }
    }

    private static func string(from value: Any?) -> String? {
        guard let string = value as? String,
              !string.isEmpty else {
            return nil
        }
        return string
    }

    private static func pricing(for modelValue: Any?) -> ClaudeTranscriptPricing? {
        guard let model = string(from: modelValue)?.lowercased() else {
            return nil
        }
        return deepSeekPricingByModel[model]
    }
}

fileprivate struct ClaudeTranscriptUsageSample {
    var messageID: String?
    var timestamp: Date
    var model: String?
    var usage: ClaudeTranscriptTokenUsage
}

fileprivate struct ClaudeTranscriptTokenUsage {
    var inputTokens: Int
    var cacheCreationInputTokens: Int
    var cacheReadInputTokens: Int
    var outputTokens: Int
    var pricing: ClaudeTranscriptPricing?

    var totalTokens: Int {
        inputTokens + cacheCreationInputTokens + cacheReadInputTokens + outputTokens
    }

    var estimatedCostCNY: Double? {
        guard let pricing else {
            return nil
        }

        let cacheMissInputTokens = inputTokens + cacheCreationInputTokens
        return (Double(cacheMissInputTokens) / 1_000_000 * pricing.cacheMissInputPerMillion)
            + (Double(cacheReadInputTokens) / 1_000_000 * pricing.cacheHitInputPerMillion)
            + (Double(outputTokens) / 1_000_000 * pricing.outputPerMillion)
    }
}

fileprivate struct ClaudeTranscriptPricing {
    var cacheHitInputPerMillion: Double
    var cacheMissInputPerMillion: Double
    var outputPerMillion: Double
}
