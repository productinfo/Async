//
//  Extensions.swift
//  Async
//
//  Created by Zhixuan Lai on 3/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SwiftAsync

extension UIView {
    class func animateWithDurationAsync(duration: NSTimeInterval, animations: () -> Void) -> (Bool -> Void) -> Void {
        return async {
            await {callback in
                async(.Main) {
                    UIView.animateWithDuration(duration, animations: animations, completion: callback)
                }() {}
            }
        }
    }
}

