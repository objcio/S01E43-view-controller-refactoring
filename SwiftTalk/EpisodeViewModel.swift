import Foundation
import UIKit

public struct EpisodeViewModel {
    public var episode: Episode
    public var loggedIn: Bool
    // TODO: Is it a good idea to inject the webservice into the view model?
    public let webservice: CachedWebservice

    public var synopsis: String { return episode.synopsis ?? "" }

    public var releaseDate: String {
        return releaseDateFormatter.string(from: episode.release ?? episode.lastUpdate)
    }

    public var duration: String {
        guard let duration = episode.duration else { return "" }
        return durationFormatter.string(from: duration)
    }

    public var subscriptionOnlyText: String {
        return episode.subscriptionOnly ? "Subscribers Only" : "Free"
    }

    public var playButtonTitle: String {
        if episode.subscriptionOnly {
            return loggedIn ? "Play" : "Preview"
        } else {
            return "Play"
        }
    }

    public var isLoginButtonVisible: Bool { return episode.subscriptionOnly && !loggedIn }

    public func loadThumbnail(_ done: @escaping (UIImage) -> ()) {
        DispatchQueue.main.async {
            self.webservice.load(self.episode.thumbnail, skipCache: false) { response in
                if let image = response.value {
                    done(image)
                }
            }
        }
    }

    private var releaseDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    /// - TODO: MeasurmentFormatter doesn't seem to support mixed-unit formats like "21 m 30 s"; it always displays "21.5 min", so we set the fraction digits to 0. This is fine for videos under 1 hour, but should we ever have videos longer than 1 hour, we'd probably have to roll a custom solution.
    private var durationFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.naturalScale]
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
}
