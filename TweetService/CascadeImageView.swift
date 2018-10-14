//
//  CascadeImageView.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/09.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa


// MARK: - CascadeImageView

class CascadeImageView: NSView {
    
    
    // MARK - Internal
    
    typealias ImageInfo = (image: NSImage, size: NSSize)
    
    var images: [NSImage] = []
    
    var offset: NSSize = NSSize(width: 6, height: 4)
    
//    var direction: NSControl.ImagePosition = .imageRight
    
    
    // MARK: NSView
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard !images.isEmpty else { return }
        
        imageShadow.set()
        
        let dwarBounds = NSRect(x: bounds.origin.x,
                                y: bounds.origin.y,
                                width: bounds.size.width - 10,
                                height: bounds.size.height - 5)
        
        let imageWidth = dwarBounds.size.width - CGFloat(images.count - 1) * offset.width
        
        _ = images
            .reversed()
            .map { image -> ImageInfo in
                
                let imageSize = image.size
                let newHeight = imageSize.height * imageWidth / imageSize.width
                
                return (image, NSSize(width: imageWidth, height: newHeight))
            }
            .reduce(0.0) { (imageOffset, imageInfo) -> CGFloat in
                
                let rect = NSRect(x: dwarBounds.maxX - imageWidth - offset.width * imageOffset,
                                  y: dwarBounds.maxY - imageInfo.size.height - offset.height * imageOffset,
                                  width: imageInfo.size.width,
                                  height: imageInfo.size.height)
                
                print(rect)
                
                imageInfo.image.draw(in: rect)
                
                return imageOffset + 1
        }
    }
    
    
    // MARK: - Private
    
    private static var imageShadow: NSShadow = {
        
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 4, height: -4)
        shadow.shadowBlurRadius = 6
        
        return shadow
    }()
    
    private var imageShadow: NSShadow {
        
        return type(of: self).imageShadow
    }
}
