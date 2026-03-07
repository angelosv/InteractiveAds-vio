import SwiftUI
import VioTV

struct TVPlayerView: View {
    @StateObject private var videoViewModel = VideoPlayerViewModel()
    @StateObject private var vioManager = VioTVManager.shared

    /// Campaign ID from vio-config.json (loaded at app launch)
    private let campaignId: Int = {
        guard let url = Bundle.main.url(forResource: "vio-config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["campaignId"] as? Int else { return 36 }
        return id
    }()

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

                // SDK Shoppable overlay — driven by VioTVManager.activeAd
                if let event = vioManager.activeAd {
                    VioTVShoppableOverlay(
                        event: event,
                        dismissAfter: 15,
                        campaignId: campaignId,
                        onDismiss: {
                            vioManager.activeAd = nil
                        }
                    )
                }
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
            VioTV.connect(broadcastId: "\(campaignId)")
        }
        .onDisappear {
            VioTV.disconnect()
        }
        .animation(.easeInOut(duration: 0.4), value: vioManager.activeAd != nil)
    }
}
