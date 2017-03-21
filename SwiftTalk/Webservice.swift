//
//  Webservice.swift
//  Videos
//
//  Created by Florian on 13/04/16.
//  Copyright © 2016 Chris Eidhof. All rights reserved.
//

import UIKit

extension Episode {
    public static var all: Resource<[Episode]> = try! Resource(
        url: Environment.current.baseURL.appendingPathComponent("episodes.json"),
        parseElement: Episode.init
    )
}

extension Episode {
    public var thumbnail: Resource<UIImage> {
        return Resource(url: thumbnailURL, parse: { UIImage(data: $0 as Data) }, method: .get)
    }
}

//public func pushNotificationRegistration(_ token: Data) -> Resource<()> {
//    let json: JSONDictionary = ["token": token.hexadecimalString]
//    return try! Resource<()>(url: URL(string: "https://swifttalk-staging.herokuapp.com/push_notification_token")!, method: .post(data: json), parseJSON: { _ in () })
//}

public enum Result<A> {
    case success(A)
    case error(Error)
}

extension Result {
    public init(_ value: A?, or error: Error) {
        if let value = value {
            self = .success(value)
        } else {
            self = .error(error)
        }
    }

    public var value: A? {
        guard case .success(let v) = self else { return nil }
        return v
    }
}


public enum WebServiceError: Error {
    case notAuthenticated
    case other
}

func logError<A>(_ result: Result<A>) {
    guard case let .error(e) = result else { return }
    assert(false, "\(e)")
}

public final class Webservice {
    public var authenticationToken: AuthToken?
    public init() { }
    
    /// Loads a resource. The completion handler is always called on the main queue.
    public func load<A>(_ resource: Resource<A>, completion: @escaping (Result<A>) -> () = logError) {
        URLSession.shared.dataTask(with: resource.urlRequest, completionHandler: { data, response, _ in
            let result: Result<A>
            if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 401 {
                result = Result.error(WebServiceError.notAuthenticated)
            } else {
                let parsed = data.flatMap(resource.parse)
                result = Result(parsed, or: WebServiceError.other)
            }
            mainQueue { completion(result) }
        }) .resume()
    }
}



