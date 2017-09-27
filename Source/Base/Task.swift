//
//  AsyncTask.swift
//  Pods
//
//  Created by Zhixuan Lai on 5/27/16.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation


// Meant to be used only for scenarios where no error can be produced
public protocol TaskType {
    associatedtype ReturnType
    
    typealias ResultCallback = (ReturnType) -> Void

    func action(_ completion: @escaping ResultCallback)
    func async(_ queue: DispatchQueue, completion: @escaping ResultCallback)
    @discardableResult func await(_ queue: DispatchQueue) -> ReturnType
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

    @discardableResult
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
