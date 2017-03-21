//
//  Model.swift
//  Videos
//
//  Created by Florian on 13/04/16.
//  Copyright © 2016 Chris Eidhof. All rights reserved.
//

import Foundation

public struct Episode {
    public var id: String
    public var title: String
    public var season: Int
    public var number: Int
    public var subscriptionOnly: Bool
    public var synopsis: String?
    public var text: String?
    // TODO naming?
    public var lastUpdate: Date
    public var release: Date?
    public var thumbnailURL: URL
    public var mediaURL: URL
    public var duration: Measurement<UnitDuration>?

    public init(id: String, title: String, season: Int, number: Int, subscriptionOnly: Bool, synopsis: String, text: String, lastUpdate: Date, release: Date? , thumbnailURL: URL, mediaURL: URL, duration: Measurement<UnitDuration>?) {
        self.id =  id
        self.title =  title
        self.season =  season
        self.number = number
        self.subscriptionOnly = subscriptionOnly
        self.synopsis = synopsis
        self.text = text
        self.lastUpdate = lastUpdate
        self.release = release
        self.thumbnailURL = thumbnailURL
        self.mediaURL = mediaURL
        self.duration = duration
    }
}

public typealias JSONDictionary = [String: Any]

extension Episode {
    public init?(json: JSONDictionary) {
        guard let id = json["id"] as? String,
            let title = json["title"] as? String,
            let season = json["season"] as? Int,
            let number = json["number"] as? Int,
            let subscriptionOnly = json["subscription_only"] as? Bool,
            let lastUpdateTimestamp = json["updated_at"] as? TimeInterval,
            let thumbnail = json["poster_url"] as? String, let thumbnailURL = URL(string: thumbnail),
            let media = json["media_url"] as? String, let mediaURL = URL(string: media)
            else { return nil }

        self.id = id
        self.title = title
        self.season = season
        self.number = number
        self.subscriptionOnly = subscriptionOnly
        self.lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
        self.thumbnailURL = thumbnailURL
        self.mediaURL = mediaURL
        self.synopsis = json["synopsis"] as? String
        self.text = json["transcript"] as? String
        if let releaseTimestamp = json["released_at"] as? TimeInterval {
            self.release = Date(timeIntervalSince1970: releaseTimestamp)
        }
        if let duration = json["media_duration"] as? TimeInterval {
            self.duration = Measurement(value: duration, unit: .seconds)
        }
    }
}
