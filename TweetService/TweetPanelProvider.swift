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

class TweetPanelProvider {
    
    
    // MARK: Internal
    
    func showTweetPanel(_ sourceWindow: NSWindow?, shareItems items: [Any], completionHandler: @escaping ([Any]) -> Void, cancelHandler: @escaping () -> Void) {
        
        tweetPanelController = TweetPanelController()
        
        guard let panelController = tweetPanelController else { return }
        
        panelController.string = items.first { item in item is String } as? String ?? ""
        panelController.images = items.filter { item in item is NSImage } as? [NSImage] ?? []
        
        panelController.completionHandler = { tController in
            
            completionHandler(tController.images + [tController.string])
            
            self.closeBlurIfNeed(sourceWindow, tweetPanelController: tController)
            
            self.tweetPanelController = nil
        }
        
        panelController.cancelHandler = { tController in
            
            cancelHandler()
            
            self.closeBlurIfNeed(sourceWindow, tweetPanelController: tController)
            
            self.tweetPanelController = nil
        }
        
        showBlurIfNeed(sourceWindow, tweetPanelController: panelController)
        panelController.showWindow(self)
    }
    
    func showTweetPanelFuture(_ sourceWindow: NSWindow?, shareItems items: [Any]) -> Future<[Any]> {
        
        let promise = Promise<[Any]>()
        
        showTweetPanel(sourceWindow,
                       shareItems: items,
                       completionHandler: { items in promise.success(items) },
                       cancelHandler: { promise.failure(TweetPanelProviderError.userCancel) })
        
        return promise.future
    }
    
    
    // MARK: - Private
    
    private static let panelTopOffset: CGFloat = 40.0
    
    private var tweetPanelController: TweetPanelController?
    
    private func showBlurIfNeed(_ window: NSWindow?, tweetPanelController: TweetPanelController) {
        
        if let window = window, let panelWindow = tweetPanelController.window {
            
            let targetFrame = window.frame
            
            let blurWindowController = BlurWindowController()
            blurWindowController.window?.addChildWindow(window, ordered: .below)
            blurWindowController.window?.setFrame(targetFrame, display: false)
            blurWindowController.showWindow(self)
            
            var panelFrame = panelWindow.frame
            panelFrame.origin.x = targetFrame.origin.x + (targetFrame.width - panelFrame.width) / 2
            panelFrame.origin.y = targetFrame.origin.y + (targetFrame.height - panelFrame.height) / 2 + type(of: self).panelTopOffset
            
            panelWindow.setFrame(panelFrame, display: false)
            panelWindow.addChildWindow(blurWindowController.window!, ordered: .below)
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
}