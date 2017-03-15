//
//  Config.swift
//  Pods
//
//  Created by Zhixuan Lai on 5/29/16.
//
//

import Foundation

let DefaultQueue = DispatchQueue.userInitiated

let TimeoutForever = TimeInterval(-1)

let DefaultConcurrency = 50

let async_custom_queue = DispatchQueue(label: "asynctask.serial.queue")

enum AsyncTaskError: Error {
    case timeout
}
