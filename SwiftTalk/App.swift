import UIKit

public final class App {
    private let application: UIApplication
    private let screens: Screens
    private let rootScreen: UITabBarController
    private let login: Login
    private let webservice = Webservice()
    private let navigationDelegate = EpisodesNavigationDelegate()

    public init(application: UIApplication, window: UIWindow) {
        self.application = application
        screens = Screens(webservice: webservice)
        login = Login(webservice: webservice)
        rootScreen = UITabBarController()
        rootScreen.viewControllers = [videosTab(), login.screen]
        window.rootViewController = rootScreen
        window.makeKeyAndVisible()
        login.stateDidChange = { [unowned self] in self.loginStateDidChange(state: $0) }
        webservice.authenticationToken = login.authenticationToken
        // TODO: Do we need this on tvOS? Should it be handled inside LoginViewController?
//        screens.authenticationFailure = { [unowned self] in self.showLogin() }
    }

    private func loginStateDidChange(state: Login.State) {
        switch state {
        case .signedOut,
             .requestingAuthCode,
             .requestingAuthCodeFailed(_),
             .receivedAuthCode(_):
            webservice.authenticationToken = nil
        case .signedIn(let token):
            webservice.authenticationToken = token
        }
        // TODO: update/reload UI after auth state changed
    }

    private func videosTab() -> UIViewController {
        let navVC = screens.videosTab()
        let episodesScreen = screens.allEpisodes { [unowned self, unowned navVC] episode in
            let episodeVC = self.screens.episode(episode, didTapPlay: { [unowned self, unowned navVC] episode in
                let videoPlayer = self.screens.video(episode)
                videoPlayer.didPlayToEnd = { [unowned navVC] in navVC.popViewController(animated: true) }
                navVC.show(videoPlayer, sender: self)
                videoPlayer.play()
            })
            navVC.show(episodeVC, sender: self)
        }
        navVC.delegate = navigationDelegate
        navVC.viewControllers = [episodesScreen]
        return navVC
    }
}

final class EpisodesNavigationDelegate: NSObject, UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let isRootVC = navigationController.viewControllers.first == viewController
        navigationController.setNavigationBarHidden(!isRootVC, animated: animated)
    }
}
