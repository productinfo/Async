// https://github.com/Quick/Quick

import Quick
import Nimble
import Async

class TableOfContentsSpec: QuickSpec {
    override func spec() {

        describe("async () -> ()") {

            it("should return a closure") {
                let _ = async {
                    NSThread.sleepForTimeInterval(0.1)
                    expect(1) == 2
                }

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("works asynchronosly") {
                var a = 0
                async {
                    NSThread.sleepForTimeInterval(0.05)
                    expect(a) == 0
                    a = 1
                    expect(a) == 1
                }({
                    expect(a) == 1
                })
                expect(a) == 0
                expect(a).toEventually(equal(1), timeout: 3)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            // queue

        }


        describe("await (() -> ()) -> ()") {

            it("can take async") {
                async {
                    await(async { expect(1) == 1 })
                    }({})

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can take a closure that returns async: { () -> () }") {
                async {
                    await { async { expect(1) == 1 } }
                }({})

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            // queue

            // timeout



        }

        describe("async<T> () -> T") {
            it("returns correct value") {
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


        describe("await<T> (T -> ()) -> ()") {

            it("takes closure of closure { (T -> ()) -> () }") {


            }

            // wrap async api

            it("runs serially inside for loop") {
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
                }({(results: [String]) in
                    expect(results) == numbers.map {number in "\(number)"}
                })

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("if passed an array, parallel") {
                let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                let toString = {(number: Int) in
                    async {() -> String in
                        NSThread.sleepForTimeInterval(0.1)
                        return "\(number)"
                    }
                }

                async {
                    await(parallel: numbers.map(toString))
                    }({(results:[String]) in
                        expect(results).to(contain(numbers.map {number in "\(number)"}))
                    })

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("if passed an object, parallel") {
                let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                let toString = {(number: Int) in
                    async {() -> String in
                        NSThread.sleepForTimeInterval(0.1)
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
                }({(results:[Int: String]) in
//                    expect(results).to(contain(numbers.map {number in "\(number)"}))
                })
                
                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

        }

        describe("async and await") {

            it("can be chained") {

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
                    }({})

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
                    }({})

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

        }

        describe("async$ and await$") {

            it("will throw error") {
                enum Error: ErrorType {
                    case TestError
                }

                let willThrow = async$ {() throws in
                    NSThread.sleepForTimeInterval(0.05)
                    throw Error.TestError
                }

                expect{ try await${ willThrow } }.to(throwError())

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("returns error") {
                enum Error: ErrorType {
                    case TestError
                }
                
                let willThrow = async$ {() throws in
                    NSThread.sleepForTimeInterval(0.05)
                    throw Error.TestError
                }
                
                async$ {
                    try await${ willThrow }
                }({error in
                    expect(error).to(beTruthy())
                })

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
            
            
        }
        
        
        describe("QoS") {
            
            it("can get Queue") {
                
            }
            
            it("works with async") {
                
            }
            
            
            it("works with await") {
                
            }
            
            
        }
    }
}
