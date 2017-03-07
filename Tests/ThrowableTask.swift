//
//  ThrowableTask.swift
//  AsyncTest
//
//  Created by Thomas Sempf on 2017-03-06.
//  Copyright © 2017 Stendahls. All rights reserved.
//

import XCTest
@testable import AsyncTask

class ThrowableTaskTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTaskThrows() {
        enum TaskError: Error {
            case notFound
        }
        
        let load = {(path: String) -> ThrowableTask<Data> in
            ThrowableTask {
                Thread.sleep(forTimeInterval: 0.05)
                switch path {
                case "profile.png":
                    return Data()
                case "index.html":
                    return Data()
                default:
                    throw TaskError.notFound
                }
            }
        }
        
        
        XCTAssertNotNil(try? load("profile.png").await())
        XCTAssertNotNil(try? load("index.html").await())
        XCTAssertNotNil(try? [load("profile.png"), load("index.html")].awaitAll())
        
        XCTAssertThrowsError(try load("random.txt").await())
        XCTAssertThrowsError(try [load("profile.png"), load("index.html"), load("random.txt")].awaitAll())
    }
    
    func testThatAwaitResultReturnsFailureAfterTimeout() {
        let echo = ThrowableTask { () -> String in
            Thread.sleep(forTimeInterval: 0.5)
            return "Hello"
        }
        
        let result = echo.awaitResult(.background, timeout: 0.05)
        
        if case .success = result {
            XCTFail()
        }
    }
    
    func testThatAwaitThrowsAfterTimeout() {
        let echo = ThrowableTask { () -> String in
            Thread.sleep(forTimeInterval: 0.5)
            return "Hello"
        }
        
        XCTAssertThrowsError(try echo.await(.background, timeout: 0.05))
    }
}
