//
//  CascadeImageView.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/09.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

class CascadeImageView: NSView {
    
    var images: [NSImage] = [] {
        
        didSet {
            
            self.needsDisplay = true
        }
    }
    
    var offset: NSSize = NSSize(width: 6, height: 6)
    
//    var direction: NSControl.ImagePosition = .imageRight

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard !images.isEmpty else { return }
        
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 4, height: -4)
        shadow.shadowBlurRadius = 6
        shadow.set()
        
        let imageWidth = bounds.size.width - CGFloat(images.count - 1) * offset.width
        
        _ = images
            .reversed()
            .map { image -> (NSImage, NSSize) in
                
                let imageSize = image.size
                let newHeight = imageSize.height * imageWidth / imageSize.width
                
                return (image, NSSize(width: imageWidth, height: newHeight))
        }
            .reduce(0.0) { (imageOffset, arg1) -> CGFloat in
                
                let (image, size) = arg1
                
                let rect = NSRect(x: bounds.maxX - imageWidth - offset.width * imageOffset,
                                  y: bounds.maxY - size.height - offset.height * imageOffset,
                                  width: size.width,
                                  height: size.height)
                
                print(rect)
                
                image.draw(in: rect)
                
                return imageOffset + 1
        }
    }
}
