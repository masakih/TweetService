//
//  TweetService.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/08.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa
import OAuthSwift

public protocol TweetServiceDelegate: class {
    
    func tweetService(_ service: TweetService, willPostItems items: [Any])
    
    func tweetService(_ service: TweetService, didPostItems items: [Any])
    
    func tweetService(_ service: TweetService, didFailPostItems items: [Any], error: Error)
}

public enum TweetServiceError: Error {
    
    case jsonNotDictionary
    
    case notConntainsMediaIds
}

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

public class TweetService {
    
    private let oauthswift: OAuthSwift
    
    public var seriviceName: String = "Twitter"
    
    public var serviceImage: NSImage = defaultServiceImage()
    
    public var alternateImage: NSImage?
    
    public weak var delegate: TweetServiceDelegate?
    
    public init(oauthswift: OAuthSwift) {
        
        self.oauthswift = oauthswift
    }
    
    public func sharingServicePicker(_ items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        
        guard canTweet(items: items) else { return proposedServices }
        
        let service = NSSharingService(title: seriviceName, image: serviceImage, alternateImage: alternateImage) {
            
            self.tweet(items: items)
        }
        
        return proposedServices + [service]
    }
    
    private func tweet(items: [Any]) {
        
        delegate?.tweetService(self, willPostItems: items)
        
        guard let text = items.first(where: { item in item is String }) as? String else {
            
            return
        }
        
        let images = items.filter({ item in item is NSImage }) as? [NSImage] ?? []
        postImages(text, images: images)
    }
    
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
    
    private func uploadImage(images: [NSImage], mediaIds: [String]) -> Future<(images: [NSImage], mediaIds: [String])> {
        
        guard let image = images.first else {
            
            return Future((images, mediaIds))
        }
        
        guard let tiff = image.tiffRepresentation,
            let bitmapRep = NSBitmapImageRep(data: tiff),
            let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
                
                return Future((Array(images.dropFirst()), mediaIds))
        }
        
        let promise = Promise<(images: [NSImage], mediaIds: [String])>()
        
        oauthswift
            .client
            .postImageFuture("https://upload.twitter.com/1.1/media/upload.json", parameters: [:], image: imageData)
            .future
            .onSuccess { response in
                
                do {
                    
                    let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments)
                    guard let dict = json as? [String: Any] else {
                        
                        throw TweetServiceError.jsonNotDictionary
                    }
                    guard let mediaId = dict["media_id_string"] as? String else {
                        
                        throw TweetServiceError.notConntainsMediaIds
                    }
                    
                    promise.success((images: Array(images.dropFirst()) , mediaIds: mediaIds + [mediaId]))
                }
                catch {
                    
                    promise.failure(error)
                }
            }
            .onFailure { error in promise.failure(error) }
        
        return promise.future.flatMap(uploadImage)
    }
    
    private func postImages(_ text: String, images: [NSImage]) {
        
        uploadImage(images: images, mediaIds: [])
            .flatMap { (_, mediaIds) -> Future<OAuthSwiftResponse> in
                
                let mediaIDsString = mediaIds.joined(separator: ",")
                let params: OAuthSwift.Parameters
                switch mediaIDsString {
                    
                case "": params = ["status": text]
                    
                default: params = ["status": text, "media_ids": mediaIDsString]
                }
                
                return self.oauthswift.client.requestFuture("https://api.twitter.com/1.1/statuses/update.json",
                                                            method: .POST,
                                                            parameters: params,
                                                            headers: nil)
                    .future
            }
            .onSuccess { _ in
                
                self.delegate?.tweetService(self, didPostItems: [text] + images)
            }
            .onFailure { error in
                
                self.delegate?.tweetService(self, didFailPostItems: [text] + images, error: error)
        }
    }
}
