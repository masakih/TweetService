//
//  OperationResult.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/15.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Foundation


// MARK: - OperationResult

struct OperationResult<T> {
    
    
    // MARK: - Internal
    
    enum Status {
        
        case complete, cancel
    }
    
    let host: T
    
    let status: Status
    
    init(complete host: T) {
        
        self.host = host
        self.status = .complete
    }
    
    init(cancel host: T) {
        
        self.host = host
        self.status = .cancel
    }
}
