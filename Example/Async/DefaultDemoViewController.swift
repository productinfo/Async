//
//  DefaultDemoViewController.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/25/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import UIKit

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
            async(dispatch_get_main_queue()) {() -> Bool in
                self.imageView.image = image
                return true
            }
        }

        async {[weak self] in
            self?.log("creating image")
            var image = await { createImage }
            self?.log("processing image")
            image = await(processImage(image))
            image = await { processImage(image) }
            await { async(dispatch_get_main_queue()) { self?.imageView.image = UIImage() } }
            self?.log("updating imageView")
            let updated = await(updateImageView(image))
            self?.log("updated imageView: \(updated)")
        }()


        /*
        print("creating image")
        createImage {image in
            print("processing image")
            (processImage(image)) {image in
                print("updating imageView")
                (updateImageView(image)) { updated in
                    print("updated imageView: \(updated)")
                }
            }
        }
        */
    }

}
