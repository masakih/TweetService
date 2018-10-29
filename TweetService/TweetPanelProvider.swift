//
//  TweetPanelProvider.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/10.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

import BrightFutures

// MARK: - TweetPanelProviderError

enum TweetPanelProviderError: Error {
    
    case userCancel
}


// MARK: - TweetPanelProvider

final class TweetPanelProvider {
    
    
    // MARK: - Internal
    
    static let panelTopOffset: CGFloat = 40.0
    
    func showTweetPanelFuture(_ sourceWindow: NSWindow?, shareItems items: [Any]) -> Future<[Any], TweetPanelProviderError> {
        
        let promise = Promise<[Any], TweetPanelProviderError>()
        
        tweetPanelController = TweetPanelController()
        
        guard let panelController = tweetPanelController else {
            
            fatalError("Could not create TweetPanelController.")
        }
        
        panelController.targetWindow = sourceWindow
        panelController.showPanel(string: items.first { item in item is String } as? String ?? "",
                                  images: items.filter { item in item is NSImage } as? [NSImage] ?? [])
            .onSuccess { result in
                
                let tController = result.host
                
                switch result.status {
                    
                case .complete: promise.success(tController.images + [tController.string])
                    
                case .cancel: promise.failure(TweetPanelProviderError.userCancel)
                }
                
                self.tweetPanelController = nil
        }
        
        return promise.future
    }
    
    
    // MARK: - Private
    
    private var tweetPanelController: TweetPanelController?
}
