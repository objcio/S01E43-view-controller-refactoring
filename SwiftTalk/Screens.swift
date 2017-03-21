import AVFoundation
import AVKit
import UIKit

public final class Screens {
    fileprivate let webservice: CachedWebservice

    // TODO: Do we need this on tvOS?
    // Should the app work without authentication at all?
    /// Executed when webservice authentication fails
    public var authenticationFailure: (() -> ())?

    public init(webservice: Webservice) {
        self.webservice = CachedWebservice(webservice: webservice)
    }

    public func root() -> UITabBarController {
        return UITabBarController()
    }

    public func videosTab(title: String = "Episodes") -> UINavigationController {
        let navVC = UINavigationController()
        navVC.title = title
        return navVC
    }

    public func allEpisodes(
        title: String = "Episodes",
        didSelect: @escaping (Episode) -> ()
    ) -> UIViewController {
        let season = TableViewController(title: title, items: [], estimatedRowHeight: 140,
            loadData: { [weak self] loadType, completion in
                self?.load(Episode.all, skipCache: loadType == .forceReload, completion: completion)
            }, configureCell: { [weak self] (cell: EpisodeCell, episode) in
                guard let `self` = self else { return }
                let viewModel = EpisodeViewModel(episode: episode, loggedIn: false, webservice: self.webservice)
                cell.configure(viewModel: viewModel)
            }
        )
        season.didSelect = didSelect
        return ReadableContentViewController(season)
    }

    public func episode(_ episode: Episode, didTapPlay: @escaping (Episode) -> ()) -> UIViewController {
        // TODO: implement loggedIn state
        return EpisodeDetailViewController(viewModel: EpisodeViewModel(episode: episode, loggedIn: false, webservice: webservice), didTapPlay: didTapPlay)
    }

    public func video(_ episode: Episode) -> VideoPlayerViewController {
        let vc = VideoPlayerViewController(episode: episode)
        webservice.load(episode.thumbnail, skipCache: false) { [weak vc] result in
            vc?.thumbnail = result.value
        }
        return vc
    }

}

public extension UIViewController {
    func presentAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let closeButton = UIAlertAction(title: "Close", style: .default, handler: nil)
            alert.addAction(closeButton)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

fileprivate extension Screens {
    func load<A>(_ resource: Resource<A>, skipCache: Bool = false, completion: @escaping (A?) -> ()) {
        webservice.load(resource, skipCache: skipCache) { [weak self] result in
            if case .error(WebServiceError.notAuthenticated) = result {
                self?.authenticationFailure?()
            }
            completion(result.value)
        }
    }
}
