//
//  SerialDemoViewController.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/24/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import UIKit
import ReactiveUI
import SwiftAsync

class SerialRequestDemoViewController: DelayedRequestDemoViewController {

    override func reload() {
        requests.removeAll()
        for _ in 0..<numberOfRequests {
            let delay = random() % 10
            requests.append(DelayedRequest(delay: delay))
        }

        async {[weak self] in
            var results = [NSData]()

            for (index, request) in self!.requests.enumerate() {
                guard self != nil else { break }

                self?.updateRequest(index, state: .Running)

                let data = await { get(request.URL) }

                self?.updateRequest(index, state: .Finished)
                results.append(data)

                print("downloaded URL: \(request.URL)")
            }

            print("downloaded \(results.count) URLs in series")
        }() {}
    }

}
