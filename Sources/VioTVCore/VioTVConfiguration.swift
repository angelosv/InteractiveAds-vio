import Foundation

/// Vio TV deployment target. Determines the backend + commerce URLs the SDK
/// talks to. Everything else (WebSocket URL, sponsors, commerce keys, campaign
/// id, capabilities, session id) is fetched at runtime via
/// `POST /v2/tv/broadcast/subscribe`.
///
/// To point at a different backend, edit the URL strings here. The SDK is
/// shipped as a Swift Package — partners that need a custom deployment fork
/// the package and bump these values.
public enum VioTVEnvironment: String, Codable {
    case development
    case testing

    public var defaultBackendURL: String {
        switch self {
        case .development: return "https://api-local-angelo.vio.live"
        case .testing:     return "https://api-dev.vio.live"
        }
    }

    /// Reachu Commerce GraphQL endpoint. Per-sponsor `apiKey` for this URL
    /// arrives in the subscribe response (`primarySponsor.commerce.apiKey`,
    /// `secondarySponsors[].commerce.apiKey`). The URL itself is the same
    /// across sponsors — they each have their own channel/key against it.
    public var defaultCommerceURL: String {
        switch self {
        case .development: return "https://graph-ql-dev.vio.live/graphql"
        case .testing:     return "https://graph-ql-dev.vio.live/graphql"
        }
    }
}

/// Shape of `vio-config.json`. **Two fields only** — everything else the SDK
/// needs at runtime comes from the backend (`/v2/tv/broadcast/subscribe`
/// response).
///
/// Example:
/// ```json
/// { "apiKey": "tv2_api_key_91b4fbf634af4bc5", "environment": "development" }
/// ```
public struct VioTVFileConfiguration: Codable {
    public let apiKey: String
    public let environment: String?

    public init(apiKey: String, environment: String? = nil) {
        self.apiKey = apiKey
        self.environment = environment
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

/// Singleton that holds the SDK's resolved configuration plus the runtime
/// state that the backend pushes via the subscribe response.
///
/// **Local config (file-driven):** `apiKey`, `environment`, `userId`. That's it.
///
/// **Backend-driven state:** `primarySponsor`, `secondarySponsors`,
/// `currentSessionId`, `currentEndUserId`, `currentCampaignId`. These get
/// populated by ``applySubscribeResponse(_:)`` and cleared by
/// ``clearSubscribeState()``.
///
/// **Derived URLs:** ``backendURL`` and ``commerceURL`` come from the
/// environment enum — no overrides. The WebSocket URL is *not* derived;
/// it always comes from the subscribe response (`wsUrl` field).
public final class VioTVConfiguration {
    public static let shared = VioTVConfiguration()

    public private(set) var apiKey: String = ""
    public private(set) var userId: String = ""
    public private(set) var environment: VioTVEnvironment = .development

    // Multi-sponsor state populated by `/v2/tv/broadcast/subscribe`.
    public private(set) var primarySponsor: VioTVSponsor?
    public private(set) var secondarySponsors: [VioTVSponsor] = []
    /// tv_sessions row id returned by the backend. Used by heartbeat + end.
    public internal(set) var currentSessionId: Int?
    /// end_users.id for the connected viewer. Used as foreign key on cart_intents.
    public internal(set) var currentEndUserId: Int?
    /// Campaign id resolved by the backend from the broadcast id. Used as
    /// fallback for cart-intent when the shoppable_ad event doesn't carry
    /// `campaignId` inline.
    public internal(set) var currentCampaignId: Int?

    private init() {}

    public var backendURL: String { environment.defaultBackendURL }
    public var commerceURL: String { environment.defaultCommerceURL }

    /// Look up any sponsor by id — primary first, then secondaries.
    public func sponsor(withId id: Int) -> VioTVSponsor? {
        if primarySponsor?.id == id { return primarySponsor }
        return secondarySponsors.first { $0.id == id }
    }

    /// Commerce credentials for a specific sponsor id from the most recent subscribe response.
    ///
    /// Resolution order (no fallback to a hardcoded key per the v2 rule "no fallbacks to v1,
    /// no hardcoded apiKeys"):
    ///   1. Sponsor whose id matches — primary or any secondary — returns its `commerce` block.
    ///   2. When `id` is `nil`, returns the primary sponsor's `commerce` block.
    ///   3. Otherwise `nil` — caller must degrade gracefully (no commerce → no checkout).
    public func commerce(forSponsorId id: Int?) -> VioTVSponsor.CommerceBlock? {
        if let id, let block = sponsor(withId: id)?.commerce {
            return block
        }
        return primarySponsor?.commerce
    }

    public func configure(
        apiKey: String,
        userId: String = "",
        environment: VioTVEnvironment = .development
    ) {
        self.apiKey = apiKey
        self.userId = userId
        self.environment = environment
        print("[VioTV] Configured — env: \(environment.rawValue), backend: \(backendURL)")
    }

    public func applyFileConfiguration(_ fileConfig: VioTVFileConfiguration, userIdOverride: String? = nil) {
        let env = VioTVEnvironment(rawValue: (fileConfig.environment ?? "development").lowercased()) ?? .development
        configure(
            apiKey: fileConfig.apiKey,
            userId: userIdOverride ?? "",
            environment: env
        )
    }

    /// Populate ``primarySponsor`` / ``secondarySponsors`` / ``currentSessionId``
    /// / ``currentEndUserId`` / ``currentCampaignId`` from the response of
    /// `POST /v2/tv/broadcast/subscribe`.
    public func applySubscribeResponse(_ response: VioTVSubscribeResponse) {
        self.primarySponsor = response.primarySponsor
        self.secondarySponsors = response.secondarySponsors ?? []
        self.currentSessionId = response.sessionId
        self.currentEndUserId = response.endUserId
        self.currentCampaignId = response.campaignId
    }

    /// Clear backend-driven state on disconnect.
    public func clearSubscribeState() {
        self.primarySponsor = nil
        self.secondarySponsors = []
        self.currentSessionId = nil
        self.currentEndUserId = nil
        self.currentCampaignId = nil
    }
}
