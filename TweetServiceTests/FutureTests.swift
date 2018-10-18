//
//  FutureTests.swift
//  testXCTestTests
//
//  Created by Hori,Masaki on 2018/01/15.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

import XCTest
@testable import TweetService

enum FutureTestError: Error {
    
    case testError
    
    case testError2
}

class FutureTests: XCTestCase {
    
    func testAsynchronus() {
        
        let ex = expectation(description: "Future")
        
        var first = true
        
        Future<Int> {
            sleep(1)
            first = false
            return 1
            }
            .onSuccess { _ in
                ex.fulfill()
        }
        
        XCTAssertTrue(first)
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSuccess() {
        
        let ex = expectation(description: "Future")
        Future<Int>(.value(5))
            .onSuccess { val in
                guard val == 5 else { return XCTFail("Fugaaaaaaaaa") }
                
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSuccess2() {
        
        let ex = expectation(description: "Future")
        let ex2 = expectation(description: "Future2")
        Future(5)
            .onSuccess { val in
                guard val == 5 else { return XCTFail("Fugaaaaaaaaa") }
                
                ex.fulfill()
            }
            .onSuccess { _ in
                ex2.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
                ex2.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testAsynchronousSuccess() {
        
        let ex = expectation(description: "Future")
        Future<Int> {
            sleep(1)
            return 5
            }
            .onSuccess { val in
                guard val == 5 else { return XCTFail("Fugaaaaaaaaa") }
                
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFailure() {
        
        let ex = expectation(description: "Future")
        Future<Int>(FutureTestError.testError)
            .onSuccess { val in
                XCTFail("Fugaaaaaa")
                ex.fulfill()
            }
            .onFailure { error in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFailure2() {
        
        let ex = expectation(description: "Future")
        let ex2 = expectation(description: "Future2")
        Future<Int>(FutureTestError.testError)
            .onSuccess { val in
                XCTFail("Fugaaaaaa")
                ex.fulfill()
                ex2.fulfill()
            }
            .onFailure { error in
                ex.fulfill()
            }
            .onFailure { _ in
                ex2.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testAsynchronousFailure() {
        
        let ex = expectation(description: "Future")
        Future<Int> {
            sleep(1)
            throw FutureTestError.testError
            }
            .onSuccess { val in
                XCTFail("Fugaaaaaa")
                ex.fulfill()
            }
            .onFailure { error in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testIsCompleted() {

        let f = Future<Int>(3)
        XCTAssertTrue(f.isCompleted)
        let ff = Future<Int>()
        XCTAssertFalse(ff.isCompleted)
    }
    
    func testAwait() {
        
        let f = Future<Int> {
            sleep(1)
            return 1000
        }
        
        XCTAssertEqual(f.await().value!.value!, 1000)
    }
    
    func testAwait2ndTime() {
        
        let f = Future<Int> {
            sleep(1)
            return 1000
        }
        
        XCTAssertEqual(f.await().await().value!.value!, 1000)
    }
    
    func testAwait3rdTime() {
        
        let f = Future<Int> {
            sleep(1)
            return 1000
        }
        
        XCTAssertEqual(f.await().await().await().value!.value!, 1000)
    }
    
    func testTransform() {
        
        Future<String> { () -> String in
            sleep(1)
            return "Hoge"
            }
            .transform( { (s: String) -> String in "Fuga" },
                        { err -> Error in FutureTestError.testError} )
            .onSuccess { val in
                
                XCTAssertEqual(val, "Fuga")
            }
            .onFailure { error in
                
                XCTFail("Hoge: \(error)")
        }
    }
    
    func testTransform2() {
        
        Future<String>(FutureTestError.testError)
            .transform( { (s: String) -> String in "Fuga" },
                        { err -> Error in FutureTestError.testError2} )
            .onSuccess { val in
                
                XCTFail("testTransform2")
            }
            .onFailure { error in
                
                guard let err = error as? FutureTestError else {
                    
                    XCTFail("Error is no FutureTestError.")
                    
                    return
                }
                
                XCTAssertEqual(err, FutureTestError.testError2)
        }
    }
    
    func testMap() {
        
        let ex = expectation(description: "Future")
        Future<String> {
            sleep(1)
            return "Hoge"
            }
            .map { $0.count }
            .onSuccess { val in
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testMapFailure() {
        
        let ex = expectation(description: "Future")
        Future<String>(FutureTestError.testError)
            .map { $0.count }
            .onSuccess { _ in
                XCTFail("Hoge")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFlatMap() {
        
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int> {
            sleep(1)
            return 1
        }
        
        Future<Int>(2)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .onSuccess { val in
                if val != 2 {
                    XCTFail()
                }
                ex.fulfill()
            }
            .onFailure { _ in
                XCTFail()
                ex.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFlatMapFailure1() {
        
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int>(FutureTestError.testError)
        
        Future(2)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .onSuccess { _ in
                XCTFail()
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFlatMapFailure2() {
        
        let ex = expectation(description: "Future")
        
        let f1 = Future(1)
        
        Future<Int>(FutureTestError.testError)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .onSuccess { _ in
                XCTFail()
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFlatMapFailure3() {
        
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int>(FutureTestError.testError)
        
        Future<Int>(FutureTestError.testError)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .onSuccess { _ in
                XCTFail()
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFilter() {
        
        let ex = expectation(description: "Future")
        Future<Int> {
            sleep(1)
            return 5
            }
            .filter { $0 == 5}
            .onSuccess { _ in
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFilterFailure() {
        
        let ex = expectation(description: "Future")
        Future<Int> {
            sleep(1)
            return 5
            }
            .filter { $0 > 5}
            .onSuccess { _ in
                XCTFail("Hogeeeeeeee")
                ex.fulfill()
            }
            .onFailure { error in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRecover() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(FutureTestError.testError)
            .recover {
                guard let e = $0 as? FutureTestError,
                    e == FutureTestError.testError else {
                        throw $0
                }
                return 10
            }
            .onSuccess {
                XCTAssertEqual($0, 10)
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRecoverWithThrow() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(FutureTestError.testError)
            .recover { _ in
                throw FutureTestError.testError2
            }
            .onSuccess {
                XCTFail("Fuga: \($0)")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRecoverFailure1() {
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int>(FutureTestError.testError)
        
        Future(2)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .recover { e in -1000 }
            .onSuccess { val in
                if val > 0 {
                    XCTFail()
                }
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    func testRecoverFailure2() {
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int> {
            sleep(1)
            return 1
        }
        
        Future<Int>(FutureTestError.testError)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .recover { e in -10000 }
            .onSuccess { val in
                if val > 0 {
                    XCTFail()
                }
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRecoverSuccess() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(5)
            .recover {
                guard let e = $0 as? FutureTestError,
                    e == FutureTestError.testError else {
                        throw $0
                }
                return 10
            }
            .onSuccess {
                XCTAssertEqual($0, 5)
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAndThen() {
        
        let ex = expectation(description: "Future")
        
        var v = 0
        
        Future<Int>(6)
            .andThen { _ in
                guard v == 0 else {
                    XCTFail()
                    return
                }
                sleep(1)
                v = 4
            }
            .andThen { _ in
                guard v == 4 else {
                    XCTFail()
                    return
                }
                sleep(1)
                v = 5
            }
            .andThen { _ in
                guard v == 5 else {
                    XCTFail()
                    return
                }
                ex.fulfill()
            }
            .onSuccess {
                guard $0 == 6 else {
                    XCTFail()
                    return
                }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

}
