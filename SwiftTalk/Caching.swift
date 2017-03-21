//
//  Caching.swift
//  Videos
//
//  Created by Florian Kugler on 01-11-2016.
//  Copyright © 2016 Chris Eidhof. All rights reserved.
//

import Foundation

extension Resource {
    var hash: String {
        return url.absoluteString.sha1()
    }
}

final class DiskCache {
    init() { }
    private let cacheDirectory: URL =
        try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    
    private func cacheLocation<A>(of resource: Resource<A>) -> URL {
        let key = resource.hash
        return cacheDirectory.appendingPathComponent(key)
    }
    
    func load<A>(_ resource: Resource<A>) -> A? {
        guard case .get = resource.method else {
            return nil
        }
        
        let data = try? Data(contentsOf: cacheLocation(of: resource))
        return data.flatMap(resource.parse)
    }
    
    func save<A>(_ data: Data, for resource: Resource<A>) {
        guard case .get = resource.method else { return }
        let url = cacheLocation(of: resource)
        try? data.write(to: url)
    }
}

public final class CachedWebservice {
    private let webservice: Webservice
    private let cache: DiskCache = DiskCache()
    
    public init(webservice: Webservice) {
        self.webservice = webservice
    }
    
    public func load<A>(_ resource: Resource<A>, skipCache: Bool, update: @escaping (Result<A>) -> () = logError) {
        let dataResource: Resource<Data> = Resource(url: resource.url, parse: { $0 }, method: resource.method)
        
        if skipCache == false, let result = cache.load(resource) {
            update(.success(result))
        }
        
        webservice.load(dataResource) { result in
            switch result {
            case let .success(data):
                self.cache.save(data, for: dataResource)
                update(Result(resource.parse(data), or: WebServiceError.other))
            case let .error(err):
                update(.error(err))
            }
        }
    }
}
