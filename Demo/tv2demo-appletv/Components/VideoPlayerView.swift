import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL
    @ObservedObject var viewModel: VideoPlayerViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)

        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill

        viewModel.configure(with: player)

        // Auto-play and loop
        player.play()

        // Loop video — observer cuando el item termina
        context.coordinator.setupLoopObserver(player: player)

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }

    class Coordinator {
        private var loopObserver: NSObjectProtocol?

        func setupLoopObserver(player: AVPlayer) {
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }

        deinit {
            if let observer = loopObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

// Helper struct for video configuration
struct VideoConfig {
    // For demo purposes, you can:
    // 1. Add a local video file to the project bundle
    // 2. Use a direct video URL (HLS stream or MP4)
    // 3. Download the YouTube video and add it as a resource

    static func getVideoURL() -> URL? {
        // Try to find the bundled video file
        if let bundlePath = Bundle.main.path(forResource: "demo-video.f137", ofType: "mp4") {
            return URL(fileURLWithPath: bundlePath)
        }

        // Fallback: Try without the extension specification
        if let bundlePath = Bundle.main.path(forResource: "demo-video.f137.mp4", ofType: nil) {
            return URL(fileURLWithPath: bundlePath)
        }

        // Fallback: Apple's sample HLS stream for testing
        print("[VioTV] Warning: Could not find demo-video.f137.mp4 in bundle, using fallback stream")
        return URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")
    }
}
