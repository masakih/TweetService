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
    
    func authorizeFuture(withCallbackURL: URL) -> Future<(OAuthSwiftCredential, OAuthSwiftResponse?, OAuthSwift.Parameters), TweetServiceError> {
        
        let promise = Promise<(OAuthSwiftCredential, OAuthSwiftResponse?, OAuthSwift.Parameters), OAuthSwiftError>()
        
        authorize(withCallbackURL: withCallbackURL,
                  success: { (credential, response, parameters) in promise.success((credential, response, parameters)) },
                  failure: promise.failure)
        
        return promise.future.mapError(convertError)
    }
}
