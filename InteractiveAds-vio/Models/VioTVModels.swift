import Foundation

struct VioTVConfig: Codable {
    let apiKey: String
    let campaignId: Int
    let backendUrl: String
    let webSocketUrl: String
    let contentId: String
    let country: String
}

struct DemoStaticData: Codable {
    let sponsor: TVSponsor
    let match: TVMatch
    let demoProducts: [TVProduct]
}

struct TVSponsor: Codable {
    let name: String
    let logoUrl: String
    let primaryColor: String
}

struct TVMatch: Codable {
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int
    let awayScore: Int
    let minute: Int
    let period: String
}

struct TVProduct: Codable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        let num = formatter.string(from: NSNumber(value: price)) ?? "\(Int(price))"
        return "kr \(num),-"
    }
}

struct ShoppableAdEvent: Codable {
    let type: String
    let product: TVProduct?
    let sponsor: TVSponsor?
}
