//
//  ViewController.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/08.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa
import OAuthSwift

class ViewController: OAuthWebViewController {
    
    @IBOutlet private weak var imageView: NSImageView?
    @IBOutlet private weak var textField: NSTextField?
    
    @IBOutlet private weak var imageView2: NSImageView?
    @IBOutlet private weak var imageView3: NSImageView?
    @IBOutlet private weak var imageView4: NSImageView?
    
    @IBOutlet private weak var shareButton: NSButton!
    
    private var oauthswift: OAuth1Swift?
    private let webViewController = AuthWebViewController()
    
    private var tweetService: TweetService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shareButton.sendAction(on: .leftMouseDown)
        
        oauthswift = OAuth1Swift(
            consumerKey:    twitterKeys.consumerKey,
            consumerSecret: twitterKeys.consumerSecret,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authenticate",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        
        oauthswift?.authorizeURLHandler = webViewController
        webViewController.delegate = self
        self.addChildViewController(webViewController)
        
        tweetService = TweetService(oauthswift: oauthswift!)
        tweetService?.delegate = self
    }
    
    @IBAction private func authorize(_: Any) {
        
        _ = oauthswift?.authorize(
            withCallbackURL: URL(string: "hmsharing://oauth-callback/twitter")!,
            success: { credential, response, parameters in },
            failure: { error in
                print(error.localizedDescription)
        })
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

extension ViewController: OAuthWebViewControllerDelegate {
    
    func oauthWebViewControllerWillAppear() {}
    func oauthWebViewControllerDidAppear() {}
    func oauthWebViewControllerWillDisappear() {}
    func oauthWebViewControllerDidDisappear() {
        // Ensure all listeners are removed if presented web view close
        oauthswift?.cancel()
        
        self.addChildViewController(webViewController)
    }
}

extension ViewController: NSSharingServicePickerDelegate {
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        
        guard let tweetService = self.tweetService else { return proposedServices }
        
        return tweetService.sharingServicePicker(items, proposedSharingServices: proposedServices)
    }
}

extension ViewController: TweetServiceDelegate {
    
    func tweetService(_ service: TweetService, willPostItems items: [Any]) {}
    
    func tweetService(_ service: TweetService, didPostItems items: [Any]) {
        
        resetUI()
    }
    
    func tweetService(_ service: TweetService, didFailPostItems items: [Any], error: Error) {
        
        print("Tweet Error:", error)
    }
}
