//
//  TaskTests.swift
//  AsyncTest
//
//  Created by Thomas Sempf on 2017-03-06.
//  Copyright © 2017 Stendahls. All rights reserved.
//

import XCTest
@testable import AsyncTask

class TaskTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTaskWithLongLastingWork() {
        func encode(message: String) -> String {
            Thread.sleep(forTimeInterval: 0.1)
            return message
        }
        
        func encrypt(message: String) -> Task<String> {
            return Task {
                encode(message: message)
            }
        }
        
        let message = "Hello"
        let encrypted = encrypt(message: message).await()
        XCTAssert(encrypted == message, "")
    }
    
    func testTaskWhichWrapAsynchronousCall() {
        let session = URLSession(configuration: .ephemeral)
        
        let get = {(URL: URL) in
            Task { session.dataTask(with: URL, completionHandler: $0).resume() }
        }
        
        let url = URL(string: "https://httpbin.org/delay/1")!
        let (data, response, error) = get(url).await()
        
        XCTAssertNotNil(data, "Failed data")
        XCTAssertNotNil(response, "Failed response")
        XCTAssert(response?.url?.absoluteString == "https://httpbin.org/delay/1", "Wrong URL")
        XCTAssertNil(error)
    }
    
    func testTaskWithOptionalValues() {
        let load = {(path: String) -> Task<Data?> in
            Task {
                Thread.sleep(forTimeInterval:0.05)
                switch path {
                case "profile.png":
                    return Data()
                case "index.html":
                    return Data()
                default:
                    return nil
                }
            }
        }
        
        XCTAssertNotNil(load("profile.png").await())
        XCTAssertNotNil(load("index.html").await())
        XCTAssertNotNil([load("profile.png"), load("index.html")].awaitAll())
        
        XCTAssertNil(load("random.txt").await())
    }
    
    func testThatTasksCanBeNested() {
        let emptyString = Task<String> {
            Thread.sleep(forTimeInterval: 0.05)
            return ""
        }
        
        let appendString = {(a: String, b: String) -> Task<String> in
            Task {
                Thread.sleep(forTimeInterval: 0.05)
                return a + b
            }
        }
        
        let chainedTask = Task<String> {completion in
            emptyString.async {(s: String) in
                XCTAssert(s == "")
                appendString(s, "https://").async {(s: String) in
                    XCTAssert(s == "https://")
                    appendString(s, "swift").async {(s: String) in
                        XCTAssert(s == "https://swift")
                        appendString(s, ".org").async {(s: String) in
                            XCTAssert(s == "https://swift.org")
                            completion(s)
                        }
                    }
                }
            }
        }
        
        let sequentialTask = Task<String> {
            var s = emptyString.await()
            XCTAssert(s == "")
            s = appendString(s, "https://").await()
            XCTAssert(s == "https://")
            s = appendString(s, "swift").await()
            XCTAssert(s == "https://swift")
            s = appendString(s, ".org").await()
            XCTAssert(s == "https://swift.org")
            return s
        }
        
        XCTAssert(sequentialTask.await() == chainedTask.await())
    }
    
    func testThatTaskExcecuteAsynchronously() {
        let expect = expectation(description: "Finish expectation")

        var a = 0
        
        Task {
            Thread.sleep(forTimeInterval: 0.05)
            
            XCTAssert(a == 0)
            
            a = 1
            
            XCTAssert(a == 1)
        }.async {
            XCTAssert(a == 1)
            
            expect.fulfill()
        }
        
        XCTAssert(a == 0)
        
        
        waitForExpectations(timeout: 0.5) { (_) in
            XCTAssert(a == 1)
        }
    }
    
    func testThatTaskReturnResultInCallback() {
        let expect = expectation(description: "Finish expectation")
    
        let echo = Task {() -> String in
            Thread.sleep(forTimeInterval: 0.05)
            return "Hello"
        }
        
        echo.async {(message: String) in
            XCTAssert(message == "Hello")
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testThatTaskCanWaitAsynchronously() {
        let expect = expectation(description: "Finish expectation")

        var a = 0
        
        Task {
            Thread.sleep(forTimeInterval: 0.05)
            XCTAssert(a == 1)
            expect.fulfill()
        }.async()
        
        Task {
            XCTAssert(a == 0)
        }.await()
        
        a = 1

        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testThatAwaitReturnsNilAfterTimout() {
        let echo = Task { () -> String in
            Thread.sleep(forTimeInterval: 0.5)
            return "Hello"
        }
        
        XCTAssertNil(echo.await(.background, timeout: 0.05))
    }
    
    func testThatAwaitRunsSerially() {
        let numbers: [Int] = [0,1,2,3,4,5]
        
        let toStringTask = { (number: Int) -> Task<String> in
            return Task {
                Thread.sleep(forTimeInterval: Double.random(min: 0.01, max: 0.1))
                return "\(number)"
            }
        }
        
        let numersToString = Task<String> {
            var result: String = ""
            
            numbers.forEach({ number in
                result += toStringTask(number).await()
            })
            
            return result
        }
        
        XCTAssert(numersToString.await() == numbers.reduce("", { return $0 + "\($1)"}))
    }
    
    func testThatAsynRunsInParallel() {
        let numbers: [Int] = [0,1,2,3,4,5]
        let expect = expectation(description: "All tasks finished")
        let lockQueue = DispatchQueue(label: "lock")
        let concurrentQueue = DispatchQueue(label: "concurrent", attributes: .concurrent)
        var result: String = ""
        
        let toStringTask = { (number: Int) -> Task<String> in
            return Task {
                Thread.sleep(forTimeInterval: Double.random(min: 0.01, max: 0.05))
                return "\(number)"
            }
        }
        
        numbers.forEach ({
            toStringTask($0).async(concurrentQueue) { convertedNumber in
                lockQueue.sync {
                    result = result + convertedNumber
                    
                    if result.characters.count >= numbers.count {
                        expect.fulfill()
                    }
                }
            }
        })
        
        waitForExpectations(timeout: 5)

        numbers.forEach({ number in
            XCTAssert(result.contains("\(number)"))
        })
    }
}
