//
//  ViewController.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/08.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

import TweetService

class ViewController: NSViewController {
    
    @IBOutlet private weak var imageView: NSImageView?
    @IBOutlet private weak var textField: NSTextField?
    
    @IBOutlet private weak var imageView2: NSImageView?
    @IBOutlet private weak var imageView3: NSImageView?
    @IBOutlet private weak var imageView4: NSImageView?
    
    @IBOutlet private weak var shareButton: NSButton!
    
    private var tweetService: TweetService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shareButton.sendAction(on: .leftMouseDown)
        
        tweetService = TweetService(callbackScheme: "hmsharing", consumerKey: twitterKeys.consumerKey, consumerSecretKey: twitterKeys.consumerSecret)
        tweetService?.delegate = self
    }
    
    @IBAction private func test(_: Any) {
        
    }
    
    @IBAction private func tweet(_ button: NSButton) {
        
        let images: [Any?] = [
            textField?.stringValue,
            imageView?.image,
            imageView2?.image,
            imageView3?.image,
            imageView4?.image,
            ]
        
        let picker = NSSharingServicePicker(items: images.compactMap( {$0 } ))
        picker.delegate = self
        picker.show(relativeTo: .zero, of: button, preferredEdge: .minX)
    }
    
    private func resetUI() {
        
        self.imageView?.image = nil
        self.imageView2?.image = nil
        self.imageView3?.image = nil
        self.imageView4?.image = nil
        
        self.textField?.stringValue = ""
    }
}

extension ViewController: NSSharingServicePickerDelegate {
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        
        guard let tweetService = self.tweetService else { return proposedServices }
        
        return tweetService.sharingServicePicker(items, proposedSharingServices: proposedServices)
    }
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, delegateFor sharingService: NSSharingService) -> NSSharingServiceDelegate? {
        
        return self
    }
}

extension ViewController: NSSharingServiceDelegate {
    
    func sharingService(_ sharingService: NSSharingService, willShareItems items: [Any]) {
        
        
    }
    
    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        
        
    }
    
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        
        print("Enter sharingService(:didShareItems:)")
    }
    
//    func sharingService(_ sharingService: NSSharingService, sourceFrameOnScreenForShareItem item: Any) -> NSRect {
//
//
//    }
    
    func sharingService(_ sharingService: NSSharingService, transitionImageForShareItem item: Any, contentRect: UnsafeMutablePointer<NSRect>) -> NSImage? {
        
        print("Enter sharingService(:transitionImageForShareItem:)")
        
        return nil
    }
    
    func sharingService(_ sharingService: NSSharingService, sourceWindowForShareItems items: [Any], sharingContentScope: UnsafeMutablePointer<NSSharingService.SharingContentScope>) -> NSWindow? {
        
        print("Enter sharingService(:sourceWindowForShareItems:sharingContentScope:)")
        
        return self.view.window
    }
    
    func anchoringView(for sharingService: NSSharingService, showRelativeTo positioningRect: UnsafeMutablePointer<NSRect>, preferredEdge: UnsafeMutablePointer<NSRectEdge>) -> NSView? {
        
        print("Enter anchoringView(for:showRelativeTo:preferredEdge:)")
        
        return self.view
    }
}

extension ViewController: TweetServiceDelegate {
    
    
    func tweetService(didSuccessAuthorize: TweetService) {
        
        print("###### Success Authorize.")
    }

    func tweetService(_ service: TweetService, didFailAuthorizeWithError error: Error) {

        print("###### Authorize Error:", error)
    }
    
//    func tweetService(_ service: TweetService, willPostItems items: [Any]) {}
    
    func tweetService(_ service: TweetService, didPostItems items: [Any]) {
        
        print("###### didPostItems")
        
        resetUI()
    }
    
    func tweetServiveDidCancel(_ service: TweetService) {
        
        print("###### Tweet did cancel")
    }
    
    func tweetService(_ service: TweetService, didFailPostItems items: [Any], error: Error) {

        print("###### Tweet Error:", error)
    }
    
    func tweetService(_ service: TweetService, sourceWindowForShareItems items: [Any]) -> NSWindow? {

        return self.view.window
    }
    
    func tweetSetviceAuthorizeSheetPearent(_ service: TweetService) -> NSViewController? {

        return self
    }
}
