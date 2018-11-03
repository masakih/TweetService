//
//  OAuthSwiftClient-Future.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/07.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Foundation

import BrightFutures
import OAuthSwift


extension OAuthSwiftClient {
    
    typealias FutureResult = (future: Future<OAuthSwiftResponse, TweetServiceError>, handle: OAuthSwiftRequestHandle?)
    
    func requestFuture(_ url: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil) -> FutureResult {
        
        let promise = Promise<OAuthSwiftResponse, OAuthSwiftError>()
        let handle = request(url,
                             method: method,
                             parameters: parameters,
                             headers: headers,
                             success: { response in promise.success(response) },
                             failure: { error in promise.failure(error) })
        
        return (promise.future.mapError(convertError), handle)
    }
    
    func postImageFuture(_ urlString: String, parameters: OAuthSwift.Parameters = [:], image: Data) -> FutureResult {
        
        let promise = Promise<OAuthSwiftResponse, OAuthSwiftError>()
        let handle = postImage(urlString,
                               parameters: parameters,
                               image: image,
                               success: { response in promise.success(response) },
                               failure: { error in promise.failure(error) })
        
        return (promise.future.mapError(convertError), handle)
    }
}
