//
//  TweetPanelController.swift
//  TwitterService
//
//  Created by Hori,Masaki on 2018/10/09.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa


// MARK: - TweetPanelController

class TweetPanelController: NSWindowController {
    
    
    // MARK: Internal
    
    var string: String {
        
        get { return text.string }
        set { text = NSAttributedString(string: newValue) }
    }
    
    var images: [NSImage] = [] {
        
        didSet { imageView?.images = images }
    }
    
    var completionHandler: ((TweetPanelController) -> Void)?
    
    var cancelHandler: ((TweetPanelController) -> Void)?
    
    
    // MARK: NSWindowController
    
    override var windowNibName: NSNib.Name {
        
        return NSNib.Name("TweetPanelController")
    }

    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        imageView?.images = self.images
    }
    
    
    // MARK: Private
    
    @objc private dynamic var text = NSAttributedString(string: "") {
        
        didSet { updateCount() }
    }
    
    @objc private dynamic var count: Int = 0
    
    @IBOutlet private weak var textView: NSTextView?
    
    @IBOutlet private weak var imageView: CascadeImageView?
    
    @IBAction private func tweet(_: Any) {
                
        completionHandler?(self)
        
        self.close()
    }
    
    @IBAction private func cancel(_: Any) {
        
        cancelHandler?(self)
        
        self.close()
    }
    
    private func updateCount() {
        
        let tweetSting = text.string
        
        count = 280 - tweetSting.utf8.count + images.count * 24
    }
}


// MARK: - NSWindowDelegate

extension TweetPanelController: NSWindowDelegate {
    
    func windowDidResignMain(_ notification: Notification) {
        
        self.window?.makeKeyAndOrderFront(nil)
    }
}
