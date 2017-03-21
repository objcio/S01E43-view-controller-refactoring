//
//  Environment.swift
//  Videos
//
//  Created by Florian Kugler on 10-10-2016.
//  Copyright © 2016 Chris Eidhof. All rights reserved.
//

import Foundation

struct Environment {
    var baseURL = URL(string: "https://talk.objc.io")!
    
    static let current = Environment()
}
