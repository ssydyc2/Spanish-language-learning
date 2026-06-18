import AVFAudio
import Foundation

final class AudioPlayer {
    private var player: AVAudioPlayer?
    private var hasConfiguredSession = false

    func play(path: String?) {
        guard let path else {
            return
        }

        let url = Bundle.main.url(forResource: path, withExtension: nil)
            ?? fallbackURL(for: path)

        guard let url else {
            return
        }

        do {
            configureSessionIfNeeded()
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            player = nil
        }
    }

    private func configureSessionIfNeeded() {
        guard !hasConfiguredSession else {
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            hasConfiguredSession = true
        } catch {
            hasConfiguredSession = false
        }
    }

    private func fallbackURL(for path: String) -> URL? {
        let nsPath = path as NSString
        let file = nsPath.deletingPathExtension
        let ext = nsPath.pathExtension
        let subdirectory = nsPath.deletingLastPathComponent

        return Bundle.main.url(
            forResource: (file as NSString).lastPathComponent,
            withExtension: ext.isEmpty ? nil : ext,
            subdirectory: subdirectory.isEmpty ? nil : subdirectory
        )
    }
}
