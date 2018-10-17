//
//  BlurWindowController.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/10.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa


// MARK: - BlurWindowController

class BlurWindowController: NSWindowController {
    
    
    // MARK: Internal
    
    var targetWindow: NSWindow? {
        
        didSet {
            
            imageView.image = targetWindow.flatMap(shadowImage)
        }
    }
    
    init() {
        
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                              styleMask: [],
                              backing: .buffered,
                              defer: true)
        
        window.alphaValue = 0.2
        window.contentView = NSImageView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Private
    
    private var imageView: NSImageView {
        
        return window?.contentView as! NSImageView
    }
    
    private func shadowImage(window: NSWindow) -> NSImage? {
        
        guard let image = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber), [.boundsIgnoreFraming]) else {
            
            return nil
        }
        
        return bitmap(image: image)
            .flatMap(toBlack)
            .flatMap { RGBAImage(from: $0, width: image.width, height: image.height) }
    }
    
    private func bitmap(image: CGImage) -> Data? {
        
        let width = image.width
        let height = image.height
        
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width
        var pixelData = Data(count: height * bytesPerRow)
        pixelData.withUnsafeMutableBytes { (rawData: UnsafeMutablePointer<UInt8>) -> Void in
            
            let context = CGContext(data: rawData,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: image.colorSpace!,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        return pixelData
    }
    
    private func toBlack(data: Data) -> Data {
        
        let size = data.count / 4
        
        let buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: size)
        defer { buffer.deallocate() }
        
        data.withUnsafeBytes { (pixel: UnsafePointer<UInt32>) -> Void in
            
            for i in 0..<size {
                
                buffer[i] = pixel[i] & 0xff000000
            }
        }
        
        return Data(bytes: buffer, count: data.count)
    }
    
    private func RGBAImage(from data: Data, width: Int, height: Int) -> NSImage? {
        
        var p: UnsafeMutablePointer<UInt8>? = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        guard let pp = p else { return nil }
        data.copyBytes(to: pp, count: data.count)
        defer { pp.deallocate() }
        
        return NSBitmapImageRep(bitmapDataPlanes: &p,
                                pixelsWide: width,
                                pixelsHigh: height,
                                bitsPerSample: 8,
                                samplesPerPixel: 4,
                                hasAlpha: true,
                                isPlanar: false,
                                colorSpaceName: NSColorSpaceName.deviceRGB,
                                bytesPerRow: 4 * width,
                                bitsPerPixel: 32)
            .flatMap { $0.tiffRepresentation }
            .flatMap { NSImage(data: $0) }
    }
}
