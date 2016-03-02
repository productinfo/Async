//
//  Async.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/24/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import Foundation

// MARK: Default: async<T>/await<T>

public func async<T>(queue: DispatchQueue = getDefaultQueue(), task: () -> T) -> ((T -> Void) -> Void) {
    return {(callback: T -> Void) in
        dispatch_async(queue.get()) {
            callback(task())
        }
    }
}

/*:
https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationQueues/OperationQueues.html#//apple_ref/doc/uid/TP40008091-CH102-SW5
The actual number of tasks executed by a concurrent queue at any given moment is variable and can change dynamically as conditions in your application change. Many factors affect the number of tasks executed by the concurrent queues, including the number of available cores, the amount of work being done by other processes, and the number and priority of tasks in other serial dispatch queues.
*/

public func await<K, T>(queue: DispatchQueue = getDefaultQueue(), timeout: NSTimeInterval, parallel tasks: [K: (T -> Void) -> Void]) -> [K: T?] {
    let timeout = dispatch_time_t(timeInterval: timeout)
    let group = dispatch_group_create()

    var results = [K: T?]()

    for (key, task) in tasks {
        results.updateValue(nil, forKey: key)
        dispatch_group_async(group, queue.get()) {
            let fd_sema = dispatch_semaphore_create(0)
            task {(result: T) in
                results[key] = result
                dispatch_semaphore_signal(fd_sema)
            }
            if dispatch_semaphore_wait(fd_sema, timeout) == 1 {
                results[key] = nil
            }
        }
    }

    dispatch_group_wait(group, timeout)

    return results
}

public func await<T>(queue: DispatchQueue = getDefaultQueue(), timeout: NSTimeInterval, parallel tasks: [(T -> Void) -> Void]) -> [T?] {
    return Array(await(queue, timeout: timeout, parallel: tasks.indexedDictionary).values)
}

public func await<T>(queue: DispatchQueue = getDefaultQueue(), timeout: NSTimeInterval, task: (T -> Void) -> Void) -> T? {
    return await(queue, timeout: timeout, parallel: [task])[0]
}

public func await<T>(queue: DispatchQueue = getDefaultQueue(), timeout: NSTimeInterval, task: (Void -> (T -> Void) -> Void)) -> T? {
    return await(queue, timeout: timeout, parallel: [task()])[0]
}

// wait on the queue in which it was invoked. queue: the queue to execute the tasks, animation, main thread
public func await<K, T>(queue: DispatchQueue = getDefaultQueue(), parallel tasks: [K: (T -> Void) -> Void]) -> [K: T] {
    var results = [K: T]()
    for (key, value) in await(queue, timeout: -1, parallel: tasks) {
        results.updateValue(value!, forKey: key)
    }
    return results
}

public func await<T>(queue: DispatchQueue = getDefaultQueue(), parallel tasks: [(T -> Void) -> Void]) -> [T] {
    return Array(await(queue, parallel: tasks.indexedDictionary).values)
}

public func await<T>(queue: DispatchQueue = getDefaultQueue(), task: (T -> Void) -> Void) -> T {
    return await(queue, parallel: [task])[0]
}

public func await<T>(queue: DispatchQueue = getDefaultQueue(), task: (Void -> (T -> Void) -> Void)) -> T {
    return await(queue, parallel: [task()])[0]
}

// MARK: - Error Handling: async$<T>/await$<T>

/*:
https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/
> GCD is a C level API; it does not catch exceptions generated by higher level languages. Your application must catch all exceptions before returning from a task submitted to a dispatch queue.
*/

public func async$<T>(queue: DispatchQueue = getDefaultQueue(), task: () throws -> T) -> (((T?, ErrorType?) -> Void) -> Void) {
    return {(callback: (T?, ErrorType?) -> Void) in
        dispatch_async(queue.get()) {
            do {
                callback(try task(), nil)
            } catch {
                callback(nil, error)
            }
        }
    }
}

public func await$<K, T>(queue: DispatchQueue = getDefaultQueue(), timeout: NSTimeInterval, parallel tasks: [K: (((T?, ErrorType?) -> Void) -> Void)]) throws -> [K: T?] {
    let timeout = dispatch_time_t(timeInterval: timeout)
    let group = dispatch_group_create()

    var results = [K: T?]()
    var err: ErrorType?

    for (key, task) in tasks {
        guard err == nil else { break }
        results.updateValue(nil, forKey: key)
        dispatch_group_async(group, queue.get()) {
            let fd_sema = dispatch_semaphore_create(0)
            task {result, error in
                results[key] = result
                if err == nil {
                    err = error
                }
                dispatch_semaphore_signal(fd_sema)
            }
            if dispatch_semaphore_wait(fd_sema, timeout) == 1 {
                results[key] = nil
            }
        }
    }

    dispatch_group_wait(group, timeout)

    if let err = err {
        throw err
    }

    return results
}

public func await$<T>(queue: DispatchQueue = getDefaultQueue(), timeout: NSTimeInterval, parallel tasks: [(((T?, ErrorType?) -> Void) -> Void)]) throws -> [T?] {
    return Array(try await$(queue, timeout: timeout, parallel: tasks.indexedDictionary).values)
}

public func await$<T>(queue: DispatchQueue = getDefaultQueue(), timeout: NSTimeInterval, task: (((T?, ErrorType?) -> Void) -> Void)) throws -> T? {
    return try await$(queue, timeout: timeout, parallel: [task])[0]
}

public func await$<T>(queue: DispatchQueue = getDefaultQueue(), timeout: NSTimeInterval, task: (Void -> (((T?, ErrorType?) -> Void) -> Void))) throws -> T? {
    return try await$(queue, timeout: timeout, parallel: [task()])[0]
}

public func await$<K, T>(queue: DispatchQueue = getDefaultQueue(), parallel tasks: [K: (((T?, ErrorType?) -> Void) -> Void)]) throws -> [K: T] {
    var results = [K: T]()
    for (key, value) in try await$(queue, timeout: -1, parallel: tasks) {
        results.updateValue(value!, forKey: key)
    }
    return results
}

public func await$<T>(queue: DispatchQueue = getDefaultQueue(), parallel tasks: [(((T?, ErrorType?) -> Void) -> Void)]) throws -> [T] {
    return Array(try await$(queue, parallel: tasks.indexedDictionary).values)
}

public func await$<T>(queue: DispatchQueue = getDefaultQueue(), task: (((T?, ErrorType?) -> Void) -> Void)) throws -> T {
    return try await$(queue, parallel: [task])[0]
}

public func await$<T>(queue: DispatchQueue = getDefaultQueue(), task: (Void -> (((T?, ErrorType?) -> Void) -> Void))) throws -> T {
    return try await$(parallel: [task()])[0]
}

// MARK: - Helpers
private func getDefaultQueue() -> DispatchQueue {
    return .UserInitiated
}
