//
//  Future.swift
//  KCD
//
//  Created by Hori,Masaki on 2018/01/13.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

import Cocoa

enum Result<T> {
    
    case value(T)
    
    case error(Error)
    
//    init(_ value: T) {
//
//        self = .value(value)
//    }
//
//    init(_ error: Error) {
//
//        self = .error(error)
//    }
}
extension Result {
    
    var value: T? {
        
        if case let .value(value) = self { return value }
        
        return nil
    }
    
    var error: Error? {
        
        if case let .error(error) = self { return error }
        
        return nil
    }
}

enum FutureError: Error {
    
    case unsolvedFuture
    
    case noSuchElement
}

final class Future<T> {
    
    private let semaphore: DispatchSemaphore?
    
    private var callbacks: [(Result<T>) -> Void] = []
    
    fileprivate var result: Result<T>? {
        
        willSet {
            
            if result != nil {
                
                fatalError("Result already seted.")
            }
        }
        
        didSet {
            
            guard let result = self.result else {
                
                fatalError("set nil to result.")
            }
            
            callbacks.forEach { f in f(result) }
            callbacks = []
            
            semaphore?.signal()
        }
    }
    
    var isCompleted: Bool {
        
        return result != nil
    }
    
    var value: Result<T>? {
        
        return result
    }
    
    /// Life cycle
    init() {
        
        // for await()
        semaphore = DispatchSemaphore(value: 0)
    }
    
    init(in queue: DispatchQueue = .global(), _ block: @escaping () throws -> T) {
        
        // for await()
        semaphore = DispatchSemaphore(value: 0)
        
        queue.async {
            
            defer { self.semaphore?.signal() }
            
            do {
                
                self.result = .value(try block())
                
            } catch {
                
                self.result = .error(error)
            }
        }
    }
    
    init(_ result: Result<T>) {
        
        semaphore = nil
        
        self.result = result
    }
    
    convenience init(_ value: T) {
        
        self.init(.value(value))
    }
    
    convenience init(_ error: Error) {
        
        self.init(.error(error))
    }
    
    deinit {
        
        semaphore?.signal()
    }
}

extension Future {
    
    ///
    @discardableResult
    func await() -> Self {
        
        if result == nil {
            
            semaphore?.wait()
            semaphore?.signal()
        }
        
        return self
    }
    
    @discardableResult
    func onComplete(_ callback: @escaping (Result<T>) -> Void) -> Self {
        
        if let r = result {
            
            callback(r)
            
        } else {
            
            callbacks.append(callback)
        }
        
        return self
    }
    
    @discardableResult
    func onSuccess(_ callback: @escaping (T) -> Void) -> Self {
        
        onComplete { result in
            
            if case let .value(v) = result {
                
                callback(v)
            }
        }
        
        return self
    }
    
    @discardableResult
    func onFailure(_ callback: @escaping (Error) -> Void) -> Self {
        
        onComplete { result in
            
            if case let .error(e) = result {
                
                callback(e)
            }
        }
        
        return self
    }
}

extension Future {
    
    ///
    func transform<U>(_ s: @escaping (T) -> U, _ f: @escaping (Error) -> Error) -> Future<U> {
        
        return transform { result in
            
            switch result {
                
            case let .value(value): return .value(s(value))
                
            case let .error(error): return .error(f(error))
                
            }
        }
    }
    
    func transform<U>(_ s: @escaping (Result<T>) -> Result<U>) ->Future<U> {
        
        return Promise()
            .complete {
                
                self.await().value.map(s) ?? .error(FutureError.unsolvedFuture)
            }
            .future
    }
    
    func map<U>(_ t: @escaping (T) -> U) -> Future<U> {
        
        return transform(t, { $0 })
    }
    
    func flatMap<U>(_ t: @escaping (T) -> Future<U>) -> Future<U> {
        
        return Promise()
            .completeWith {
                
                switch self.await().value {
                    
                case .value(let v)?: return t(v)
                    
                case .error(let e)?: return Future<U>(e)
                    
                case nil: fatalError("Future not complete")
                    
                }
            }
            .future
    }
    
    func filter(_ f: @escaping (T) -> Bool) -> Future<T> {
        
        return Promise()
            .complete {
                
                if case let .value(v)? = self.await().value, f(v) {
                    
                    return .value(v)
                }
                
                return .error(FutureError.noSuchElement)
            }
            .future
    }
    
    func recover(_ s: @escaping (Error) throws -> T) -> Future<T> {
        
        return transform { result in
            
            do {
                
                return try result.error.map { error in .value(try s(error)) } ?? .error(FutureError.unsolvedFuture)
                
            } catch {
                
                return .error(error)
            }
        }
    }
    
    @discardableResult
    func andThen(_ f: @escaping (Result<T>) -> Void) -> Future<T> {
        
        return Promise<T>()
            .complete {
                
                guard let result = self.await().result else {
                    
                    fatalError("Future not complete")
                }
                
                f(result)
                
                return result
            }
            .future
    }
}

private extension Future {
    
    func complete(_ result: Result<T>) {
        
        self.result = result
    }
}

private let promiseQueue = DispatchQueue(label: "Promise", attributes: .concurrent)
final class Promise<T> {
    
    let future: Future<T> = Future<T>()
    
    ///
    func complete(_ result: Result<T>) {
        
        future.complete(result)
    }
    
    func success(_ value: T) {
        
        complete(.value(value))
    }
    
    func failure(_ error: Error) {
        
        complete(.error(error))
    }
    
    func complete(_ completor: @escaping () -> Result<T>) -> Self {
        
        promiseQueue.async {
            
            self.complete(completor())
        }
        
        return self
    }
    
    func completeWith(_ completor: @escaping () -> Future<T>) -> Self {
        
        promiseQueue.async {
            
            completor()
                .onSuccess {
                    
                    self.success($0)
                    
                }
                .onFailure {
                    
                    self.failure($0)
                    
            }
        }
        
        return self
    }
}
