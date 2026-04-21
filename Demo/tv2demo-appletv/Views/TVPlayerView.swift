import SwiftUI
import VioTV

struct TVPlayerView: View {
    @StateObject private var videoViewModel = VideoPlayerViewModel()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Video Background
            if let videoURL = VideoConfig.getVideoURL() {
                VideoPlayerView(videoURL: videoURL, viewModel: videoViewModel)
                    .ignoresSafeArea()

                // Dark overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                // Video controls overlay
                VideoControlsOverlay(viewModel: videoViewModel)
                    .ignoresSafeArea(edges: .bottom)

                // SDK Shoppable overlay — fully auto-managed
                VioTVShoppableOverlay()
            } else {
                // Fallback gradient
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            VioTV.connect()
        }
        .onDisappear {
            VioTV.disconnect()
        }
    }
}
