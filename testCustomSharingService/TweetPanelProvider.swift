//
//  TweetPanelProvider.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/10.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

enum TweetPanelProviderError: Error {
    
    case userCancel
}

class TweetPanelProvider {
    
    private var tweetPanel: TweetPanelController?
    
    func showTweetPanel(_ sourceWindow: NSWindow?, shareItems items: [Any], completionHandler: @escaping ([Any]) -> Void, cancelHandler: @escaping () -> Void) {
        
        tweetPanel = TweetPanelController()
        
        guard let panel = tweetPanel else { return }
        
        panel.string = items.first(where: { item in item is String }) as? String ?? ""
        panel.images = items.filter({ item in item is NSImage }) as? [NSImage] ?? []
        
        if let window = sourceWindow, let panelWindow = panel.window {
            
            let targetFrame = window.frame
            
            let blurWindowController = BlurWindowController()
            blurWindowController.window?.addChildWindow(window, ordered: .below)
            blurWindowController.window?.setFrame(targetFrame, display: false)
            
            blurWindowController.showWindow(self)
            
            var panelFrame = panelWindow.frame
            
            panelFrame.origin.x = targetFrame.origin.x + (targetFrame.width - panelFrame.width) / 2
            panelFrame.origin.y = targetFrame.origin.y + (targetFrame.height - panelFrame.height) / 2 + 40
            
            panelWindow.setFrame(panelFrame, display: false)
            
            panelWindow.addChildWindow(blurWindowController.window!, ordered: .below)
        }
        
        panel.completionHandler = { tController in
            
            completionHandler(tController.images + [tController.string])
            
            if let window = sourceWindow, let panelWindow = panel.window, let blurWindow = window.parent {
                
                blurWindow.removeChildWindow(window)
                
                panelWindow.removeChildWindow(blurWindow)
                blurWindow.close()
            }
            
            self.tweetPanel = nil
        }
        panel.cancelHandler = { _ in
            
            cancelHandler()
            
            if let window = sourceWindow, let panelWindow = panel.window, let blurWindow = window.parent {
                
                blurWindow.removeChildWindow(window)
                
                panelWindow.removeChildWindow(blurWindow)
                blurWindow.close()
            }
            
            
            self.tweetPanel = nil
        }
        
        panel.showWindow(self)
    }
    
    func showTweetPanelFuture(_ sourceWindow: NSWindow?, shareItems items: [Any]) -> Future<[Any]> {
        
        let promise = Promise<[Any]>()
        
        showTweetPanel(sourceWindow, shareItems: items, completionHandler: { items in
            
            promise.success(items)
            
        }, cancelHandler: {
            
            promise.failure(TweetPanelProviderError.userCancel)
        })
        
        return promise.future
    }
    
}
