import XCTest
@testable import VioTVCore

final class VioTVCoreTests: XCTestCase {
    func testShoppableProductDecodesFlatPayloadWithIntId() throws {
        let json = """
        {
          "id": 408895,
          "name": "Samsung 85 Neo QLED 4K TV",
          "price": 17990,
          "currency": "NOK",
          "imageUrl": "https://example.com/tv.jpg"
        }
        """

        let decoded = try JSONDecoder().decode(ShoppableProduct.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.id, "408895")
        XCTAssertEqual(decoded.title, "Samsung 85 Neo QLED 4K TV")
        XCTAssertEqual(decoded.images.first?.url, "https://example.com/tv.jpg")
        XCTAssertEqual(decoded.price.currencyCode, "NOK")
        XCTAssertEqual(decoded.price.amount, 17990)
    }

    func testBackendProductEventCarriesCampaignIdToShoppableEvent() throws {
        let json = """
        {
          "type": "product",
          "campaignId": 36,
          "data": {
            "id": "evt_1",
            "productId": "408895",
            "name": "Samsung 85 Neo QLED 4K TV",
            "price": "17990",
            "currency": "NOK",
            "imageUrl": "https://example.com/tv.jpg"
          }
        }
        """

        let backendEvent = try JSONDecoder().decode(BackendProductEvent.self, from: Data(json.utf8))
        let mapped = backendEvent.toShoppableAdEvent()

        XCTAssertEqual(mapped.type, "shoppable_ad")
        XCTAssertEqual(mapped.campaignId, 36)
        XCTAssertEqual(mapped.product.id, "408895")
    }

    func testConfigurationStoresDefaultCampaignId() {
        VioTVConfiguration.shared.configure(
            apiKey: "api_key",
            commerceApiKey: "commerce_key",
            userId: "user_1",
            environment: .production,
            defaultCampaignId: 99
        )

        XCTAssertEqual(VioTVConfiguration.shared.defaultCampaignId, 99)
        XCTAssertEqual(VioTVConfiguration.shared.environment, .production)
        XCTAssertEqual(VioTVConfiguration.shared.webSocketBaseURL, "wss://api.vio.live/ws")
    }
}
