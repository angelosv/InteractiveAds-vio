import Foundation

// MARK: - ShoppableAdEvent (from WebSocket payload)

public struct ShoppableAdEvent: Codable {
    public let type: String
    public let broadcastId: String?
    public let product: ShoppableProduct
    public let sponsor: ShoppableSponsor?
    public let timestamp: Double?
    public let discountBadge: String?
    public let campaignId: Int?

    public init(type: String, broadcastId: String? = nil, product: ShoppableProduct, sponsor: ShoppableSponsor? = nil, timestamp: Double? = nil, discountBadge: String? = nil, campaignId: Int? = nil) {
        self.type = type
        self.broadcastId = broadcastId
        self.product = product
        self.sponsor = sponsor
        self.timestamp = timestamp
        self.discountBadge = discountBadge
        self.campaignId = campaignId
    }
}

public struct ShoppableProduct: Codable {
    public let id: String
    public let title: String
    public let images: [ProductImage]
    public let price: ProductPrice

    public init(id: String, title: String, images: [ProductImage], price: ProductPrice) {
        self.id = id
        self.title = title
        self.images = images
        self.price = price
    }

    public var primaryImageUrl: String? {
        images.sorted { $0.order < $1.order }.first?.url
    }

    public var formattedPrice: String {
        let amount = price.amountInclTaxes > 0 ? price.amountInclTaxes : price.amount
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        return "kr \(formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"),-"
    }
}

public struct ShoppableSponsor: Codable {
    public let name: String
    public let logoUrl: String?
    public let primaryColor: String?

    public init(name: String, logoUrl: String? = nil, primaryColor: String? = nil) {
        self.name = name
        self.logoUrl = logoUrl
        self.primaryColor = primaryColor
    }
}

public struct ProductImage: Codable {
    public let url: String
    public let order: Int

    public init(url: String, order: Int) {
        self.url = url
        self.order = order
    }
}

public struct ProductPrice: Codable {
    public let amount: Double
    public let amountInclTaxes: Double
    public let currencyCode: String

    public init(amount: Double, amountInclTaxes: Double, currencyCode: String) {
        self.amount = amount
        self.amountInclTaxes = amountInclTaxes
        self.currencyCode = currencyCode
    }

    enum CodingKeys: String, CodingKey {
        case amount
        case amountInclTaxes = "amount_incl_taxes"
        case currencyCode = "currency_code"
    }
}
