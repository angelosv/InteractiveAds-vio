import Foundation

class VioTVConfigLoader {
    static let shared = VioTVConfigLoader()

    private(set) var config: VioTVConfig!
    private(set) var staticData: DemoStaticData!

    func load() {
        config = loadJSON("vio-config", as: VioTVConfig.self)
        staticData = loadJSON("demo-static-data", as: DemoStaticData.self)
    }

    private func loadJSON<T: Decodable>(_ name: String, as type: T.Type) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            fatalError("❌ [VioTV] Failed to load \(name).json")
        }
        return decoded
    }
}
