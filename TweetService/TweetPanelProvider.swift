//
//  TweetPanelProvider.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/10.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa


// MARK: - TweetPanelProviderError

enum TweetPanelProviderError: Error {
    
    case userCancel
}


// MARK: - TweetPanelProvider

final class TweetPanelProvider {
    
    
    // MARK: - Internal
    
    static let panelTopOffset: CGFloat = 40.0
    
    func showTweetPanelFuture(_ sourceWindow: NSWindow?, shareItems items: [Any]) -> Future<[Any]> {
        
        let promise = Promise<[Any]>()
        
        tweetPanelController = TweetPanelController()
        
        guard let panelController = tweetPanelController else {
            
            fatalError("Could not create TweetPanelController.")
        }
        
        showBlurIfNeed(sourceWindow, tweetPanelController: panelController)
        panelController.showPanel(string: items.first { item in item is String } as? String ?? "",
                                  images: items.filter { item in item is NSImage } as? [NSImage] ?? [])
            .onSuccess { result in
                
                let tController = result.host
                
                switch result.status {
                    
                case .complete: promise.success(tController.images + [tController.string])
                    
                case .cancel: promise.failure(TweetPanelProviderError.userCancel)
                }
                
                closeBlurIfNeed(sourceWindow, tweetPanelController: tController)
                self.tweetPanelController = nil
        }
        
        return promise.future
    }
    
    
    // MARK: - Private
    
    private var tweetPanelController: TweetPanelController?
}


// MARK: - Private

private func showBlurIfNeed(_ window: NSWindow?, tweetPanelController: TweetPanelController) {
    
    DispatchQueue.main.async {
        
        if let window = window, let panelWindow = tweetPanelController.window {
            
            let targetFrame = window.frame
            
            let blurWindowController = BlurWindowController()
            blurWindowController.window?.addChildWindow(window, ordered: .below)
            blurWindowController.window?.setFrame(targetFrame, display: false)
            blurWindowController.targetWindow = window
            blurWindowController.showWindow(nil)
            
            var panelFrame = panelWindow.frame
            panelFrame.origin.x = targetFrame.origin.x + (targetFrame.width - panelFrame.width) / 2
            panelFrame.origin.y = targetFrame.origin.y + (targetFrame.height - panelFrame.height) / 2 + TweetPanelProvider.panelTopOffset
            
            panelWindow.setFrame(panelFrame, display: false)
            panelWindow.addChildWindow(blurWindowController.window!, ordered: .below)
        }
    }
}

private func closeBlurIfNeed(_ window: NSWindow?, tweetPanelController: TweetPanelController) {
    
    if let window = window,
        let panelWindow = tweetPanelController.window,
        let blurWindow = window.parent {
        
        blurWindow.removeChildWindow(window)
        
        panelWindow.removeChildWindow(blurWindow)
        blurWindow.close()
    }
}

