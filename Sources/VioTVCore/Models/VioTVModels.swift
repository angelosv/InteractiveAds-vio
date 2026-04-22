import Foundation

public struct ShoppableAdEvent: Codable {
    public let type: String
    public let broadcastId: String?
    public let product: ShoppableProduct
    public let sponsor: ShoppableSponsor?
    public let timestamp: Double?
    public let discountBadge: String?
    public let campaignId: Int?
    /// Backend-issued id of the row in `shoppable_ad_activations`. The TV SDK echoes this
    /// back in `sendCartIntent` as `activationId` so the backend can stamp
    /// `cart_intents.source_activation_id` and close the attribution chain.
    public let activationId: Int?
    /// Which sponsor of the campaign owns this dispatch. Used by the SDK to resolve
    /// the right `commerceApiKey` from `VioTVConfiguration.commerce(forSponsorId:)`.
    public let sponsorId: Int?

    public init(
        type: String,
        broadcastId: String? = nil,
        product: ShoppableProduct,
        sponsor: ShoppableSponsor? = nil,
        timestamp: Double? = nil,
        discountBadge: String? = nil,
        campaignId: Int? = nil,
        activationId: Int? = nil,
        sponsorId: Int? = nil
    ) {
        self.type = type
        self.broadcastId = broadcastId
        self.product = product
        self.sponsor = sponsor
        self.timestamp = timestamp
        self.discountBadge = discountBadge
        self.campaignId = campaignId
        self.activationId = activationId
        self.sponsorId = sponsorId
    }

    public func withProduct(_ product: ShoppableProduct) -> ShoppableAdEvent {
        ShoppableAdEvent(
            type: type,
            broadcastId: broadcastId,
            product: product,
            sponsor: sponsor,
            timestamp: timestamp,
            discountBadge: discountBadge,
            campaignId: campaignId,
            activationId: activationId,
            sponsorId: sponsorId
        )
    }
}

public struct ShoppableProduct: Codable {
    public let id: String
    public let title: String
    public let images: [ProductImage]
    public let price: ProductPrice

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let strId = try? c.decode(String.self, forKey: .id) {
            id = strId
        } else {
            id = String(try c.decode(Int.self, forKey: .id))
        }
        if let t = try? c.decode(String.self, forKey: .title) {
            title = t
        } else {
            title = (try? c.decode(String.self, forKey: .name)) ?? ""
        }
        if let imgs = try? c.decode([ProductImage].self, forKey: .images) {
            images = imgs
        } else if let url = try? c.decode(String.self, forKey: .imageUrl) {
            images = [ProductImage(url: url, order: 0)]
        } else {
            images = []
        }
        if let p = try? c.decode(ProductPrice.self, forKey: .price) {
            price = p
        } else {
            let amount = (try? c.decode(Double.self, forKey: .price)) ?? 0
            let currency = (try? c.decode(String.self, forKey: .currency)) ?? "NOK"
            price = ProductPrice(amount: amount, amountInclTaxes: amount, currencyCode: currency)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(images, forKey: .images)
        try c.encode(price, forKey: .price)
    }

    public init(id: String, title: String, images: [ProductImage], price: ProductPrice) {
        self.id = id
        self.title = title
        self.images = images
        self.price = price
    }

    enum CodingKeys: String, CodingKey {
        case id, title, name, images, price, imageUrl, currency
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
    public let id: Int?
    public let name: String
    /// Square brand mark — what the overlay / product card renders. Always set when
    /// the backend dispatches a shoppable_ad (the helper rejects sponsors with no avatar).
    public let avatarUrl: String?
    /// Wide horizontal brand logo — used for sponsor intros or full-screen surfaces.
    /// May be nil; do not use as a substitute for ``avatarUrl`` in product cards.
    public let logoUrl: String?
    public let primaryColor: String?

    public init(
        id: Int? = nil,
        name: String,
        avatarUrl: String? = nil,
        logoUrl: String? = nil,
        primaryColor: String? = nil
    ) {
        self.id = id
        self.name = name
        self.avatarUrl = avatarUrl
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

struct BackendProductEvent: Codable {
    let type: String
    let campaignId: Int?
    let data: BackendProductData
    let campaignLogo: String?
    let timestamp: Int64?

    struct BackendProductData: Codable {
        let id: String
        let productId: String?
        let name: String
        let description: String?
        let price: String
        let currency: String?
        let imageUrl: String?
        let campaignLogo: String?
    }

    func toShoppableAdEvent() -> ShoppableAdEvent {
        let priceAmount = Double(data.price) ?? 0
        let currency = data.currency ?? "NOK"
        let imageUrl = data.imageUrl ?? ""

        let product = ShoppableProduct(
            id: data.productId ?? data.id,
            title: data.name,
            images: imageUrl.isEmpty ? [] : [ProductImage(url: imageUrl, order: 0)],
            price: ProductPrice(amount: priceAmount, amountInclTaxes: priceAmount, currencyCode: currency)
        )

        let logoUrl = data.campaignLogo ?? campaignLogo
        let sponsor = logoUrl.map { ShoppableSponsor(name: "", logoUrl: $0) }

        return ShoppableAdEvent(
            type: "shoppable_ad",
            product: product,
            sponsor: sponsor,
            campaignId: campaignId
        )
    }
}
