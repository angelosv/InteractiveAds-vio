import Foundation
import VioTVCore

public final class VioTVCommerceService {
    public static let shared = VioTVCommerceService()

    private init() {}

    /// Fetches a product from Commerce GraphQL using the provided `commerceApiKey`.
    ///
    /// Pass the key of the sponsor that emitted the shoppable_ad — resolve with
    /// `VioTVConfiguration.shared.commerce(forSponsorId:)` using the `sponsorId`
    /// on the WS event. If `commerceApiKey` is `nil` the method falls back to the
    /// dev-only local key (`VioTVConfiguration.shared.commerceApiKey`) for
    /// backwards compatibility; in production this path should never hit.
    public func fetchProduct(id: String, commerceApiKey: String? = nil) async -> ShoppableProduct? {
        let config = VioTVConfiguration.shared
        guard let url = URL(string: config.commerceURL) else {
            print("[VioTV] Invalid commerce URL")
            return nil
        }

        let resolvedKey = commerceApiKey ?? config.commerceApiKey
        guard !resolvedKey.isEmpty else {
            print("[VioTV] Commerce fetchProduct skipped — no commerceApiKey (sponsor is visual-only or SDK not subscribed yet)")
            return nil
        }

        let query = """
        query GetProductsByIds($productIds: [Int!]!) {
          Channel {
            GetProductsByIds(product_ids: $productIds) {
              id
              title
              images { url order }
              price {
                amount
                amount_incl_taxes
                currency_code
              }
            }
          }
        }
        """

        let intId = Int(id) ?? -1
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(resolvedKey, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "query": query,
            "variables": ["productIds": [intId]]
        ])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200...299).contains(status) else {
                print("[VioTV] Commerce HTTP error \(status)")
                return nil
            }

            let json = try JSONDecoder().decode(CommerceGraphQLResponse.self, from: data)
            guard let commerceProduct = json.data?.channel?.getProductsByIds?.first else {
                print("[VioTV] Product \(id) not found in commerce response")
                return nil
            }

            let images = (commerceProduct.images ?? []).map {
                ProductImage(url: $0.url, order: $0.order ?? 0)
            }
            let price = ProductPrice(
                amount: commerceProduct.price?.amount ?? 0,
                amountInclTaxes: commerceProduct.price?.amount_incl_taxes ?? 0,
                currencyCode: commerceProduct.price?.currency_code ?? "NOK"
            )
            return ShoppableProduct(
                id: String(commerceProduct.id),
                title: commerceProduct.title,
                images: images,
                price: price
            )
        } catch {
            print("[VioTV] Failed to fetch product \(id): \(error)")
            return nil
        }
    }
}

struct CommerceGraphQLResponse: Codable {
    let data: CommerceData?
}

struct CommerceData: Codable {
    let channel: CommerceChannelData?
    enum CodingKeys: String, CodingKey { case channel = "Channel" }
}

struct CommerceChannelData: Codable {
    let getProductsByIds: [CommerceProduct]?
    enum CodingKeys: String, CodingKey {
        case getProductsByIds = "GetProductsByIds"
    }
}

struct CommerceProduct: Codable {
    let id: Int
    let title: String
    let images: [CommerceImage]?
    let price: CommercePrice?
}

struct CommerceImage: Codable {
    let url: String
    let order: Int?
}

struct CommercePrice: Codable {
    let amount: Double
    let amount_incl_taxes: Double?
    let currency_code: String
}
