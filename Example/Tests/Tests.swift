// https://github.com/Quick/Quick

import Quick
import Nimble
import SwiftAsync
import Foundation

class TableOfContentsSpec: QuickSpec {
    override func spec() {

        describe("async") {
            it("should execute asynchronously") {
                var a = 0
                async {
                    NSThread.sleepForTimeInterval(0.05)
                    expect(a) == 0
                    a = 1
                    expect(a) == 1
                }() { expect(a) == 1 }

                expect(a) == 0
                expect(a).toEventually(equal(1), timeout: 3)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should return result in callback") {
                let echo = async {() -> String in
                    NSThread.sleepForTimeInterval(0.05)
                    return "Hello"
                }

                echo {(message: String) in
                    expect(message) == "Hello"
                }

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
        }

        describe("await") {
            it("can take async or a closure that returns async") {
                async {
                    await(task: async { expect(1) == 1 })
                    await { async { expect(1) == 1 } }
                }($)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should return nil if timeout occurs") {
                async {
                    await(timeout: 0.4) { async { () -> Bool in NSThread.sleepForTimeInterval(0.3); return true } }
                }() {value in expect(value) == true }

                async {
                    await(timeout: 0.2) { async { () -> Bool in NSThread.sleepForTimeInterval(0.3); return true } }
                }() {value in expect(value).to(beNil())}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can wrap asynchronous APIs") {
                let session = NSURLSession(configuration: .ephemeralSessionConfiguration())

                let get = {(URL: NSURL) in
                    async { await {callback in session.dataTaskWithURL(URL, completionHandler: callback).resume()} }
                }

                async {
                    let URL = NSURL(string: "https://httpbin.org/delay/1")!
                    let (data, response, error) = await { get(URL) }
                    expect(data).to(beTruthy())
                    expect(response).to(beTruthy())
                    expect(response!.URL!.absoluteString) == "https://httpbin.org/delay/1"
                    expect(error).to(beNil())
                }($)

                waitUntil(timeout: 3) { done in
                    NSThread.sleepForTimeInterval(1.5)
                    done()
                }
            }

            it("should run serially inside for loops") {
                let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                let toString = {(number: Int) in
                    async {() -> String in
                        return "\(number)"
                    }
                }

                async {
                    var results = [String]()
                    for number in numbers {
                        let numberString = await { toString(number) }
                        results.append(numberString)
                    }
                    return results
                }() {(results: [String]) in expect(results) == numbers.map {number in "\(number)"}}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should run an array of closures in parallel") {
                let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                let toString = {(number: Int) in
                    async {() -> String in
                        NSThread.sleepForTimeInterval(0.03)
                        return "\(number)"
                    }
                }

                async {
                    await(parallel: numbers.map(toString))
                }() {(results:[String]) in expect(results).to(contain("0", "1", "2", "3", "4", "5", "6", "7", "8", "9"))}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should run a dictionary of closures in parallel") {
                let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                let toString = {(number: Int) in
                    async {() -> String in
                        NSThread.sleepForTimeInterval(0.03)
                        return "\(number)"
                    }
                }

                async {
                    var object: [Int: (String -> Void) -> Void] = [:]
                    let tasks = numbers.map(toString)
                    for (index, element) in tasks.enumerate() {
                        let key = numbers[index]
                        object[key] = element
                    }
                    return await(parallel: object)
                }() {(results:[Int: String]) in
                    var expected = [Int: String]()
                    for number in numbers {
                        expected[number] = "\(number)"
                    }
                    expect(results.count) == expected.count
                    for (key, _) in expected {
                        expect(expected[key]) == results[key]
                    }
                }
                
                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
        }

        describe("async and await") {
            it("can be chained together") {
                let createString = async {() -> String in
                    NSThread.sleepForTimeInterval(0.05)
                    return ""
                }

                let appendString = {(a: String, b: String) in
                    async {() -> String in
                        NSThread.sleepForTimeInterval(0.05)
                        return a + b
                    }
                }

                createString {(s: String) in
                    expect(s) == ""
                    appendString(s, "https://")() {(s: String) in
                        expect(s) == "https://"
                        appendString(s, "swift")() {(s: String) in
                            expect(s) == "https://swift"
                            appendString(s, ".org")() {(s: String) in
                                expect(s) == "https://swift.org"
                            }
                        }
                    }
                }

                async {
                    var s = await { createString }
                    expect(s) == ""
                    s = await { appendString(s, "https://") }
                    expect(s) == "https://"
                    s = await { appendString(s, "swift") }
                    expect(s) == "https://swift"
                    s = await { appendString(s, ".org") }
                    expect(s) == "https://swift.org"
                }($)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can return tuple") {
                enum Error: ErrorType {
                    case NotFoundError
                }

                let load = {(path: String) in
                    async {() -> (data: NSData?, error: Error?) in
                        NSThread.sleepForTimeInterval(0.05)
                        switch path {
                        case "profile.png":
                            return (NSData(), nil)
                        case "index.html":
                            return (NSData(), nil)
                        default:
                            return (nil, .NotFoundError)
                        }
                    }
                }

                async {
                    let (data1, error1) = await { load("profile.png") }
                    expect(data1).to(beTruthy())
                    expect(error1).to(beNil())

                    let (data2, error2) = await { load("index.html") }
                    expect(data2).to(beTruthy())
                    expect(error2).to(beNil())

                    let (data3, error3) = await { load("random.txt") }
                    expect(data3).to(beNil())
                    expect(error3) == .NotFoundError
                }($)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
        }

        describe("async$") {
            it("should execute asynchronously") {
                var a = 0
                async$ {
                    NSThread.sleepForTimeInterval(0.05)
                    expect(a) == 0
                    a = 1
                    expect(a) == 1
                }() {(_, _) in expect(a) == 1}

                expect(a) == 0
                expect(a).toEventually(equal(1), timeout: 3)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should return result in callback") {
                let echo = async$ {() -> String in
                    NSThread.sleepForTimeInterval(0.05)
                    return "Hello"
                }

                echo {(message: String?, _: ErrorType?) in
                    expect(message) == "Hello"
                }

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should catch thrown error") {
                enum Error: ErrorType {
                    case TestError
                }

                async$ {
                    throw Error.TestError
                }() {(_, error) in expect(error).to(beTruthy())}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
        }

        describe("await$") {
            it("can take async or a closure that returns async") {
                async$ {
                    try await$(task: async$ { expect(1) == 1 })
                    try await$ { async$ { expect(1) == 1 } }
                }() {_, _ in}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should return nil if timeout occurs") {
                async$ {
                    try await$(timeout: 0.4) { async$ { () -> Bool in NSThread.sleepForTimeInterval(0.3); return true } }
                }() {(value, error) in expect(value!) == true }

                async$ {
                    try await$(timeout: 0.2) { async$ { () -> Bool in NSThread.sleepForTimeInterval(0.3); return true } }
                }() {(value, error) in expect(value!).to(beNil())}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can wrap asynchronous APIs") {
                let config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
                config.timeoutIntervalForRequest = 2
                config.timeoutIntervalForResource = 2
                let session = NSURLSession(configuration: config)

                let get = {(URL: NSURL) in
                    async$ {() -> (NSData, NSURLResponse) in
                        let (data, response, error) = await {callback in session.dataTaskWithURL(URL, completionHandler: callback).resume()}
                        guard let d = data, r = response where error == nil else { throw error! }
                        return (d, r)
                    }
                }

                async$ {
                    let URL = NSURL(string: "https://httpbin.org/delay/1")!
                    let (data, response) = try await$ { get(URL) }
                    expect(data).to(beTruthy())
                    expect(response).to(beTruthy())
                    expect(response.URL!.absoluteString) == "https://httpbin.org/delay/1"
                }() {value, error in expect(error).to(beNil())}

                async$ {() -> (NSData, NSURLResponse) in
                    let URL = NSURL(string: "https://httpbin.org/status/404")!
                    return try await$ { get(URL) }
                }() {value, error in
                    expect(value).to(beTruthy())
                    expect(error).to(beNil())
                }

                async$ {() -> (NSData, NSURLResponse) in
                    let URL = NSURL(string: "https://invalid.url")!
                    return try await$ { get(URL) }
                }() {value, error in
                    expect(value).to(beNil())
                    expect(error).to(beTruthy())
                }

                waitUntil(timeout: 5) { done in
                    NSThread.sleepForTimeInterval(4)
                    done()
                }
            }

            it("should run serially inside for loops") {
                let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                let toString = {(number: Int) in
                    async$ {() -> String in
                        return "\(number)"
                    }
                }

                async {
                    var results = [String]()
                    do {
                        for number in numbers {
                            let numberString = try await$ { toString(number) }
                            results.append(numberString)
                        }
                    } catch {

                    }
                    return results
                }() {(results: [String]) in expect(results) == numbers.map {number in "\(number)"}}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should run an array of closures in parallel") {
                let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                let toString = {(number: Int) in
                    async$ {() -> String in
                        NSThread.sleepForTimeInterval(0.03)
                        return "\(number)"
                    }
                }

                async {
                    var results = [String]()
                    do {
                        results = try await$(parallel: numbers.map(toString))
                    } catch {

                    }
                    return results
                }() {(results:[String]) in expect(results).to(contain("0", "1", "2", "3", "4", "5", "6", "7", "8", "9"))}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should run a dictionary of closures in parallel") {
                let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                let toString = {(number: Int) in
                    async$ {() -> String in
                        NSThread.sleepForTimeInterval(0.03)
                        return "\(number)"
                    }
                }

                async {
                    var object: [Int: ((String?, ErrorType?) -> Void) -> Void] = [:]
                    let tasks = numbers.map(toString)
                    for (index, element) in tasks.enumerate() {
                        let key = numbers[index]
                        object[key] = element
                    }
                    var results = [Int: String]()
                    do {
                        results = try await$(parallel: object)
                    } catch {

                    }
                    return results
                }() {(results:[Int: String]) in
                    var expected = [Int: String]()
                    for number in numbers {
                        expected[number] = "\(number)"
                    }
                    expect(results.count) == expected.count
                    for (key, _) in expected {
                        expect(expected[key]) == results[key]
                    }
                }

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can throw error") {
                enum Error: ErrorType {
                    case TestError
                }

                let willThrow = async$ {() throws in
                    throw Error.TestError
                }

                async {
                    expect{ try await${ willThrow } }.to(throwError())
                }($)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
        }

        describe("async$ and await$") {
            it("should work together") {
                enum Error: ErrorType {
                    case TestError
                }
                
                let willThrow = async$ {() throws in
                    NSThread.sleepForTimeInterval(0.05)
                    throw Error.TestError
                }
                
                async$ {
                    try await${ willThrow }
                }({(_, error) in
                    expect(error).to(beTruthy())
                })

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
        }
        

        // TODO: test performace against GCD APIs

        // Thanks to https://github.com/duemunk/Async
        describe("DispatchQueue") {
            it("works with async") {
                async(.Main) {
                    #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                        expect(NSThread.isMainThread()) == true
                    #else
                        expect(qos_class_self()) == qos_class_main()
                    #endif
                }($)

                async(.UserInteractive) {
                    expect(qos_class_self()) == QOS_CLASS_USER_INTERACTIVE
                }($)

                async(.UserInitiated) {
                    expect(qos_class_self()) == QOS_CLASS_USER_INITIATED
                }($)

                async(.Utility) {
                    expect(qos_class_self()) == QOS_CLASS_UTILITY
                }($)

                async(.Background) {
                    expect(qos_class_self()) == QOS_CLASS_BACKGROUND
                }($)

                let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
                async(.Custom(customQueue)) {
                    let currentClass = qos_class_self()
                    let isValidClass = currentClass == qos_class_main() || currentClass == QOS_CLASS_USER_INITIATED
                    expect(isValidClass) == true
                    // TODO: Test for current queue label. dispatch_get_current_queue is unavailable in Swift, so we cant' use the return value from and pass it to dispatch_queue_get_label.
                }($)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("works with await") {
                async {
                    await(.Main) {(callback: Void -> Void) in
                        #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                            expect(NSThread.isMainThread()) == true
                        #else
                            expect(qos_class_self()) == qos_class_main()
                        #endif
                        callback()
                    }
                }($)

                async {
                    await(.UserInteractive) {(callback: Void -> Void) in
                        expect(qos_class_self()) == QOS_CLASS_USER_INTERACTIVE
                        callback()
                    }
                }($)

                async {
                    await(.UserInitiated) {(callback: Void -> Void) in
                        expect(qos_class_self()) == QOS_CLASS_USER_INITIATED
                        callback()
                    }
                }($)

                async {
                    await(.Utility) {(callback: Void -> Void) in
                        expect(qos_class_self()) == QOS_CLASS_UTILITY
                        callback()
                    }
                }($)

                async {
                    await(.Background) {(callback: Void -> Void) in
                        expect(qos_class_self()) == QOS_CLASS_BACKGROUND
                        callback()
                    }
                }($)

                let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
                async {
                    await(.Custom(customQueue)) {(callback: Void -> Void) in
                        let currentClass = qos_class_self()
                        let isValidClass = currentClass == qos_class_main() || currentClass == QOS_CLASS_USER_INITIATED
                        expect(isValidClass) == true
                        // TODO: Test for current queue label. dispatch_get_current_queue is unavailable in Swift, so we cant' use the return value from and pass it to dispatch_queue_get_label.
                        callback()
                    }
                }($)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("works with async$") {
                async$(.Main) {
                    #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                        expect(NSThread.isMainThread()) == true
                    #else
                        expect(qos_class_self()) == qos_class_main()
                    #endif
                }() {_, _ in}

                async$(.UserInteractive) {
                    expect(qos_class_self()) == QOS_CLASS_USER_INTERACTIVE
                }() {_, _ in}

                async$(.UserInitiated) {
                    expect(qos_class_self()) == QOS_CLASS_USER_INITIATED
                }() {_, _ in}

                async$(.Utility) {
                    expect(qos_class_self()) == QOS_CLASS_UTILITY
                }() {_, _ in}

                async$(.Background) {
                    expect(qos_class_self()) == QOS_CLASS_BACKGROUND
                }() {_, _ in}

                let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
                async$(.Custom(customQueue)) {
                    let currentClass = qos_class_self()
                    let isValidClass = currentClass == qos_class_main() || currentClass == QOS_CLASS_USER_INITIATED
                    expect(isValidClass) == true
                    // TODO: Test for current queue label. dispatch_get_current_queue is unavailable in Swift, so we cant' use the return value from and pass it to dispatch_queue_get_label.
                }() {_, _ in}

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("works with await$") {
                async$ {
                    try await$(.Main) {(callback: (Void?, ErrorType?) -> Void) in
                        #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                            expect(NSThread.isMainThread()) == true
                        #else
                            expect(qos_class_self()) == qos_class_main()
                        #endif
                        callback((), nil)
                    }
                }() {_, _ in}

                async$ {
                    try await$(.UserInteractive) {(callback: (Void?, ErrorType?) -> Void) in
                        expect(qos_class_self()) == QOS_CLASS_USER_INTERACTIVE
                        callback((), nil)
                    }
                }() {_, _ in}

                async$ {
                    try await$(.UserInitiated) {(callback: (Void?, ErrorType?) -> Void) in
                        expect(qos_class_self()) == QOS_CLASS_USER_INITIATED
                        callback((), nil)
                    }
                }() {_, _ in}

                async$ {
                    try await$(.Utility) {(callback: (Void?, ErrorType?) -> Void) in
                        expect(qos_class_self()) == QOS_CLASS_UTILITY
                        callback((), nil)
                    }
                }() {_, _ in}

                async$ {
                    try await$(.Background) {(callback: (Void?, ErrorType?) -> Void) in
                        expect(qos_class_self()) == QOS_CLASS_BACKGROUND
                        callback((), nil)
                    }
                }() {_, _ in}

                let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
                async$ {
                    try await$(.Custom(customQueue)) {(callback: (Void?, ErrorType?) -> Void) in
                        let currentClass = qos_class_self()
                        let isValidClass = currentClass == qos_class_main() || currentClass == QOS_CLASS_USER_INITIATED
                        expect(isValidClass) == true
                        // TODO: Test for current queue label. dispatch_get_current_queue is unavailable in Swift, so we cant' use the return value from and pass it to dispatch_queue_get_label.
                        callback((), nil)
                    }
                }() {_, _ in}
                
                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
        }
    }
}
