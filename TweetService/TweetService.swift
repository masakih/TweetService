//
//  TweetService.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/08.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

import OAuthSwift


// MARK: - TweetServiceDelegate

public protocol TweetServiceDelegate: class {
    
    func tweetService(didSuccessAuthorize: TweetService)
    
    func tweetService(_ service: TweetService, didFailAuthorizeWithError error: Error)
    
    func tweetService(_ service: TweetService, willPostItems items: [Any])
    
    func tweetService(_ service: TweetService, didPostItems items: [Any])
    
    func tweetServiveDidCancel(_ service: TweetService)
    
    func tweetService(_ service: TweetService, didFailPostItems items: [Any], error: Error)
    
    
    func tweetService(_ service: TweetService, sourceWindowForShareItems items: [Any]) -> NSWindow?
    
    func tweetSetviceAuthorizeSheetPearent(_ service: TweetService) -> NSViewController?
}

public extension TweetServiceDelegate {
    
    func tweetService(didSuccessAuthorize: TweetService) {}
    
    func tweetService(_ service: TweetService, didFailAuthorizeWithError error: Error) {}
    
    func tweetService(_ service: TweetService, willPostItems items: [Any]) {}
    
    func tweetService(_ service: TweetService, didPostItems items: [Any]) {}
    
    func tweetServiveDidCancel(_ service: TweetService) {}
    
    func tweetService(_ service: TweetService, didFailPostItems items: [Any], error: Error) {}
    
    
    func tweetService(_ service: TweetService, sourceWindowForShareItems items: [Any]) -> NSWindow? {
        
        return nil
    }
    
    func tweetSetviceAuthorizeSheetPearent(_ service: TweetService) -> NSViewController? {
        
        return nil
    }
}


// MARK: - TweetServiceError

public enum TweetServiceError: Error {
    
    case jsonNotDictionary
    
    case notContainsMediaId
    
    case twitterError(message: String, code: Int)
}


// MARK: - TweetService

public class TweetService {
    
    
    // MARK: Public
    
    public var seriviceName: String = "Tweet"
    
    public var serviceImage: NSImage = defaultServiceImage()
    
    public var alternateImage: NSImage?
    
    public weak var delegate: TweetServiceDelegate?
    
    public init(callbackScheme: String, consumerKey: String, consumerSecretKey: String) {
        
        self.webViewController = AuthWebViewController(callbackScheme: callbackScheme)
        
        self.callbackScheme = callbackScheme
        
        self.oauthswift = makeOAuth1Swift(consumerKey: consumerKey, consumerSecretKey: consumerSecretKey)
        
    }
    
    public func sharingServicePicker(_ items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        
        guard canTweet(items: items) else { return proposedServices }
        
        let service = NSSharingService(title: seriviceName, image: serviceImage, alternateImage: alternateImage) {
            
            self.tweet(items: items)
        }
        
        return [service] + proposedServices
    }
    
    
    // MARK: Private
    
    private var oauthswift: OAuth1Swift
    
    private var didAuthrized = false
    
    private let callbackScheme: String
    
    private let webViewController: AuthWebViewController
    
    private let tweetPanelProvider = TweetPanelProvider()
    
    private func canTweet(items: [Any]) -> Bool {
        
        // check String or Image
        guard items.first(where: { item in !(item is String) && !(item is NSImage) }) == nil else {
            
            return false
        }
        
        // check Image count
        let images = items.filter { item in item is NSImage }
        guard images.count < 5 else { return false }
        
        // check String count
        let strings = items.filter { item in item is String }
        guard strings.count < 2 else { return false }
        
        return true
    }
    
    private func tweet(items: [Any]) {
        
        guard didAuthrized else {
            
            authorizeAndTweet(items)
            
            return
        }
        
        tweetPanelProvider
            .showTweetPanelFuture(self.delegate?.tweetService(self, sourceWindowForShareItems: items), shareItems: items)
            .onSuccess { items in self.tweetFromPanel(items: items) }
            .onFailure { _ in self.delegate?.tweetServiveDidCancel(self) }
    }
    
    private func authorizeAndTweet(_ items: [Any]) {
        
        oauthswift.authorizeURLHandler = webViewController
        webViewController.delegate = self
        authorizePanelParent(for: items).addChildViewController(webViewController)
        
        oauthswift
            .authorizeFuture(withCallbackURL: URL(string: callbackScheme + "://oauth-callback/twitter")!)
            .onSuccess { _,_,_ in
                
                self.didAuthrized = true
                self.delegate?.tweetService(didSuccessAuthorize: self)
                
                self.tweet(items: items)
            }
            .onFailure { error in
                
                // error is always OAuthSwiftError.
                let error = error as! OAuthSwiftError
                
                if case .missingToken = error {
                    
                    self.oauthswift = makeOAuth1Swift(consumerKey: self.oauthswift.client.credential.consumerKey,
                                                      consumerSecretKey: self.oauthswift.client.credential.consumerSecret)
                    
                    self.delegate?.tweetServiveDidCancel(self)
                    
                    return
                }
                
                self.delegate?.tweetService(self, didFailAuthorizeWithError: error)
        }
    }
    
    private func authorizePanelParent(for items: [Any]) -> NSViewController {
        
        if let viewController = self.delegate?.tweetSetviceAuthorizeSheetPearent(self) {
            
            return viewController
        }
        
        if let viewController = self.delegate?.tweetService(self, sourceWindowForShareItems: items)?.contentViewController {
            
            return viewController
        }
        
        fatalError("TweetServiceDelegate must provide tweetSetviceAuthorizeSheetPearent or sourceWindowForShareItems must has contentViewController")
    }
    
    private func tweetFromPanel(items: [Any]) {
        
        delegate?.tweetService(self, willPostItems: items)
        
        let text = items.first{ item in item is String } as? String ?? ""
        let images = items.filter { item in item is NSImage } as? [NSImage] ?? []
        
        uploadImage(images: images)
            .flatMap { (_, mediaIds) -> Future<OAuthSwiftResponse> in
                
                let mediaIDsString = mediaIds.joined(separator: ",")
                let params: OAuthSwift.Parameters
                switch mediaIDsString {
                    
                case "": params = ["status": text]
                    
                default: params = ["status": text, "media_ids": mediaIDsString]
                }
                
                return self.oauthswift
                    .client
                    .requestFuture("https://api.twitter.com/1.1/statuses/update.json",
                                   method: .POST,
                                   parameters: params)
                    .future
            }
            .onSuccess { _ in
                
                self.delegate?.tweetService(self, didPostItems: items)
            }
            .onFailure { error in
                
                if let (message, code) = twitterError(error) {
                    
                    self.delegate?.tweetService(self, didFailPostItems: items,
                                                error: TweetServiceError.twitterError(message: message, code: code))
                    
                    return
                }
                
                self.delegate?.tweetService(self, didFailPostItems: items, error: error)
        }
    }
    
    private func uploadImage(images: [NSImage], mediaIds: [String] = []) -> Future<(images: [NSImage], mediaIds: [String])> {
        
        guard let image = images.first else {
            
            return Future((images, mediaIds))
        }
        
        guard let imageData = jpegData(image) else {
            
            return Future((Array(images.dropFirst()), mediaIds))
        }
        
        let promise = Promise<([NSImage], [String])>()
        
        oauthswift
            .client
            .postImageFuture("https://upload.twitter.com/1.1/media/upload.json", image: imageData)
            .future
            .onSuccess { response in
                
                do {
                    
                    let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments)
                    guard let dict = json as? [String: Any] else {
                        
                        throw TweetServiceError.jsonNotDictionary
                    }
                    
                    guard let mediaId = dict["media_id_string"] as? String else {
                        
                        throw TweetServiceError.notContainsMediaId
                    }
                    
                    promise.success((Array(images.dropFirst()) , mediaIds + [mediaId]))
                    
                } catch {
                    
                    promise.failure(error)
                }
            }
            .onFailure { error in
                
                if let (message, code) = twitterError(error) {
                    
                    promise.failure(TweetServiceError.twitterError(message: message, code: code))
                    
                } else {
                    
                    promise.failure(error)
                }
        }
        
        return promise.future.flatMap(uploadImage)
    }
}


// MARK: - OAuthWebViewControllerDelegate

extension TweetService: OAuthWebViewControllerDelegate {
    
    public func oauthWebViewControllerWillAppear() {}
    public func oauthWebViewControllerDidAppear() {}
    public func oauthWebViewControllerWillDisappear() {}
    public func oauthWebViewControllerDidDisappear() {
        // Ensure all listeners are removed if presented web view close
        oauthswift.cancel()
    }
}


// MARK: - Private

private func defaultServiceImage() -> NSImage {
    
    let image = NSImage(size: NSSize(width: 100, height: 100))
    image.lockFocus()
    defer { image.unlockFocus() }
    
    NSColor.black.setStroke()
    NSColor.white.setFill()
    let frameBezier = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                                   xRadius: 3,
                                   yRadius: 3)
    frameBezier.stroke()
    frameBezier.fill()
    
    return image
}

private func makeOAuth1Swift(consumerKey: String, consumerSecretKey: String) -> OAuth1Swift {
    
    return OAuth1Swift(
        consumerKey: consumerKey,
        consumerSecret: consumerSecretKey,
        requestTokenUrl: "https://api.twitter.com/oauth/request_token",
        authorizeUrl: "https://api.twitter.com/oauth/authenticate",
        accessTokenUrl: "https://api.twitter.com/oauth/access_token"
    )
}

private func twitterError(_ error: Error) -> (message: String, code: Int)? {
    
    if let aouthError = error as? OAuthSwiftError,
        case let .requestError(nserror as NSError, _) = aouthError,
        let resData = nserror.userInfo[OAuthSwiftError.ResponseDataKey] as? Data,
        let json = try? JSONSerialization.jsonObject(with: resData, options: .allowFragments) as? [String: Any],
        let errors = json?["errors"] as? [[String: Any]],
        let firstError = errors.first,
        let message = firstError["message"] as? String,
        let code = firstError["code"] as? Int {
        
        print("Twitter Error, message:", message, "code:", code)
        
        return (message, code)
    }
    
    return nil
}


private func jpegData(_ image: NSImage) -> Data? {
    
    guard let tiff = image.tiffRepresentation,
        let bitmapRep = NSBitmapImageRep(data: tiff),
        let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
            
            return nil
    }
    
    return imageData
}
