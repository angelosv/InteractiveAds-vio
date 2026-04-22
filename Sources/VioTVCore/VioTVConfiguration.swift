import Foundation

public enum VioTVEnvironment: String, Codable {
    case development
    case testing

    public var defaultBackendURL: String {
        switch self {
        case .development: return "https://api-local-angelo.vio.live"
        case .testing: return "https://api-dev.vio.live"
        }
    }

    public var defaultCommerceURL: String {
        switch self {
        case .development: return "https://graph-ql-dev.vio.live/graphql"
        case .testing: return "https://graph-ql-dev.vio.live/graphql"
        }
    }

    public var defaultWebSocketBaseURL: String {
        switch self {
        case .development: return "wss://api-local-angelo.vio.live/ws"
        case .testing: return "wss://api-dev.vio.live/ws"
        }
    }
}

public struct VioTVFileConfiguration: Codable {
    public let apiKey: String
    /// Only used as a **dev-only fallback** when the SDK hasn't run `connect(broadcastId:)` yet
    /// or the backend response didn't include a primary-sponsor commerce block. In production
    /// the SDK uses sponsor-specific keys from `/api/sdk/tv/broadcast/subscribe`.
    public let commerceApiKey: String?
    public let campaignId: Int?
    /// Partner-internal broadcast identifier (e.g. `"barcelona-psg-2026-03-03"`). When set,
    /// `VioTV.connect()` without args uses this as the `broadcastId` sent to
    /// `POST /api/sdk/tv/broadcast/subscribe`. Aligned with the backend nomenclature
    /// (`broadcasts.broadcast_id`) — no longer aliased as `contentId`.
    public let broadcastId: String?
    public let userId: String?
    public let environment: String?
    public let backendURL: String?
    public let webSocketBaseURL: String?
    public let commerceURL: String?
    public let devBackendURL: String?
    public let devWebSocketBaseURL: String?
    public let devCommerceURL: String?

    public init(
        apiKey: String,
        commerceApiKey: String? = nil,
        campaignId: Int? = nil,
        broadcastId: String? = nil,
        userId: String? = nil,
        environment: String? = nil,
        backendURL: String? = nil,
        webSocketBaseURL: String? = nil,
        commerceURL: String? = nil,
        devBackendURL: String? = nil,
        devWebSocketBaseURL: String? = nil,
        devCommerceURL: String? = nil
    ) {
        self.apiKey = apiKey
        self.commerceApiKey = commerceApiKey
        self.campaignId = campaignId
        self.broadcastId = broadcastId
        self.userId = userId
        self.environment = environment
        self.backendURL = backendURL
        self.webSocketBaseURL = webSocketBaseURL
        self.commerceURL = commerceURL
        self.devBackendURL = devBackendURL
        self.devWebSocketBaseURL = devWebSocketBaseURL
        self.devCommerceURL = devCommerceURL
    }

    enum CodingKeys: String, CodingKey {
        case apiKey, commerceApiKey, campaignId, broadcastId, userId, environment
        case backendURL = "backendUrl"
        case webSocketBaseURL = "webSocketUrl"
        case commerceURL = "commerceUrl"
        case devBackendURL
        case devWebSocketBaseURL
        case devCommerceURL
    }
}

public enum VioTVConfigurationLoader {
    public static func loadConfiguration(
        fileName: String? = nil,
        bundle: Bundle = .main
    ) throws -> VioTVFileConfiguration {
        let candidates = candidateConfigNames(explicitFileName: fileName)
        for name in candidates {
            guard let url = bundle.url(forResource: name, withExtension: "json") else {
                continue
            }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(VioTVFileConfiguration.self, from: data)
            return decoded
        }
        throw NSError(
            domain: "VioTVConfigurationLoader",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "No VioTV config JSON found in bundle."]
        )
    }

    private static func candidateConfigNames(explicitFileName: String?) -> [String] {
        if let explicitFileName, !explicitFileName.isEmpty {
            return [explicitFileName]
        }
        if let configType = ProcessInfo.processInfo.environment["VIO_CONFIG_TYPE"], !configType.isEmpty {
            return ["vio-config-\(configType)"]
        }
        return ["vio-config", "vio-config-automatic", "vio-config-example", "vio-config-dark-streaming"]
    }
}

public final class VioTVConfiguration {
    public static let shared = VioTVConfiguration()

    public private(set) var apiKey: String = ""
    /// **Dev-only fallback** commerce key. Production commerce keys come per-sponsor from
    /// `/api/sdk/tv/broadcast/subscribe` and are stored in ``primarySponsor`` / ``secondarySponsors``.
    /// Resolve with ``commerce(forSponsorId:)``.
    public private(set) var commerceApiKey: String = ""
    public private(set) var userId: String = ""
    public private(set) var defaultCampaignId: Int?
    /// Partner-internal broadcast id loaded from `vio-config.json` (`contentId`). Preferred
    /// argument for `VioTV.connect()` when the host app doesn't pass an explicit broadcastId.
    public private(set) var defaultBroadcastId: String?
    public private(set) var environment: VioTVEnvironment = .development
    public private(set) var backendURLOverride: String?
    public private(set) var webSocketBaseURLOverride: String?
    public private(set) var commerceURLOverride: String?

    // Multi-sponsor state populated by `/api/sdk/tv/broadcast/subscribe`.
    public private(set) var primarySponsor: VioTVSponsor?
    public private(set) var secondarySponsors: [VioTVSponsor] = []
    /// tv_sessions row id returned by the backend. Used by heartbeat + end.
    public internal(set) var currentSessionId: Int?
    /// end_users.id for the connected viewer. Used as foreign key on cart_intents.
    public internal(set) var currentEndUserId: Int?

    private init() {}

    public var backendURL: String {
        backendURLOverride ?? environment.defaultBackendURL
    }

    public var commerceURL: String {
        commerceURLOverride ?? environment.defaultCommerceURL
    }

    public var webSocketBaseURL: String {
        webSocketBaseURLOverride ?? environment.defaultWebSocketBaseURL
    }

    /// Look up any sponsor by id — primary first, then secondaries.
    public func sponsor(withId id: Int) -> VioTVSponsor? {
        if primarySponsor?.id == id { return primarySponsor }
        return secondarySponsors.first { $0.id == id }
    }

    /// Commerce credentials for a specific sponsor id from the most recent subscribe response.
    /// Falls back to the local `commerceApiKey` (dev-only) when no sponsor matches.
    public func commerce(forSponsorId id: Int?) -> VioTVSponsor.CommerceBlock? {
        if let id, let block = sponsor(withId: id)?.commerce {
            return block
        }
        if !commerceApiKey.isEmpty {
            return VioTVSponsor.CommerceBlock(apiKey: commerceApiKey)
        }
        return primarySponsor?.commerce
    }

    public func configure(
        apiKey: String,
        commerceApiKey: String = "",
        userId: String = "",
        environment: VioTVEnvironment = .development,
        defaultCampaignId: Int? = nil,
        defaultBroadcastId: String? = nil,
        backendURLOverride: String? = nil,
        webSocketBaseURLOverride: String? = nil,
        commerceURLOverride: String? = nil
    ) {
        self.apiKey = apiKey
        self.commerceApiKey = commerceApiKey
        self.userId = userId
        self.environment = environment
        self.defaultCampaignId = defaultCampaignId
        self.defaultBroadcastId = defaultBroadcastId
        self.backendURLOverride = sanitize(url: backendURLOverride)
        self.webSocketBaseURLOverride = sanitize(url: webSocketBaseURLOverride)
        self.commerceURLOverride = sanitize(url: commerceURLOverride)
        let broadcastLabel = defaultBroadcastId ?? defaultCampaignId.map(String.init) ?? "(none)"
        print("[VioTV] Configured - env: \(environment.rawValue), broadcast: \(broadcastLabel), ws: \(webSocketBaseURL)")
    }

    public func applyFileConfiguration(_ fileConfig: VioTVFileConfiguration, userIdOverride: String? = nil) {
        let env = VioTVEnvironment(rawValue: (fileConfig.environment ?? "development").lowercased()) ?? .development
        let backendOverride = resolvedBackendURL(fileConfig: fileConfig, environment: env)
        let wsOverride = resolvedWebSocketURL(fileConfig: fileConfig, environment: env)
        let commerceOverride = resolvedCommerceURL(fileConfig: fileConfig, environment: env)

        configure(
            apiKey: fileConfig.apiKey,
            commerceApiKey: fileConfig.commerceApiKey ?? "",
            userId: userIdOverride ?? fileConfig.userId ?? "",
            environment: env,
            defaultCampaignId: fileConfig.campaignId,
            defaultBroadcastId: fileConfig.broadcastId,
            backendURLOverride: backendOverride,
            webSocketBaseURLOverride: wsOverride,
            commerceURLOverride: commerceOverride
        )
    }

    /// Populate ``primarySponsor`` / ``secondarySponsors`` / ``currentSessionId`` from the
    /// response of `POST /api/sdk/tv/broadcast/subscribe`.
    public func applySubscribeResponse(_ response: VioTVSubscribeResponse) {
        self.primarySponsor = response.primarySponsor
        self.secondarySponsors = response.secondarySponsors ?? []
        self.currentSessionId = response.sessionId
        self.currentEndUserId = response.endUserId
    }

    /// Clear multi-sponsor state on disconnect.
    public func clearSubscribeState() {
        self.primarySponsor = nil
        self.secondarySponsors = []
        self.currentSessionId = nil
        self.currentEndUserId = nil
    }

    public func loadFromEnvironment() {
        let env = VioTVEnvironment(rawValue: (ProcessInfo.processInfo.environment["VIO_ENVIRONMENT"] ?? "").lowercased()) ?? environment
        let apiKey = ProcessInfo.processInfo.environment["VIO_API_KEY"] ?? apiKey
        let commerceKey = ProcessInfo.processInfo.environment["VIO_COMMERCE_API_KEY"] ?? commerceApiKey
        let userId = ProcessInfo.processInfo.environment["VIO_USER_ID"] ?? userId
        let campaignId = ProcessInfo.processInfo.environment["VIO_CAMPAIGN_ID"].flatMap { Int($0) } ?? defaultCampaignId

        configure(
            apiKey: apiKey,
            commerceApiKey: commerceKey,
            userId: userId,
            environment: env,
            defaultCampaignId: campaignId,
            defaultBroadcastId: ProcessInfo.processInfo.environment["VIO_BROADCAST_ID"] ?? defaultBroadcastId,
            backendURLOverride: ProcessInfo.processInfo.environment["VIO_BACKEND_URL"],
            webSocketBaseURLOverride: ProcessInfo.processInfo.environment["VIO_WS_BASE_URL"],
            commerceURLOverride: ProcessInfo.processInfo.environment["VIO_COMMERCE_URL"]
        )
    }

    private func sanitize(url: String?) -> String? {
        guard let raw = url?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        guard URL(string: raw) != nil else { return nil }
        // Normalize to avoid double slashes when SDK concatenates API paths.
        if raw.count > 1, raw.hasSuffix("/") {
            return String(raw.dropLast())
        }
        return raw
    }

    private func resolvedBackendURL(fileConfig: VioTVFileConfiguration, environment: VioTVEnvironment) -> String? {
        if environment == .development, let dev = sanitize(url: fileConfig.devBackendURL) {
            return dev
        }
        return sanitize(url: fileConfig.backendURL)
    }

    private func resolvedWebSocketURL(fileConfig: VioTVFileConfiguration, environment: VioTVEnvironment) -> String? {
        if environment == .development, let dev = sanitize(url: fileConfig.devWebSocketBaseURL) {
            return dev
        }
        return sanitize(url: fileConfig.webSocketBaseURL)
    }

    private func resolvedCommerceURL(fileConfig: VioTVFileConfiguration, environment: VioTVEnvironment) -> String? {
        if environment == .development, let dev = sanitize(url: fileConfig.devCommerceURL) {
            return dev
        }
        return sanitize(url: fileConfig.commerceURL)
    }
}
