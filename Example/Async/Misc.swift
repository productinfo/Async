//
//  Misc.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/24/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import Foundation
import UIKit
import SwiftAsync

struct DelayedRequest {
    static let baseURL = "https://httpbin.org/delay/"

    enum State {
        case Pending, Running, Finished

        var description : String {
            switch self {
            case .Pending: return "Pending";
            case .Running: return "Running";
            case .Finished: return "Finished";
            }
        }
    }

    let delay: Int
    let URL: NSURL

    var state: State
//    var response: JSON
    init(delay: Int) {
        self.delay = delay
        URL = NSURL(string: "\(DelayedRequest.baseURL)\(delay)")!
        state = .Pending
    }
}

let session = NSURLSession(configuration: .ephemeralSessionConfiguration())

let get = {(URL: NSURL) in
    async { () -> NSData in
        let (data, _, _) = await {callback in session.dataTaskWithURL(URL, completionHandler: callback).resume()}
        return data!
    }
}

public extension CGFloat {
    public static func random(lower: CGFloat = 0.0, upper: CGFloat = 1.0) -> CGFloat {
        let r = CGFloat(arc4random()) / CGFloat(UInt32.max)
        return (r * (upper - lower)) + lower
    }
}



