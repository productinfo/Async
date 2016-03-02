//
//  Extensions.swift
//  Pods
//
//  Created by Zhixuan Lai on 3/1/16.
//
//

import UIKit

public extension UIView {
    class func animateWithDurationAsync(duration: NSTimeInterval, animations: () -> Void) -> (Bool -> Void) -> Void {
        return async {
            await(.Main) {callback in
                UIView.animateWithDuration(duration, animations: animations, completion: callback)
            }
        }
    }
}

