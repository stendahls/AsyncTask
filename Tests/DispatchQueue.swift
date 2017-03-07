//
//  AsyncTestUnitTests.swift
//  AsyncTestUnitTests
//
//  Created by Thomas Sempf on 2017-01-10.
//  Copyright © 2017 Stendahls. All rights reserved.
//

import XCTest
@testable import AsyncTask

class DispatchQueueTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAsyncRunsOnMainQueue() {
        let expectMainThread = expectation(description: "Should be called from main thread")
        
        Task() {
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                XCTAssert(Thread.isMainThread == true, "Should be main thread")
            #else
                XCTAssert(qos_class_self() == qos_class_main(), "Should be main thread")
            #endif
            
            expectMainThread.fulfill()
        }.async(.main)
     
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAsyncRunsOnInteractiveQueue() {
        let expectQOS_CLASS_USER_INTERACTIVE = expectation(description: "Should be called from QOS_CLASS_USER_INTERACTIVE")

        Task() {
            XCTAssert(qos_class_self() == QOS_CLASS_USER_INTERACTIVE, "Should be on QOS_CLASS_USER_INTERACTIVE")
            expectQOS_CLASS_USER_INTERACTIVE.fulfill()
        }.await(.userInteractive)

        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAsyncRunsOnUserInitiatedQueue() {
        let expectQOS_CLASS_USER_INITIATED = expectation(description: "Should be called from QOS_CLASS_USER_INITIATED")
        
        Task() {
            XCTAssert(qos_class_self() == QOS_CLASS_USER_INITIATED, "Should be on QOS_CLASS_USER_INITIATED")
            expectQOS_CLASS_USER_INITIATED.fulfill()
        }.await(.userInitiated)

        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAsyncRunsOnUtilityQueue() {
        let expectQOS_CLASS_UTILITY = expectation(description: "Should be called from QOS_CLASS_UTILITY")
        
        Task() {
            XCTAssert(qos_class_self() == QOS_CLASS_UTILITY, "Should be on QOS_CLASS_UTILITY")
            expectQOS_CLASS_UTILITY.fulfill()
            }.await(.utility)
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testAsyncRunsOnBackgroundQueue() {
        let expectQOS_CLASS_BACKGROUND = expectation(description: "Should be called from QOS_CLASS_BACKGROUND")
        
        Task() {
            XCTAssert(qos_class_self() == QOS_CLASS_BACKGROUND, "Should be on QOS_CLASS_BACKGROUND")
            expectQOS_CLASS_BACKGROUND.fulfill()
            }.await(.background)
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAsyncRunsOnCustomQueue() {
        func currentQueueName() -> String? {
            let name = __dispatch_queue_get_label(nil)
            return String(cString: name, encoding: .utf8)
        }

        let expectCustomQeue = expectation(description: "Should be called from QOS_CLASS_BACKGROUND")
        let customQueue = DispatchQueue(label: "CustomQueueLabel")
            
        Task() {
            XCTAssert(currentQueueName() == "CustomQueueLabel", "Should be on Custom Queue")
            expectCustomQeue.fulfill()
        }.await(customQueue)
        
        waitForExpectations(timeout: 5, handler: nil)
    }    
}
