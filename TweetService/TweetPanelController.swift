//
//  TweetPanelController.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/09.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

import BrightFutures
import TwitterText


// MARK: - TweetPanelController

final class TweetPanelController: NSWindowController {
    
    
    // MARK: - Internal
    
    var string: String { return text.string }
    
    var images: [NSImage] = [] {
        
        didSet { imageView?.images = images }
    }
    
    weak var targetWindow: NSWindow?
    
    
    // MARK: - NSWindowController
    
    override var windowNibName: NSNib.Name {
        
        return NSNib.Name("TweetPanelController")
    }

    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        replaceContentView()
        
        imageView?.images = self.images
    }
    
    /// Show Tweet Panel.
    ///
    /// - Parameters:
    ///   - string: initial string
    ///   - images: initial images
    /// - Returns: Future of OperationResult of TweetPanelController. This future will always success.
    func showPanel(string: String, images: [NSImage]) -> Future<OperationResult<TweetPanelController>, NSError> {
        
        text = NSAttributedString(string: string)
        self.images = images
        
        promise = Promise()
        
        showBlurIfNeed()
        showWindow(nil)
        
        return promise!.future
    }
    
    
    // MARK: - Private
    
    @objc private dynamic var text = NSAttributedString(string: "") {
        
        didSet {
            
            parseResult = twitterTextParser.parseTweet(text.string)
        }
    }
    
    @objc private dynamic var count: Int = 0
    
    @objc private dynamic var canTweet: Bool = false
    
    @IBOutlet private weak var textView: NSTextView?
    
    @IBOutlet private weak var imageView: CascadeImageView?
    
    private lazy var twitterTextParser: TwitterTextParser = {
        
        TwitterTextParser.defaultParser()
        
    }()
    
    private var parseResult: TwitterTextParseResults? {
        
        didSet {
            
            guard let result = parseResult else { return }
            
            count = result.weightedLength
            canTweet = result.isValid
        }
    }
    
    private var promise: Promise<OperationResult<TweetPanelController>, NSError>?
    
    @IBAction private func tweet(_: Any) {
        
        promise?.success(OperationResult(complete: self))
        
        self.close()
    }
    
    @IBAction private func cancel(_: Any) {
        
        promise?.success(OperationResult(cancel: self))
        
        self.close()
    }
    
    private func replaceContentView() {
        
        guard let contentView = window?.contentView else {
            
            fatalError("Not exist window's content view")
        }
        
        let newContentView = NSVisualEffectView(frame: contentView.frame)
        contentView.subviews.forEach(newContentView.addSubview)
        window?.contentView = newContentView
    }
    
    private func showBlurIfNeed() {
        
        guard let targetWindow = targetWindow, let window = window else {
            
            self.window?.center()
            
            return
        }
        
        let targetFrame = targetWindow.frame
        
        let blurWindowController = BlurWindowController()
        blurWindowController.window?.addChildWindow(targetWindow, ordered: .below)
        blurWindowController.window?.setFrame(targetFrame, display: false)
        blurWindowController.targetWindow = targetWindow
        blurWindowController.showWindow(nil)
        
        var panelFrame = window.frame
        panelFrame.origin.x = targetFrame.origin.x + (targetFrame.width - panelFrame.width) / 2
        panelFrame.origin.y = targetFrame.origin.y + (targetFrame.height - panelFrame.height) / 2 + TweetPanelProvider.panelTopOffset
        
        window.setFrame(panelFrame, display: false)
        window.addChildWindow(blurWindowController.window!, ordered: .below)
    }
    
    private func closeBlurIfNeed() {
        
        guard let targetWindow = targetWindow,
            let window = window,
            let blurWindow = targetWindow.parent else {
                
                return
        }
        
        blurWindow.removeChildWindow(targetWindow)
        
        window.removeChildWindow(blurWindow)
        blurWindow.close()
    }
}


// MARK: - NSWindowDelegate

extension TweetPanelController: NSWindowDelegate {
    
    func windowDidResignMain(_ notification: Notification) {
        
        self.window?.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        
        closeBlurIfNeed()
    }
}
