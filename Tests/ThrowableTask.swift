//
//  ThrowableTask.swift
//  AsyncTest
//
//  Created by Thomas Sempf on 2017-03-06.
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

class ThrowableTaskTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatAwaitHasDiscardableResult() {
        let task = ThrowableTask<String> { (completion: (String) -> Void) in
            // do nothing
            completion("Foobar")
        }
        
        do {
            try task.await()
        } catch {
            // nothing
        }
        
        XCTAssert(true)
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
