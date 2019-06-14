//
//  OAuth1Swift-Future.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/11.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Foundation

import BrightFutures
import OAuthSwift

extension OAuth1Swift {
    
    func authorizeFuture(withCallbackURL url: URL) -> Future<TokenSuccess, TweetServiceError> {
        
        let promise = Promise<TokenSuccess, OAuthSwiftError>()
        
        authorize(withCallbackURL: url, completionHandler: promise.complete)
        
        return promise.future.mapError(convertError)
    }
}
