import SwiftUI

struct ContentView: View {
    @State private var loaded = false

    var body: some View {
        Group {
            if loaded {
                TVPlayerView()
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
