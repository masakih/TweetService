//
//  TweetPanelController.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/09.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

import TwitterText


// MARK: - TweetPanelController

final class TweetPanelController: NSWindowController {
    
    
    // MARK: Internal
    
    private lazy var twitterTextParser: TwitterTextParser = {
        
        TwitterTextParser.defaultParser()
        
    }()
    
    var string: String { return text.string }
    
    var images: [NSImage] = [] {
        
        didSet { imageView?.images = images }
    }
    
    deinit {
        
        progress?.unbind(NSBindingName("current"))
    }
    
    // MARK: NSWindowController
    
    override var windowNibName: NSNib.Name {
        
        return NSNib.Name("TweetPanelController")
    }

    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        imageView?.images = self.images
        
        progress?.max = 280
        progress?.bind(NSBindingName("current"),
                       to: self,
                       withKeyPath: "count",
                       options: nil)
    }
    
    /// Show Tweet Panel.
    ///
    /// - Parameters:
    ///   - string: initial string
    ///   - images: initial images
    /// - Returns: Future of OperationResult of TweetPanelController. This future will always success.
    func showPanel(string: String, images: [NSImage]) -> Future<OperationResult<TweetPanelController>> {
        
        text = NSAttributedString(string: string)
        self.images = images
        
        promise = Promise()
        
        showWindow(nil)
        
        return promise!.future
    }
    
    
    // MARK: Private
    
    @objc private dynamic var text = NSAttributedString(string: "") {
        
        didSet { updateCount() }
    }
    
    @objc private dynamic var count: Int = 0
    
    @IBOutlet private weak var textView: NSTextView?
    
    @IBOutlet private weak var imageView: CascadeImageView?
    
    @IBOutlet private weak var progress: CharactorCounter?
    
    private var promise: Promise<OperationResult<TweetPanelController>>?
    
    @IBAction private func tweet(_: Any) {
        
        promise?.complete(.value(OperationResult(complete: self)))
        
        self.close()
    }
    
    @IBAction private func cancel(_: Any) {
        
        promise?.complete(.value(OperationResult(cancel: self)))
        
        self.close()
    }
    
    private func updateCount() {
        
        let tweetSting = text.string
        
        let tResult = twitterTextParser.parseTweet(tweetSting)
                
        count = 280 - tResult.weightedLength
    }
}


// MARK: - NSWindowDelegate

extension TweetPanelController: NSWindowDelegate {
    
    func windowDidResignMain(_ notification: Notification) {
        
        self.window?.makeKeyAndOrderFront(nil)
    }
}
