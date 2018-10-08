//
//  OAuthSwiftClient-Future.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/07.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Foundation
import OAuthSwift

extension OAuthSwiftClient {
    
    typealias FutureSuccess = OAuthSwiftResponse
    typealias FutureError = OAuthSwiftError
    typealias FutureResult = (future: Future<FutureSuccess>, handle: OAuthSwiftRequestHandle?)
    
    func requestFuture(_ url: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil) -> FutureResult {
        
        let promise = Promise<FutureSuccess>()
        let handle = request(
            url, method: method, parameters: parameters, headers: headers,
            success: { response in
                promise.success(response)
        },
            failure: { error in
                promise.failure(error)
        }
        )
        
        return (promise.future, handle)
    }
    
    func postImageFuture(_ urlString: String, parameters: OAuthSwift.Parameters, image: Data) -> FutureResult {
        
        let promise = Promise<FutureSuccess>()
        
        let handle = postImage(
            urlString, parameters: parameters, image: image,
            success: { response in
                promise.success(response)
        },
            failure: { error in
                promise.failure(error)
        }
        )
        return (promise.future, handle)
    }
}
