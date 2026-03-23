import Foundation

enum VideoConfig {
    /// Returns the URL for the demo video from the app bundle.
    static func getVideoURL() -> URL? {
        Bundle.main.url(forResource: "demo-video.f137", withExtension: "mp4")
    }
}
