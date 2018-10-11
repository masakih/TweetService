//
//  OAuth1Swift-Future.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/11.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Foundation
import OAuthSwift

extension OAuth1Swift {
    
    func authorizeFuture(withCallbackURL: URL) -> Future<(OAuthSwiftCredential, OAuthSwiftResponse?, OAuthSwift.Parameters)> {
        
        let promise = Promise<(OAuthSwiftCredential, OAuthSwiftResponse?, OAuthSwift.Parameters)>()
        
        authorize(withCallbackURL: withCallbackURL, success: { (credential, response, parameters) in
            
            promise.success((credential, response, parameters))
            
        }, failure: { error in
            
            promise.failure(error)
        })
        
        return promise.future
    }
}
