import AVFoundation
import AVKit
import UIKit

public extension AVPlayerItem {
    static let didPlayToEndTime = NotificationDescriptor<()>(name: .AVPlayerItemDidPlayToEndTime) { _ in () }
}

public final class VideoPlayerViewController: UIViewController {
    let episode: Episode
    let playerViewController = AVPlayerViewController()
    public var thumbnail: UIImage? {
        didSet {
            guard let playerItem = playerViewController.player?.currentItem else { return }
            let artwork = AVMetadataItem.item(identifier: AVMetadataCommonIdentifierArtwork, image: thumbnail)
            playerItem.externalMetadata = playerItem.externalMetadata + [artwork]
        }
    }
    public var didPlayToEnd: (() -> ())?
    private var didPlayToEndTimeToken: NotificationToken?

    public init(episode: Episode) {
        self.episode = episode
        super.init(nibName: nil, bundle: nil)

        let playerItem = AVPlayerItem(url: episode.mediaURL)
        // Metadata to be displayed in the Info panel on swipe down.
        playerItem.externalMetadata = [
            AVMetadataItem.item(identifier: AVMetadataCommonIdentifierTitle, value: episode.title),
            AVMetadataItem.item(identifier: AVMetadataCommonIdentifierDescription, value: episode.synopsis)
        ]

        let player = AVPlayer(playerItem: playerItem)
        playerViewController.player = player
        // Disable the Subtitles menu. As I understand the documentation, setting this to an empty array should work, but AVPlayerViewController seems to treat [] like nil. By setting it to "en", we effectively disable the subtitles selection as long as the media files don't contain an English subtitle track (and when they do in the future, it would be available for selection).
        playerViewController.allowedSubtitleOptionLanguages = ["en"]
    }

    required public init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()

        addChildViewController(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.didMove(toParentViewController: self)

        playerViewController.view.topAnchor.constrainEqual(view.topAnchor)
        playerViewController.view.leadingAnchor.constrainEqual(view.leadingAnchor)
        playerViewController.view.trailingAnchor.constrainEqual(view.trailingAnchor)
        playerViewController.view.bottomAnchor.constrainEqual(view.bottomAnchor)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let playerItem = playerViewController.player?.currentItem {
            didPlayToEndTimeToken = NotificationCenter.default.addObserver(descriptor: AVPlayerItem.didPlayToEndTime, object: playerItem) { [unowned self] _ in
                self.didPlayToEnd?()
            }
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didPlayToEndTimeToken = nil
    }

    public func play() {
        playerViewController.player?.play()
    }
}
