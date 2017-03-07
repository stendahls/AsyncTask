//
//  main.swift
//  AsyncTest
//
//  Created by Thomas Sempf on 2017-03-03.
//  Copyright © 2017 Stendahls. All rights reserved.
//
import UIKit
import Foundation

private func delegateClassName() -> String? {
    return NSClassFromString("XCTestCase") == nil ? NSStringFromClass(AppDelegate.self) : nil
}

UIApplicationMain(
    CommandLine.argc,
    UnsafeMutableRawPointer(CommandLine.unsafeArgv)
        .bindMemory(
            to: UnsafeMutablePointer<Int8>.self,
            capacity: Int(CommandLine.argc)),
    nil,
    delegateClassName()
)
