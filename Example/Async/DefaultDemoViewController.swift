//
//  DefaultDemoViewController.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/25/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import UIKit
import SwiftAsync

class DefaultDemoViewController: LogsDemoViewController {

    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        let createImage = async {() -> UIImage in
            sleep(3)
            return UIImage()
        }

        let processImage = {(image: UIImage) in
            async {() -> UIImage in
                sleep(1)
                return image
            }
        }

        let updateImageView = {(image: UIImage) in
            async(.Main) {
                self.imageView.image = image
            }
        }

        async {[weak self] in
            self?.log("creating image")
            var image = await { createImage }
            self?.log("processing image")
            image = await { processImage(image) }
            await { async(.Main) { self?.imageView.image = UIImage() } }
            self?.log("updating imageView")
            await { updateImageView(image) }
            self?.log("updated imageView")
        }() {}
    }

}
