//
//  TweetService.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/08.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

import BrightFutures
import KeychainAccess
import OAuthSwift
import Result


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


// MARK: - TweetService

public final class TweetService {
    
    
    // MARK: - Public
    
    public var serviceName: String = "Tweet"
    
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
        
        let service = NSSharingService(title: serviceName, image: serviceImage, alternateImage: alternateImage) {
            
            self.tweet(items: items)
        }
        
        return [service] + proposedServices
    }
    
    
    // MARK: - Private
    
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
        
        checkAuthorized()
            .recoverWith { _ in self.retrieveFromKeyChain() }
            .recoverWith { _ in self.authorize(items) }
            .onSuccess {
                
                self.didAuthrized = true
                self.delegate?.tweetService(didSuccessAuthorize: self)
            }
            .flatMap {
                
                self.tweetPanelProvider
                    .showTweetPanelFuture(self.delegate?.tweetService(self, sourceWindowForShareItems: items), shareItems: items)
                    .mapError(convertError)
            }
            .flatMap(self.postTweet)
            .onSuccess { items in self.delegate?.tweetService(self, didPostItems: items) }
            .onFailure { error in
                
                switch error {
                    
                case .userCancel:
                    
                    self.delegate?.tweetServiveDidCancel(self)
                    
                case .missingToken:
                    
                    self.oauthswift = makeOAuth1Swift(consumerKey: self.oauthswift.client.credential.consumerKey,
                                                      consumerSecretKey: self.oauthswift.client.credential.consumerSecret)
                    
                    self.delegate?.tweetServiveDidCancel(self)
                    
                case .failAuthorize:
                    
                    self.delegate?.tweetService(self, didFailAuthorizeWithError: error)
                    
                case .twitterError:
                    
                    let error = twitterError(error) ?? error
                    
                    self.delegate?.tweetService(self, didFailPostItems: items,
                                                error: error)
                    
                default:
                    
                    self.delegate?.tweetService(self, didFailPostItems: items, error: error)
                }
        }
    }
    
    private func checkAuthorized() -> Future<Void, TweetServiceError> {
        
        return Future { complete in
            
            if didAuthrized {
                
                complete(.success(()))
                
            } else {
                
                complete(.failure(.notAuthorized))
            }
        }
    }
    
    private func authorize(_ items: [Any]) -> Future<Void, TweetServiceError> {
        
        oauthswift.authorizeURLHandler = webViewController
        webViewController.delegate = self
        authorizePanelParent(for: items).addChildViewController(webViewController)
        
        return  oauthswift
            .authorizeFuture(withCallbackURL: URL(string: callbackScheme + "://oauth-callback/twitter")!)
            .flatMap { _,_,_ in  self.storeCredental() }
            .mapError { error in
                
                switch error {
                    
                case .missingToken: return error
                    
                default: return .failAuthorize
                }
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
    
    private func postTweet(items: [Any]) -> Future<[Any], TweetServiceError> {
        
        delegate?.tweetService(self, willPostItems: items)
        
        let text = items.first{ item in item is String } as? String ?? ""
        let images = items.filter { item in item is NSImage } as? [NSImage] ?? []
        
        return images
            .traverse(f: self.uploadImage)
            .map { ids in ids.compactMap { $0 } }
            .flatMap { mediaIds in
                
                self.oauthswift
                    .client
                    .requestFuture("https://api.twitter.com/1.1/statuses/update.json",
                                   method: .POST,
                                   parameters: parameter(text: text, mediaIds: mediaIds))
                    .future
                    .map { _ in items }
                    .mapError(convertError)
        }
    }
    
    private func uploadImage(_ image: NSImage) -> Future<String?, TweetServiceError> {
        
        guard let imageData = jpegData(image) else {
            
            return Future(value: nil)
        }
        
        let promise = Promise<String?, TweetServiceError>()
        
        oauthswift
            .client
            .postImageFuture("https://upload.twitter.com/1.1/media/upload.json", image: imageData)
            .future
            .flatMap(mediaId(response:))
            .onSuccess(callback: promise.success)
            .onFailure(callback: promise.failure)
        
        return promise.future
    }
    
    private func mediaId(response: OAuthSwiftResponse) -> Result<String, TweetServiceError> {
        
        return Result {
            
            let json = try JSONSerialization.jsonObject(with: response.data) !!! TweetServiceError.couldNotParseJSON
            let dict = try json as? [String: Any] ??! TweetServiceError.jsonNotDictionary
            let mediaId = try dict["media_id_string"] as? String ??! TweetServiceError.notContainsMediaId
            
            return mediaId
        }
    }
    
    private func retrieveFromKeyChain() -> Future<Void, TweetServiceError> {
        
        return Future(result: Result {
            
            let keychain = Keychain(service: "TweetService")
            
            let data = try keychain
                .authenticationPrompt("Authenticate to tweet")
                .getData("credental") !!! TweetServiceError.keychainAccessInternal
            let credentalData = try data ??! TweetServiceError.credentalNotStoreInKeychain
            let credental = try OAuthSwiftCredential.unarchive(credentalData)
            
            self.oauthswift.client.credential.oauthToken = credental.oauthToken
            self.oauthswift.client.credential.oauthTokenSecret = credental.oauthTokenSecret
        })
    }
    
    private func storeCredental() -> Future<Void, TweetServiceError> {
        
        return Future(result: Result {
            
            let archiveData = try self.oauthswift.client.credential.archive()
            let keychain = Keychain(service: "TweetService")
            try? keychain.set(archiveData, key: "credental")
        })
            .mapError(convertError)
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

private func parameter(text: String, mediaIds: [String]) -> OAuthSwift.Parameters {
    
    let mediaIDsString = mediaIds.joined(separator: ",")
    switch mediaIDsString {
        
    case "": return ["status": text]
        
    default: return ["status": text, "media_ids": mediaIDsString]
    }
}

private func jpegData(_ image: NSImage) -> Data? {
    
    guard let tiff = image.tiffRepresentation,
        let bitmapRep = NSBitmapImageRep(data: tiff),
        let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
            
            return nil
    }
    
    return imageData
}
