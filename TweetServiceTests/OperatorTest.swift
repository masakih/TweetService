//
//  OperatorTest.swift
//  TweetServiceTests
//
//  Created by Hori,Masaki on 2018/10/27.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import XCTest

@testable import TweetService


class OperatorTest: XCTestCase {

    enum TestError: Error {
        case test1, test2
    }
    
    func testTripleExclamation() {
        
        do {
            func f() throws -> Int {
                
                return 1
            }
            
            let result = try f() !!! TestError.test2
            XCTAssertEqual(result, 1)
        }
        catch {
            
            XCTFail("OOPs")
        }
        
        
        do {
            func f() throws -> Int {
                
                throw TestError.test1
            }
            
            _ = try f() !!! TestError.test2
            XCTFail("not throw.")
        }
        catch {
            switch error {
                
            case let e as TestError: XCTAssertEqual(e, .test2)
                
            default: XCTFail("Not test2")
            }
        }
    }
    
    func testDoubbleExclamation() {
        
        do {
            func f() throws -> Int? {
                
                return 1
            }
            
            let result = try f() ?!! TestError.test2
            XCTAssertEqual(result, 1)
        }
        catch {
            
            XCTFail("OOPs")
        }
        
        do {
            func f() throws -> Int? {
                
                return nil
            }
            
            _ = try f() ?!! TestError.test2
            XCTFail("not throw")
        }
        catch {
            switch error {
                
            case let e as TestError: XCTAssertEqual(e, .test2)
                
            default: XCTFail("Not test2")
            }
        }
        
        do {
            func f() throws -> Int? {
                
                throw TestError.test1
            }
            
            _ = try f() ?!! TestError.test2
            XCTFail("not throw")
        }
        catch {
            switch error {
                
            case let e as TestError: XCTAssertEqual(e, .test2)
                
            default: XCTFail("Not test2")
            }
        }
    }
    
    func testSingleExclamation() {
        
        do {
            func f() -> Int? {
                
                return 1
            }
            
            let result = try f() ??! TestError.test2
            XCTAssertEqual(result, 1)
        }
        catch {
            XCTFail("OOPs")
        }
        
        do {
            func f() -> Int? {
                
                return nil
            }
            
            _ = try f() ??! TestError.test2
            XCTFail("not throw")
        }
        catch {
            switch error {
                
            case let e as TestError: XCTAssertEqual(e, .test2)
                
            default: XCTFail("Not test2")
            }
        }
    }
}
