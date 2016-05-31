// https://github.com/Quick/Quick

import Quick
import Nimble
import AsyncTask

class TableOfContentsSpec: QuickSpec {
    override func spec() {

        describe("task") {

            it("can warp expensive synchronous API") {
                func encode(message: String) -> String {
                    NSThread.sleepForTimeInterval(0.1)
                    return message
                }

                func encryptMessage(message: String) -> Task<String> {
                    return Task {
                        encode(message)
                    }
                }

                let message = "Hello"
                let encrypted = encryptMessage(message).await()
                expect(encrypted) == message
            }

            it("can wrap asynchronous APIs") {
                let session = NSURLSession(configuration: .ephemeralSessionConfiguration())

                let get = {(URL: NSURL) in
                    Task { session.dataTaskWithURL(URL, completionHandler: $0).resume() }
                }

                let URL = NSURL(string: "https://httpbin.org/delay/1")!
                let (data, response, error) = get(URL).await()
                expect(data).to(beTruthy())
                expect(response).to(beTruthy())
                expect(response!.URL!.absoluteString) == "https://httpbin.org/delay/1"
                expect(error).to(beNil())
            }

            it("should return nil if timeout occurs") {
                let task = Task<Bool> { NSThread.sleepForTimeInterval(0.3); return true }
                expect(task.await(timeout: 0.4)) == true
                expect(task.await(timeout: 0.2)).to(beNil())
            }

            it("can take optional value") {
                let load = {(path: String) -> Task<NSData?> in
                    Task {
                        NSThread.sleepForTimeInterval(0.05)
                        switch path {
                        case "profile.png":
                            return NSData()
                        case "index.html":
                            return NSData()
                        default:
                            return nil
                        }
                    }
                }

                expect(load("profile.png").await()).to(beTruthy())
                expect(load("index.html").await()).to(beTruthy())
                expect(load("random.txt").await()).to(beNil())
            }

            it("can be nested") {
                let emptyString = Task<String> {
                    NSThread.sleepForTimeInterval(0.05)
                    return ""
                }

                let appendString = {(a: String, b: String) -> Task<String> in
                    Task {
                        NSThread.sleepForTimeInterval(0.05)
                        return a + b
                    }
                }

                let chainedTask = Task {(completion: String -> ()) in
                    emptyString.async {(s: String) in
                        expect(s) == ""
                        appendString(s, "https://").async {(s: String) in
                            expect(s) == "https://"
                            appendString(s, "swift").async {(s: String) in
                                expect(s) == "https://swift"
                                appendString(s, ".org").async {(s: String) in
                                    expect(s) == "https://swift.org"
                                    completion(s)
                                }
                            }
                        }
                    }
                }

                let sequentialTask = Task<String> {
                    var s = emptyString.await()
                    expect(s) == ""
                    s = appendString(s, "https://").await()
                    expect(s) == "https://"
                    s = appendString(s, "swift").await()
                    expect(s) == "https://swift"
                    s = appendString(s, ".org").await()
                    expect(s) == "https://swift.org"
                    return s
                }

                expect(sequentialTask.await()) == chainedTask.await()
            }

        }

        describe("collection of tasks") {
            let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

            let toString = {(number: Int) -> Task<String> in
                Task { "\(number)" }
            }

            it("should run serially inside for loops") {
                var results = [String]()
                for number in numbers {
                    results.append(toString(number).await())
                }
                expect(results) == numbers.map {number in "\(number)"}
            }

            it("should run serially inside map") {
                let results = numbers.map {number in toString(number).await()}
                expect(results) == numbers.map {number in "\(number)"}
            }

            it("should run an array of closures in parallel") {
                let results = numbers.map(toString).await()
                expect(results).to(contain("0", "1", "2", "3", "4", "5", "6", "7", "8", "9"))
            }

            it("should run a dictionary of closures in parallel") {
                var tasks = [Int: Task<String>]()
                let re = numbers.map(toString)
                for (index, element) in re.enumerate() {
                    let key = numbers[index]
                    tasks[key] = element
                }
                let results = tasks.await()

                var expected = [Int: String]()
                for number in numbers {
                    expected[number] = "\(number)"
                }
                expect(results.count) == expected.count
                for (key, _) in expected {
                    expect(expected[key]) == results[key]
                }
            }

            it("should limit concurrency") {
                let wait = {(timeInterval: NSTimeInterval) -> Task<Bool> in
                    Task {
                        NSThread.sleepForTimeInterval(timeInterval)
                        return true
                    }
                }

                func waitForSeconds(seconds: Int, concurrency: Int, timeout: NSTimeInterval) -> Task<Int> {
                    return Task {
                        (0..<seconds).map{_ in 1}.map(wait)
                            .await(concurrency: concurrency, timeout: timeout * 1.1)
                            .flatMap {$0}
                            .count
                    }
                }

                let testcases = [(2, 1, 2.0), (2, 1, 1), (3, 3, 1), (3, 2, 2)]
                expect(testcases.map(waitForSeconds).await()) == testcases.map {min($0, ($1 * Int($2)))}
            }

        }

        describe("throwing task") {
            it("should throw") {
                enum Error: ErrorType {
                    case NotFound
                }

                let load = {(path: String) -> ThrowingTask<NSData> in
                    ThrowingTask {
                        NSThread.sleepForTimeInterval(0.05)
                        switch path {
                        case "profile.png":
                            return NSData()
                        case "index.html":
                            return NSData()
                        default:
                            throw Error.NotFound
                        }
                    }
                }

                expect{try load("profile.png").await()}.notTo(throwError())
                expect{try load("index.html").await()}.notTo(throwError())
                expect{try load("random.txt").await()}.to(throwError())
                expect{try [load("profile.png"), load("index.html")].await()}.notTo(throwError())
                expect{try [load("profile.png"), load("index.html"), load("random.txt")].await()}.to(throwError())
            }

        }

        describe("collection of throwing tasks") {
            let numbers: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

            enum Error : ErrorType {
                case FoundZero
            }

            let toStringExceptZero = {(number: Int) -> ThrowingTask<String> in
                ThrowingTask {
                    if number == 0 {
                        throw Error.FoundZero
                    }
                    return "\(number)"
                }
            }

            it("should throw if any task throws") {
                expect{try numbers.map(toStringExceptZero).await()}.to(throwError())
            }
        }
        

        // TODO: test performace against GCD APIs

        // Thanks to https://github.com/duemunk/Async
        describe("DispatchQueue") {
            it("works with async") {

                // waiting on the current thread creates dead lock
                Task() {
                    #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(tvOS)) // Simulator
                        expect(NSThread.isMainThread()) == true
                    #else
                        expect(qos_class_self()) == qos_class_main()
                    #endif
                }.async(.Main)

                Task() {
                    expect(qos_class_self()) == QOS_CLASS_USER_INTERACTIVE
                }.async(.UserInteractive)

                Task() {
                    expect(qos_class_self()) == QOS_CLASS_USER_INITIATED
                }.async(.UserInitiated)

                Task() {
                    expect(qos_class_self()) == QOS_CLASS_UTILITY
                }.async(.Utility)

                Task() {
                    expect(qos_class_self()) == QOS_CLASS_BACKGROUND
                }.async(.Background)

                let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
                Task() {
                    let currentClass = qos_class_self()
                    let isValidClass = currentClass == qos_class_main() || currentClass == QOS_CLASS_USER_INITIATED
                    expect(isValidClass) == true
                    // TODO: Test for current queue label. dispatch_get_current_queue is unavailable in Swift, so we cant' use the return value from and pass it to dispatch_queue_get_label.
                }.await(.Custom(customQueue))

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.05)
                    done()
                }
            }
        }

        describe("task (trivial examples)") {
            it("should execute asynchronously") {
                var a = 0

                Task {
                    NSThread.sleepForTimeInterval(0.05)
                    expect(a) == 0
                    a = 1
                    expect(a) == 1
                }.async { expect(a) == 1 }

                expect(a) == 0
                expect(a).toEventually(equal(1), timeout: 3)

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("should return result in callback") {
                let echo = Task {() -> String in
                    NSThread.sleepForTimeInterval(0.05)
                    return "Hello"
                }

                echo.async {(message: String) in
                    expect(message) == "Hello"
                }

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }

            it("can wait synchronously") {
                var a = 0

                Task { NSThread.sleepForTimeInterval(0.05); expect(a) == 1 }.async()
                Task {expect(a) == 0}.await()

                a = 1

                waitUntil { done in
                    NSThread.sleepForTimeInterval(0.5)
                    done()
                }
            }
                
        }

    }
}
