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
    public let commerceApiKey: String
    public let campaignId: Int?
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
        commerceApiKey: String,
        campaignId: Int? = nil,
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
        case apiKey, commerceApiKey, campaignId, userId, environment
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
    public private(set) var commerceApiKey: String = ""
    public private(set) var userId: String = ""
    public private(set) var defaultCampaignId: Int?
    public private(set) var environment: VioTVEnvironment = .development
    public private(set) var backendURLOverride: String?
    public private(set) var webSocketBaseURLOverride: String?
    public private(set) var commerceURLOverride: String?

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

    public func configure(
        apiKey: String,
        commerceApiKey: String,
        userId: String = "",
        environment: VioTVEnvironment = .development,
        defaultCampaignId: Int? = nil,
        backendURLOverride: String? = nil,
        webSocketBaseURLOverride: String? = nil,
        commerceURLOverride: String? = nil
    ) {
        self.apiKey = apiKey
        self.commerceApiKey = commerceApiKey
        self.userId = userId
        self.environment = environment
        self.defaultCampaignId = defaultCampaignId
        self.backendURLOverride = sanitize(url: backendURLOverride)
        self.webSocketBaseURLOverride = sanitize(url: webSocketBaseURLOverride)
        self.commerceURLOverride = sanitize(url: commerceURLOverride)
        print("[VioTV] Configured - env: \(environment.rawValue), campaign: \(defaultCampaignId.map(String.init) ?? "(none)"), ws: \(webSocketBaseURL)")
    }

    public func applyFileConfiguration(_ fileConfig: VioTVFileConfiguration, userIdOverride: String? = nil) {
        let env = VioTVEnvironment(rawValue: (fileConfig.environment ?? "development").lowercased()) ?? .development
        let backendOverride = resolvedBackendURL(fileConfig: fileConfig, environment: env)
        let wsOverride = resolvedWebSocketURL(fileConfig: fileConfig, environment: env)
        let commerceOverride = resolvedCommerceURL(fileConfig: fileConfig, environment: env)

        configure(
            apiKey: fileConfig.apiKey,
            commerceApiKey: fileConfig.commerceApiKey,
            userId: userIdOverride ?? fileConfig.userId ?? "",
            environment: env,
            defaultCampaignId: fileConfig.campaignId,
            backendURLOverride: backendOverride,
            webSocketBaseURLOverride: wsOverride,
            commerceURLOverride: commerceOverride
        )
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
