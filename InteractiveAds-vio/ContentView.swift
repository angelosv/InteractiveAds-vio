import SwiftUI

struct ContentView: View {
    @State private var loaded = false

    var body: some View {
        Group {
            if loaded {
                let data = VioTVConfigLoader.shared.staticData!
                TVPlayerView(
                    match: data.match,
                    sponsor: data.sponsor,
                    products: data.demoProducts
                )
            } else {
                ProgressView("Cargando Vio TV...")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            VioTVConfigLoader.shared.load()
            loaded = true
        }
    }
}
