//
//  ChainedAnimationDemoViewController.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/25/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import UIKit
import SwiftAsync

class ChainedAnimationDemoViewController: UIViewController {

    let label = UILabel(frame: CGRectMake(0, 0, 200, 21))

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()

        label.center = randomCenter()
        label.textAlignment = NSTextAlignment.Center
        label.text = "I'am a test label"
        view.addSubview(label)

        let duration: NSTimeInterval = 1

        async {[weak self] in
            while self != nil {
                let completed = await { UIView.animateWithDurationAsync(0.3) { self?.label.center = self!.randomCenter() } }
//                    {callback in
//                    async(.Main) {
//                        UIView.animateWithDuration(duration, animations: { self?.label.center = self!.randomCenter() }, completion: callback)
//                    }() {}
//                }

                print("animation completed: \(completed)")
            }
        }() {}
    }

    func randomCenter() -> CGPoint {
        return CGPointMake(CGFloat.random(0.2, upper: 0.8) * view.frame.width, CGFloat.random(0.2, upper: 0.8) * view.frame.height)
    }

}
