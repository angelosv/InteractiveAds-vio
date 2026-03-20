import Foundation

/// Environment for VioTV SDK backend connections.
public enum VioTVEnvironment {
    case development
    case production

    public var backendURL: String {
        switch self {
        case .development: return "https://api-dev.vio.live"
        case .production:  return "https://api.vio.live"
        }
    }
}

/// Singleton configuration for the VioTV SDK.
public final class VioTVConfiguration {
    public static let shared = VioTVConfiguration()

    public private(set) var apiKey: String = ""
    public private(set) var userId: String = ""
    public private(set) var environment: VioTVEnvironment = .development

    private init() {}

    public var commerceURL: String {
        switch environment {
        case .development: return "https://graph-ql-dev.vio.live/graphql"
        case .production:  return "https://graph-ql.vio.live/graphql"
        }
    }

    public var webSocketBaseURL: String {
        switch environment {
        case .development: return "wss://api-dev.vio.live/ws"
        case .production:  return "wss://api.vio.live/ws"
        }
    }

    func configure(apiKey: String, userId: String, environment: VioTVEnvironment) {
        self.apiKey = apiKey
        self.userId = userId
        self.environment = environment
        print("[VioTV] Configured — env: \(environment), userId: \(userId.isEmpty ? "(none)" : userId)")
    }
}
