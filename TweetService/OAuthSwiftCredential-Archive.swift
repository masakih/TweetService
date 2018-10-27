//
//  OAuthSwiftCredential-Archive.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/25.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Foundation

import OAuthSwift


extension OAuthSwiftCredential {
    
    func archive() throws -> Data {
        
        return try NSKeyedArchiver.archivedData(withRootObject: self,
                                                requiringSecureCoding: true)
            !!! TweetServiceError.couldNotArchiveCredental
    }
    
    static func unarchive(_ data: Data) throws -> OAuthSwiftCredential {
        
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: OAuthSwiftCredential.self,
                                                      from: data)
            ?!! TweetServiceError.couldNotUnarchiveCredental
    }
}
