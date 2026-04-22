import Foundation

/// Sponsor descriptor returned by `POST /api/sdk/tv/broadcast/subscribe` and
/// cached in ``VioTVConfiguration``.
///
/// A sponsor with `commerce == nil` is **visual-only** — the SDK will render its
/// branding if any shoppable event carries `sponsorId` pointing at it, but no
/// purchase flow will be initiated for that sponsor.
public struct VioTVSponsor: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let logoUrl: String?
    public let primaryColor: String?
    public let secondaryColor: String?
    public let commerce: CommerceBlock?

    public struct CommerceBlock: Codable, Equatable, Sendable {
        public let apiKey: String
        public let channelId: String?
        public let paymentMethods: [String]

        public init(apiKey: String, channelId: String? = nil, paymentMethods: [String] = []) {
            self.apiKey = apiKey
            self.channelId = channelId
            self.paymentMethods = paymentMethods
        }
    }

    public init(
        id: Int,
        name: String,
        logoUrl: String? = nil,
        primaryColor: String? = nil,
        secondaryColor: String? = nil,
        commerce: CommerceBlock? = nil
    ) {
        self.id = id
        self.name = name
        self.logoUrl = logoUrl
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.commerce = commerce
    }
}

// MARK: - Subscribe endpoint response

/// Shape of `POST /api/sdk/tv/broadcast/subscribe` response.
/// Either `subscribed: true` with the full payload, or `subscribed: false` with a reason.
public struct VioTVSubscribeResponse: Codable, Equatable, Sendable {
    public let subscribed: Bool
    public let reason: String?

    public let campaignId: Int?
    public let broadcastId: String?
    public let sessionId: Int?
    public let endUserId: Int?
    public let wsUrl: String?
    public let primarySponsor: VioTVSponsor?
    public let secondarySponsors: [VioTVSponsor]?
    public let capabilities: Capabilities?

    public struct Capabilities: Codable, Equatable, Sendable {
        public let shoppable: Bool?
        public let engagement: Bool?
    }
}

/// Soft-miss reasons returned by the backend when `subscribed == false`.
public enum VioTVSubscribeFailureReason: String, Codable, Sendable {
    case broadcastNotRegistered = "broadcast_not_registered_for_client_app"
    case campaignHasNoPrimarySponsor = "campaign_has_no_primary_sponsor"
    case tvNotEnabledForPlatform = "tv_not_enabled_for_this_platform"
    case unknown

    public init(rawValue: String) {
        switch rawValue {
        case Self.broadcastNotRegistered.rawValue: self = .broadcastNotRegistered
        case Self.campaignHasNoPrimarySponsor.rawValue: self = .campaignHasNoPrimarySponsor
        case Self.tvNotEnabledForPlatform.rawValue: self = .tvNotEnabledForPlatform
        default: self = .unknown
        }
    }
}
