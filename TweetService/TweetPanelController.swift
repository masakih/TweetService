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
    
    var string: String { return text.string }
    
    var images: [NSImage] = [] {
        
        didSet { imageView?.images = images }
    }
    
    // MARK: NSWindowController
    
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
    func showPanel(string: String, images: [NSImage]) -> Future<OperationResult<TweetPanelController>> {
        
        text = NSAttributedString(string: string)
        self.images = images
        
        promise = Promise()
        
        showWindow(nil)
        
        return promise!.future
    }
    
    
    // MARK: Private
    
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
    
    private var promise: Promise<OperationResult<TweetPanelController>>?
    
    @IBAction private func tweet(_: Any) {
        
        promise?.complete(.value(OperationResult(complete: self)))
        
        self.close()
    }
    
    @IBAction private func cancel(_: Any) {
        
        promise?.complete(.value(OperationResult(cancel: self)))
        
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
}


// MARK: - NSWindowDelegate

extension TweetPanelController: NSWindowDelegate {
    
    func windowDidResignMain(_ notification: Notification) {
        
        self.window?.makeKeyAndOrderFront(nil)
    }
}
