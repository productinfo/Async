# Async

<!-- [![CI Status](http://img.shields.io/travis/Zhixuan Lai/Async.svg?style=flat)](https://travis-ci.org/Zhixuan Lai/Async)
[![Version](https://img.shields.io/cocoapods/v/Async.svg?style=flat)](http://cocoapods.org/pods/Async)
[![License](https://img.shields.io/cocoapods/l/Async.svg?style=flat)](http://cocoapods.org/pods/Async)
[![Platform](https://img.shields.io/cocoapods/p/Async.svg?style=flat)](http://cocoapods.org/pods/Async) -->

Async, await control flow for Swift.

## Installation

Async is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftAsync"
```

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Prerequisites:
- [Trailing Closures](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html#//apple_ref/doc/uid/TP40014097-CH11-ID102)
- [GCD](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/)
- [Capture List](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html#//apple_ref/doc/uid/TP40014097-CH20-ID48)

### async
Here is how you create an async function
~~~swift
let createImage = async {() -> UIImage in
    sleep(3)
    return UIImage()
}
~~~

Here is how you execute the async function
~~~swift
createImage() {image in
  // do something with the image
}
~~~

Here is how you create an async function with parameters
~~~swift
let fetchImage = {(URL: NSURL) in
    async {() -> UIImage in
        // fetch the image synchronously
        let image = get(URL)
        return image
    }
}

fetchImage(URL)() {image in
    // do something with the image
}
~~~

Let's define more functions like this
~~~swift
let processImage = {(image: UIImage) in
    async {() -> UIImage in
        sleep(1)
        return image
    }
}

let updateImageView = {(image: UIImage) in
    async(.Main) {() -> Bool in
        self.imageView.image = image
        return true
    }
}
~~~

Chaining async functions is cumbersome. Use `await` to simplify it.
~~~swift
print("creating image")
createImage {image in
    print("processing image")
    processImage(image)() {image in
        print("updating imageView")
        updateImageView(image)() { updated in
            print("updated imageView: \(updated)")
        }
    }
}

async {
    print("creating image")
    var image = await { createImage }
    print("processing image")
    image = await { processImage(image) }
    print("updating imageView")
    let updated = await { updateImageView(image) }
    print("updated imageView: \(updated)")
}() {}
~~~

### await
`await` is a blocking function. Because of this, it should never be called in main thread. It executes a closure of type `(T -> Void) -> Void`, AKA a thunk, and returns the result synchronously.

~~~swift
async {
    // blocks the thread until callback is called
    let message = await {(callback: (String -> Void)) in
        sleep(1)
        callback("Hello")
    }
    print(message) // "Hello"
}() {}

// equivalent to
async {
    let message = await {
        async {() -> String in sleep(1); return "Hello" }
    }
    print(message) // "Hello"
}() {}

// equivalent to
async {
    sleep(1)
    let message = "Hello"
    print(message) // "Hello"
}
~~~

Here is how to use `await` to wrap asynchronous APIs (eg. network request, animation, ...) and make them synchronous.
~~~swift
let session = NSURLSession(configuration: .ephemeralSessionConfiguration())

let get = {(URL: NSURL) in
    async { () -> (NSData?, NSURLResponse?, NSError?) in
        await {callback in session.dataTaskWithURL(URL, completionHandler: callback).resume()}
    }
}

// with error handling
let get = {(URL: NSURL) in
    async { () -> NSData? in
        let (data, _, error) = await {callback in session.dataTaskWithURL(URL, completionHandler: callback).resume()}
        guard let d = data where error != nil else { return nil }
        return d
    }
}

async {
  let data = await(get(URL))
  print(data)
}() {}
~~~

### serial vs parallel

Since `await` is blocking, for loop is a natural way to run tasks in series.
~~~swift
let URLs = [NSURL]()
async {
    var results = [NSData]()

    for URL in URLs {
        let data = await(block: get(URL))
        results.append(data)
    }

    print("fetched \(results.count) items in series")
}() {}
~~~

`await` can also take an array or a dictionary of tasks and perform them in parallel.
~~~swift
let URLs = [NSURL]()
async {
    let results = await(blocks: URLs.map(get))

    print("fetched \(results.count) items in parallel")
}() {}
~~~

Error handling.

Test file and demo app for more examples.

### Strong reference cycle
According to [Strong Reference Cycles for Closures](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html#//apple_ref/doc/uid/TP40014097-CH20-ID48)
> A strong reference cycle can also occur if you assign a closure to a property of a class instance, and the body of that closure captures the instance. This capture might occur because the closure’s body accesses a property of the instance, such as self.someProperty, or because the closure calls a method on the instance, such as self.someMethod(). In either case, these accesses cause the closure to “capture” self, creating a strong reference cycle.

It is helpful to add a capture list to the top level closure. Please take a look at the demo project for more examples

~~~swift
async {[weak self] in
    self?.doSomething()
}
~~~

## License

Async is available under the MIT license. See the LICENSE file for more info.
