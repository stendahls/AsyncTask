//
//  Misc.swift
//  AsyncDemo
//
//  Created by Zhixuan Lai on 2/26/16.
//  Copyright © 2016 Zhixuan Lai. All rights reserved.
//

import Foundation

public extension DispatchQueue {
    public static var userInteractive: DispatchQueue {
        return .global(qos: .userInteractive)
    }
    
    public static var userInitiated: DispatchQueue {
        return .global(qos: .userInitiated)
    }
    
    public static var utility: DispatchQueue {
        return .global(qos: .utility)
    }
    
    public static var background: DispatchQueue {
        return .global(qos: .background)
    }
}

