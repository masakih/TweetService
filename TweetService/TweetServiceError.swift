//
//  TweetServiceError.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/21.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import KeychainAccess
import OAuthSwift


// MARK: - TweetServiceError

public enum TweetServiceError: Error {
    
    case notAuthorized
    
    case userCancel
    
    case failAuthorize
    
    case couldNotParseJSON
    
    case jsonNotDictionary
    
    case notContainsMediaId
    
    case credentalNotStoreInKeychain
    
    case couldNotArchiveCredental
    
    case couldNotUnarchiveCredental
    
    case keychainAccessInternal
    
    case tokenExpired
    
    case missingToken
    
    case authorizationPending
    
    case requestError(error: Error, request: URLRequest)
    
    case twitterError(message: String, code: Int)
    
    case canNotCreateDataFromNSImage
        
    case unknownError(Error)
}


// MARK: - Internal

func twitterError(_ error: TweetServiceError) -> TweetServiceError? {
    
    if case let .requestError(nserror as NSError, _) = error,
        let resData = nserror.userInfo[OAuthSwiftError.ResponseDataKey] as? Data,
        let json = try? JSONSerialization.jsonObject(with: resData, options: .allowFragments) as? [String: Any],
        let errors = json["errors"] as? [[String: Any]],
        let firstError = errors.first,
        let message = firstError["message"] as? String,
        let code = firstError["code"] as? Int {
        
        return .twitterError(message: message, code: code)
    }
    
    return nil
}

func convertError(_ error: Error) -> TweetServiceError {
    
    if let error = error as? TweetServiceError {
        
        return error
    }
    
    if let error = error as? TweetPanelProviderError, error == .userCancel {
        
        return .userCancel
    }
    
    if error is KeychainAccess.Status {
        
        return .keychainAccessInternal
    }
    
    guard let oauthError = error as? OAuthSwiftError else { return .unknownError(error) }
    
    switch oauthError {
        
    case .configurationError: fatalError("unreached configurationError")
        
    case .tokenExpired: return .tokenExpired
        
    case .missingState: fatalError("unreached missingState")
        
    case .stateNotEqual: fatalError("unreached stateNotEqual")
        
    case .serverError: fatalError("unreached serverError")
        
    case .encodingError: fatalError("unreached encodingError")
        
    case .authorizationPending: return .authorizationPending
        
    case .requestCreation: fatalError("unreached requestCreation")
        
    case .missingToken: return .missingToken
        
    case .retain: fatalError("unreached retain")
        
    case let .requestError(err, request): return .requestError(error: err, request: request)
        
    case .cancelled: fatalError("unreached cancelled")
        
    case .slowDown(let error, let request): fatalError("slowDown: \(error), \(request)")
        
    case .accessDenied(let error, let request): fatalError("accessDenied: \(error), \(request)")
    }
}
