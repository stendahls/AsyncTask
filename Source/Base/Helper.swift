//
//  Misc.swift
//  Pods
//
//  Created by Zhixuan Lai on 3/1/16.
//
//

import Foundation

internal extension DispatchTime {
    init(timeInterval: TimeInterval) {
        let timeIntervalInNanoSeconds = timeInterval < TimeInterval(0) ? DispatchTime.distantFuture : DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        self.init(uptimeNanoseconds: timeIntervalInNanoSeconds.uptimeNanoseconds)
    }
}
