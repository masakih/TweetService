//
//  CustomOperator.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/27.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//


precedencegroup ThrowPrecedence {
    associativity: left
    higherThan: NilCoalescingPrecedence
}
infix operator !!! : ThrowPrecedence
infix operator ?!! : ThrowPrecedence
infix operator ??! : ThrowPrecedence


/// 左辺値が例外を投げた場合に右辺値の例外を投げる
///
/// - Parameters:
///   - value: 例外が発生しうる値
///   - throwsError: 投げられる例外
/// - Returns: 例外が発生しなければ左辺値
/// - Throws: 右辺値の例外が投げられる
func !!! <T, E: Error> (_ value: @autoclosure () throws -> T, _ throwsError: E) throws -> T {
    
    do {
        
        return try value()
    }
    catch {
        
        throw throwsError
    }
}


/// 左辺値がnilまたは例外を投げた場合に右辺値の例外を投げる
///
/// - Parameters:
///   - optionalValue: nilまたは例外が発生しうる値
///   - throwsError: 投げられる例外
/// - Returns: 例外が発生しなく、かつnilでなければ左辺値
/// - Throws: 右辺値の例外が投げられる
func ?!! <T, E: Error> (_ optionalValue: @autoclosure () throws -> T?, _ throwsError: E) throws -> T {
    
    guard let returnValue = try optionalValue() !!! throwsError else {
        
        throw throwsError
    }
    
    return returnValue
}


/// 左辺値がnilならば右辺値の例外を投げる
///
/// - Parameters:
///   - optionalValue: nilになりうる値
///   - throwsError: 投げられる例外
/// - Returns: nilでなければ左辺値
/// - Throws: 右辺値の例外が投げられる
func ??! <T, E: Error> (_ optionalValue: @autoclosure () -> T?, _ throwsError: E) throws -> T {
    
    return try optionalValue() ?!! throwsError
}
