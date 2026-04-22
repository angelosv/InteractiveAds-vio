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
            environment: .testing,
            defaultCampaignId: 99
        )

        XCTAssertEqual(VioTVConfiguration.shared.defaultCampaignId, 99)
        XCTAssertEqual(VioTVConfiguration.shared.environment, .testing)
        XCTAssertEqual(VioTVConfiguration.shared.webSocketBaseURL, "wss://api-dev.vio.live/ws")
    }

    func testApplyFileConfigurationUsesDevelopmentOverrides() {
        let fileConfig = VioTVFileConfiguration(
            apiKey: "api_key",
            commerceApiKey: "commerce_key",
            campaignId: 36,
            userId: "bundle_user",
            environment: "development",
            backendURL: "https://api-test.vio.live",
            webSocketBaseURL: "wss://api-test.vio.live/ws",
            commerceURL: "https://graph-ql-test.vio.live/graphql",
            devBackendURL: "http://localhost:4000",
            devWebSocketBaseURL: "ws://localhost:4000/ws",
            devCommerceURL: "http://localhost:4000/graphql"
        )

        VioTVConfiguration.shared.applyFileConfiguration(fileConfig)

        XCTAssertEqual(VioTVConfiguration.shared.backendURL, "http://localhost:4000")
        XCTAssertEqual(VioTVConfiguration.shared.webSocketBaseURL, "ws://localhost:4000/ws")
        XCTAssertEqual(VioTVConfiguration.shared.commerceURL, "http://localhost:4000/graphql")
        XCTAssertEqual(VioTVConfiguration.shared.defaultCampaignId, 36)
    }

    func testSanitizeRemovesTrailingSlashFromOverrides() {
        VioTVConfiguration.shared.configure(
            apiKey: "api_key",
            commerceApiKey: "commerce_key",
            environment: .development,
            backendURLOverride: "https://api-local-angelo.vio.live/",
            webSocketBaseURLOverride: "wss://api-local-angelo.vio.live/ws/",
            commerceURLOverride: "https://api-local-angelo.vio.live/graphql/"
        )

        XCTAssertEqual(VioTVConfiguration.shared.backendURL, "https://api-local-angelo.vio.live")
        XCTAssertEqual(VioTVConfiguration.shared.webSocketBaseURL, "wss://api-local-angelo.vio.live/ws")
        XCTAssertEqual(VioTVConfiguration.shared.commerceURL, "https://api-local-angelo.vio.live/graphql")
    }

    func testFileConfigurationDecodesSdkStyleKeyNames() throws {
        let json = """
        {
          "apiKey": "tv_api_key",
          "commerceApiKey": "commerce_key",
          "campaignId": 42,
          "environment": "testing",
          "backendUrl": "https://api-test.vio.live",
          "webSocketUrl": "wss://api-test.vio.live/ws",
          "commerceUrl": "https://graph-ql-test.vio.live/graphql"
        }
        """
        let decoded = try JSONDecoder().decode(VioTVFileConfiguration.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.backendURL, "https://api-test.vio.live")
        XCTAssertEqual(decoded.webSocketBaseURL, "wss://api-test.vio.live/ws")
        XCTAssertEqual(decoded.commerceURL, "https://graph-ql-test.vio.live/graphql")
    }
}
