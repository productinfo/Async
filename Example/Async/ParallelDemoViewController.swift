//
//  ParallelDemoViewController.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/24/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import UIKit
import SwiftAsync

class ParallelRequestDemoViewController: DelayedRequestTableViewController {

    override func reload() {
        requests.removeAll()
        for _ in 0..<numberOfRequests {
            let delay = random() % 10
            requests.append(DelayedRequest(delay: delay))
        }

        async {[weak self] in
            let array = self!.requests.enumerate().map {(index: Int, request: DelayedRequest) in
                async { () -> NSData in
                    self?.updateRequest(index, state: .Running)

                    let data = await { get(request.URL) }

                    self?.updateRequest(index, state: .Finished)
                    print("downloaded URL: \(request.URL)")
                    return data
                }
            }
            let results = await(parallel: array)

            print("downloaded \(results.count) URLs in parallel")
        }() {}

    }

}
