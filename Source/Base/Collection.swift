//
//  Wait.swift
//  Pods
//
//  Created by Zhixuan Lai on 5/27/16.
//
//

import Foundation

extension Sequence where Iterator.Element : ThrowableTaskType {

    public func awaitFirstResult(_ queue: DispatchQueue = DefaultQueue, concurrency: Int = DefaultConcurrency) -> Result<Iterator.Element.ReturnType> {
        let tasks = map{$0}
        
        return Task(action: { (callback: @escaping (Result<Iterator.Element.ReturnType>) -> ()) in
            tasks.concurrentForEach(queue, concurrency: concurrency, transform: {task in task.awaitResult()}) { result in
                callback(result)
            }
        }).await(queue)
    }

    public func awaitAllResults(_ queue: DispatchQueue = DefaultQueue, concurrency: Int = DefaultConcurrency) -> [Result<Iterator.Element.ReturnType>] {
        let tasks = map{$0}
        
        return tasks.concurrentMap(queue, concurrency: concurrency) {task in task.awaitResult()}
    }

    public func awaitFirst(_ queue: DispatchQueue = DefaultQueue) throws -> Iterator.Element.ReturnType {
        return try awaitFirstResult(queue).extract()
    }

    public func awaitAll(_ queue: DispatchQueue = DefaultQueue, concurrency: Int = DefaultConcurrency) throws -> [Iterator.Element.ReturnType] {
        return try awaitAllResults(queue, concurrency: concurrency).map {try $0.extract()}
    }

}

extension Dictionary where Value : ThrowableTaskType {

    public func awaitFirst(_ queue: DispatchQueue = DefaultQueue) throws -> Value.ReturnType {
        return try values.awaitFirst(queue)
    }

    public func awaitAll(_ queue: DispatchQueue = DefaultQueue, concurrency: Int = DefaultConcurrency) throws -> [Key: Value.ReturnType] {
        let elements = Array(zip(Array(keys), try values.awaitAll(queue, concurrency: concurrency)))
        return Dictionary<Key, Value.ReturnType>(elements: elements)
    }
    
}

extension Sequence where Iterator.Element : TaskType {

    var throwableTasks: [ThrowableTask<Iterator.Element.ReturnType>] {
        return map {$0.throwableTask}
    }

    public func awaitFirst(_ queue: DispatchQueue = DefaultQueue) -> Iterator.Element.ReturnType {
        return try! throwableTasks.awaitFirstResult(queue).extract()
    }

    public func awaitAll(_ queue: DispatchQueue = DefaultQueue, concurrency: Int = DefaultConcurrency) -> [Iterator.Element.ReturnType] {
        return throwableTasks.awaitAllResults(queue, concurrency: concurrency).map {result in try! result.extract() }
    }

}

extension Dictionary where Value : TaskType {

    var throwableTasks: [ThrowableTask<Value.ReturnType>] {
        return values.throwableTasks
    }

    public func awaitFirst(_ queue: DispatchQueue = DefaultQueue) -> Value.ReturnType {
        return try! throwableTasks.awaitFirstResult(queue).extract()
    }

    public func await(_ queue: DispatchQueue = DefaultQueue, concurrency: Int = DefaultConcurrency) -> [Key: Value.ReturnType] {
        let elements = Array(zip(Array(keys), try! throwableTasks.awaitAll(queue, concurrency: concurrency)))
        return Dictionary<Key, Value.ReturnType>(elements: elements)
    }

}

extension Dictionary {

    init(elements: [(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }

}

extension Array {

    func concurrentForEach<U>(_ queue: DispatchQueue, concurrency: Int, transform: @escaping (Element) -> U, completion: @escaping (U) -> ()) {
        let tasks = map{$0}
        let workGroup = DispatchGroup()
        let maxWorkItemsSema = DispatchSemaphore(value: concurrency)
        
        tasks.forEach ({ task in
            maxWorkItemsSema.wait()
            workGroup.enter()
            
            queue.async(group: workGroup) {
                let result = transform(task)
                
                async_custom_queue.sync {
                    completion(result)
                    workGroup.leave()
                    maxWorkItemsSema.signal()
                }
            }
        })
        
        workGroup.wait()
    }

    func concurrentMap<U>(_ queue: DispatchQueue, concurrency: Int, transform: @escaping (Element) -> U) -> [U] {
        let fd_sema = DispatchSemaphore(value: 0)
        let fd_sema2 = DispatchSemaphore(value: concurrency)

        var results = [U?](repeating: nil, count: count)
        var numberOfCompletedTasks = 0
        let numberOfTasks = count

        DispatchQueue.concurrentPerform(iterations: count) {index in
            let _ = fd_sema2.wait(timeout: DispatchTime(timeInterval: -1))
            let result = transform(self[index])
            async_custom_queue.sync {
                results[index] = result
                numberOfCompletedTasks += 1
                if numberOfCompletedTasks == numberOfTasks {
                    fd_sema.signal()
                }
                fd_sema2.signal()
            }
        }

        let _ = fd_sema.wait(timeout: DispatchTime(timeInterval: -1))
        return results.flatMap {$0}
    }

}

