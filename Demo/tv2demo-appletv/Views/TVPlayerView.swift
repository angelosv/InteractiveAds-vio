import SwiftUI
import VioTV

struct TVPlayerView: View {
    /// Partner-internal broadcast id passed to the SDK. When the backend doesn't
    /// recognise it, `onSubscriptionFailed` fires with a `broadcast_not_registered_for_client_app`
    /// reason and the SDK stays idle — used by the demo picker to exercise both paths.
    let broadcastId: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var videoViewModel = VideoPlayerViewModel()

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let videoURL = VideoConfig.getVideoURL() {
                VideoPlayerView(videoURL: videoURL, viewModel: videoViewModel)
                    .ignoresSafeArea()

                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VideoControlsOverlay(viewModel: videoViewModel)
                    .ignoresSafeArea(edges: .bottom)

                VioTVShoppableOverlay()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            Button {
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                    Text("Volver")
                }
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
            }
            .padding(40)
        }
        .onAppear {
            VioTV.connect(broadcastId: broadcastId)
        }
        .onDisappear {
            VioTV.disconnect()
        }
    }
}
