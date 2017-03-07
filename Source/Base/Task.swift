//
//  AsyncTask.swift
//  Pods
//
//  Created by Zhixuan Lai on 5/27/16.
//
//

import Foundation

public protocol TaskType {
    associatedtype ReturnType
    
    typealias ResultCallback = (ReturnType) -> Void

    func action(_ completion: @escaping ResultCallback)
    func async(_ queue: DispatchQueue, completion: @escaping ResultCallback)
    func await(_ queue: DispatchQueue, timeout: TimeInterval) -> ReturnType?
    func await(_ queue: DispatchQueue) -> ReturnType
}

extension TaskType {

    public var throwableTask: ThrowableTask<ReturnType> {
        return ThrowableTask<ReturnType>(action: { callback in
            self.action { result in
                callback(Result.success(result))
            }
        })
    }
    
    public func async(_ queue: DispatchQueue = DefaultQueue, completion: @escaping (ResultCallback) = {_ in}) {
        throwableTask.asyncResult(queue) {result in
            if case let .success(r) = result {
                completion(r)
            }
        }
    }

    public func await(_ queue: DispatchQueue = DefaultQueue, timeout: TimeInterval) -> ReturnType? {
        do {
            let result = try throwableTask.awaitResult(queue, timeout: timeout).extract()
            return result
        } catch {
            return nil
        }
    }

    public func await(_ queue: DispatchQueue = DefaultQueue) -> ReturnType {
        return try! throwableTask.awaitResult(queue).extract()
    }
}

open class Task<ReturnType> : TaskType {
    public typealias ResultCallback = (ReturnType) -> Void
    
    private let action: (@escaping ResultCallback) -> Void

    open func action(_ completion: @escaping ResultCallback) {
        self.action(completion)
    }

    public init(action anAction: @escaping (@escaping ResultCallback) -> Void) {
        self.action = anAction
    }

    public convenience init(action: @escaping () -> ReturnType) {
        self.init {callback in callback(action())}
    }

}
