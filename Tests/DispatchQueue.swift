//
//  AsyncTestUnitTests.swift
//  AsyncTestUnitTests
//
//  Created by Thomas Sempf on 2017-01-10.
//  Copyright © 2017 Stendahls. All rights reserved.
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
