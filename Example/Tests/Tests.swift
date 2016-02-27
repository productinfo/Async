// https://github.com/Quick/Quick

import Quick
import Nimble
import Async

class TableOfContentsSpec: QuickSpec {
    override func spec() {
        describe("these will succeed") {

            it("should not invoke") {
                let _ = async {
                    NSThread.sleepForTimeInterval(0.1)
                    expect(1) == 2
                }

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can async") {
                var a = 0
                async {
                    NSThread.sleepForTimeInterval(0.05)
                    expect(a) == 0
                    a = 1
                    expect(a) == 1
                }()
                expect(a) == 0
                expect(a).toEventually(equal(1), timeout: 3)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("async func with arguments") {
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


            it("async func normal error") {
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
                }()

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("async func catch error") {
                enum Error: ErrorType {
                    case TestError
                }

                let willThrow = async$ {() throws in
                    NSThread.sleepForTimeInterval(0.05)

                    print("bbb error")

                    throw Error.TestError
                    print("after error")
                }

                async {
                    do {
                        try await${ willThrow }
                    } catch {
                        print(error)
                    }
                    expect{ try await${ willThrow } }.to(throwError())

                }()




                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can chain") {

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
                    (appendString(s, "https://")) {(s: String) in
                        expect(s) == "https://"
                        (appendString(s, "swift")) {(s: String) in
                            expect(s) == "https://swift"
                            (appendString(s, ".org")) {(s: String) in
                                expect(s) == "https://swift.org"
                            }
                        }
                    }
                }

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can chain pineline") {
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

                async {
                    var s = await { createString }
                    expect(s) == ""
                    s = await { appendString(s, "https://") }
                    expect(s) == "https://"
                    s = await { appendString(s, "swift") }
                    expect(s) == "https://swift"
                    s = await { appendString(s, ".org") }
                    expect(s) == "https://swift.org"
                }()

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

        }

        describe("these will fail") {

//            it("can do maths") {
//                expect(1) == 2
//            }
//
//            it("can read") {
//                expect("number") == "string"
//            }
//
//            it("will eventually fail") {
//                expect("time").toEventually( equal("done") )
//            }

            context("these will pass") {

                it("can do maths") {
                    expect(23) == 23
                }

                it("can read") {
                    expect("🐮") == "🐮"
                }

                it("will eventually pass") {
                    var time = "passing"

                    dispatch_async(dispatch_get_main_queue()) {
                        time = "done"
                    }

                    waitUntil { done in
                        NSThread.sleepForTimeInterval(0.5)
                        expect(time) == "done"

                        done()
                    }
                }
            }
        }
    }
}
