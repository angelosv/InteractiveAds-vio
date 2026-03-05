import Foundation

class VioCommerceService {
    static let shared = VioCommerceService()

    private let graphQLUrl = "https://graph-ql-dev.vio.live/graphql"
    private let apiKey = "KCXF10Y-W5T4PCR-GG5119A-Z64SQ9S"

    func fetchProduct(id: String) async -> CommerceProduct? {
        let query = """
        {
          Channel {
            GetProductsByIds(product_ids: [\(id)]) {
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

        guard let url = URL(string: graphQLUrl) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": query])

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONDecoder().decode(CommerceGraphQLResponse.self, from: data) else {
            print("❌ [Commerce] Failed to fetch product \(id)")
            return nil
        }
        return json.data?.channel?.getProductsByIds?.first
    }
}

// MARK: - Commerce Models
struct CommerceGraphQLResponse: Codable {
    let data: CommerceData?
}

struct CommerceData: Codable {
    let channel: CommerceChannelData?
    enum CodingKeys: String, CodingKey { case channel = "Channel" }
}

struct CommerceChannelData: Codable {
    let getProductById: CommerceProduct?
    enum CodingKeys: String, CodingKey { case getProductById = "GetProductById" }
}

struct CommerceProduct: Codable {
    let id: String
    let title: String
    var name: String { title }
    let images: [CommerceImage]?
    let price: CommercePrice?

    var primaryImageUrl: String? { images?.sorted { ($0.order ?? 99) < ($1.order ?? 99) }.first?.url }

    var formattedPrice: String {
        let amount = price?.amount_incl_taxes ?? price?.amount ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        return "kr \(formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"),-"
    }
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
