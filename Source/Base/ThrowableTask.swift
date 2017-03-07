//
//  BaseTask.swift
//  Pods
//
//  Created by Zhixuan Lai on 6/1/16.
//
//

import Foundation

public enum Result<ReturnType> {
    case success(ReturnType)
    case failure(Error)

    public func extract() throws -> ReturnType {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
}

public protocol ThrowableTaskType {
    associatedtype ReturnType
    
    typealias ResultCallback = (Result<ReturnType>) -> Void

    func action(_ completion: @escaping ResultCallback)
    func asyncResult(_ queue: DispatchQueue, completion: @escaping ResultCallback)
    func awaitResult(_ queue: DispatchQueue, timeout: TimeInterval) -> Result<ReturnType>
    func await(_ queue: DispatchQueue, timeout: TimeInterval) throws -> ReturnType
}

extension ThrowableTaskType {

    public func asyncResult(_ queue: DispatchQueue = DefaultQueue, completion: @escaping ResultCallback) {
        queue.async {
            self.action(completion)
        }
    }

    public func awaitResult(_ queue: DispatchQueue = DefaultQueue, timeout: TimeInterval = TimeoutForever) -> Result<ReturnType> {
        let timeout = DispatchTime(timeInterval: timeout)

        var value: Result<ReturnType>?
        let fd_sema = DispatchSemaphore(value: 0)

        queue.async {
            self.action {result in
                value = result
                fd_sema.signal()
            }
        }

        guard  fd_sema.wait(timeout: timeout) == .success else {
            return Result.failure(AsyncTaskError.timeout)
        }

        return value!
    }

    public func await(_ queue: DispatchQueue = DefaultQueue, timeout: TimeInterval = TimeoutForever) throws -> ReturnType {
        return try awaitResult(queue, timeout: timeout).extract()
    }

}

open class ThrowableTask<ReturnType> : ThrowableTaskType {
    public typealias ResultCallback = (Result<ReturnType>) -> Void
    
    private let action: (@escaping ResultCallback) -> Void

    open func action(_ completion: @escaping ResultCallback) {
        self.action(completion)
    }

    public init(action: @escaping (@escaping ResultCallback) -> Void) {
        self.action = action
    }

    public convenience init(action: @escaping () -> Result<ReturnType>) {
        self.init {callback in callback(action())}
    }

    public convenience init(action: @escaping ((ReturnType) -> Void) throws -> Void) {
        self.init {(callback: ResultCallback) in
            do {
                try action {result in
                    callback(Result.success(result))
                }
            } catch {
                callback(Result.failure(error))
            }
        }
    }

    public convenience init(action: @escaping () throws -> ReturnType) {
        self.init { (callback: ResultCallback) in
            do {
                callback(Result.success(try action()))
            } catch {
                callback(Result.failure(error))
            }
        }
    }

}
