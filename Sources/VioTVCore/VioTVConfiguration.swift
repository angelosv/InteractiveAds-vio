import Foundation

public enum VioTVEnvironment: String, Codable {
    case development
    case production

    public var backendURL: String {
        switch self {
        case .development: return "https://api-dev.vio.live"
        case .production: return "https://api.vio.live"
        }
    }

    public var commerceURL: String {
        switch self {
        case .development: return "https://graph-ql-dev.vio.live/graphql"
        case .production: return "https://graph-ql.vio.live/graphql"
        }
    }

    public var webSocketBaseURL: String {
        switch self {
        case .development: return "wss://api-dev.vio.live/ws"
        case .production: return "wss://api.vio.live/ws"
        }
    }
}

public struct VioTVFileConfiguration: Codable {
    public let apiKey: String
    public let commerceApiKey: String
    public let campaignId: Int?
    public let userId: String?
    public let environment: String?

    public init(
        apiKey: String,
        commerceApiKey: String,
        campaignId: Int? = nil,
        userId: String? = nil,
        environment: String? = nil
    ) {
        self.apiKey = apiKey
        self.commerceApiKey = commerceApiKey
        self.campaignId = campaignId
        self.userId = userId
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
        return ["vio-config", "vio-config-automatic", "vio-config-example"]
    }
}

public final class VioTVConfiguration {
    public static let shared = VioTVConfiguration()

    public private(set) var apiKey: String = ""
    public private(set) var commerceApiKey: String = ""
    public private(set) var userId: String = ""
    public private(set) var defaultCampaignId: Int?
    public private(set) var environment: VioTVEnvironment = .development

    private init() {}

    public var commerceURL: String { environment.commerceURL }
    public var webSocketBaseURL: String { environment.webSocketBaseURL }

    public func configure(
        apiKey: String,
        commerceApiKey: String,
        userId: String = "",
        environment: VioTVEnvironment = .development,
        defaultCampaignId: Int? = nil
    ) {
        self.apiKey = apiKey
        self.commerceApiKey = commerceApiKey
        self.userId = userId
        self.environment = environment
        self.defaultCampaignId = defaultCampaignId
        print("[VioTV] Configured - env: \(environment.rawValue), campaign: \(defaultCampaignId.map(String.init) ?? "(none)")")
    }
}
