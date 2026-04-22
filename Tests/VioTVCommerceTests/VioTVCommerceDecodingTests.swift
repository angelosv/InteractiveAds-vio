import XCTest
@testable import VioTVCommerce

final class VioTVCommerceDecodingTests: XCTestCase {
    func testCommerceGraphQLResponseDecodesChannelProductsByIds() throws {
        let json = """
        {
          "data": {
            "Channel": {
              "GetProductsByIds": [
                {
                  "id": 408895,
                  "title": "Samsung 85 Neo QLED 4K TV",
                  "images": [{ "url": "https://example.com/tv.jpg", "order": 0 }],
                  "price": {
                    "amount": 17990,
                    "amount_incl_taxes": 17990,
                    "currency_code": "NOK"
                  }
                }
              ]
            }
          }
        }
        """

        let decoded = try JSONDecoder().decode(CommerceGraphQLResponse.self, from: Data(json.utf8))
        let first = decoded.data?.channel?.getProductsByIds?.first

        XCTAssertEqual(first?.id, 408895)
        XCTAssertEqual(first?.title, "Samsung 85 Neo QLED 4K TV")
        XCTAssertEqual(first?.price?.currency_code, "NOK")
        XCTAssertEqual(first?.images?.first?.order, 0)
    }
}
