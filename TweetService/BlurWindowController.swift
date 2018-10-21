//
//  BlurWindowController.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/10.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa


// MARK: - BlurWindowController

final class BlurWindowController: NSWindowController {
    
    
    // MARK: - Internal
    
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
    
    
    // MARK: - Private
    
    private var imageView: NSImageView {
        
        return window?.contentView as! NSImageView
    }
}


// MARK: - Private

// 256 grayscale with alpha
private typealias PixelWide = UInt16
private let bytesPerPixel = 2
private let bitsPerComponent = 8
private let alphaMask: PixelWide = 0xff00

private func shadowImage(window: NSWindow) -> NSImage? {
    
    guard let image = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber), [.boundsIgnoreFraming]) else {
        
        return nil
    }
    
    return bitmap(image: image)
        .flatMap(toBlack)
        .flatMap { grayscaleImage(from: $0, width: image.width, height: image.height) }
}

private func bitmap(image: CGImage) -> Data? {
    
    let width = image.width
    let height = image.height
    
    let bytesPerRow = bytesPerPixel * width
    var pixelData = Data(count: height * bytesPerRow)
    pixelData.withUnsafeMutableBytes { (rawData: UnsafeMutablePointer<UInt8>) -> Void in
        
        let context = CGContext(data: rawData,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: CGColorSpaceCreateDeviceGray(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    return pixelData
}

private func toBlack(data: Data) -> Data {
    
    return data.withUnsafeBytes { (pixel: UnsafePointer<PixelWide>) -> Data in
        
        let size = data.count / bytesPerPixel
        
        let buffer = UnsafeMutablePointer<PixelWide>.allocate(capacity: size)
        defer { buffer.deallocate() }
        
        for i in 0..<size {
            
            buffer[i] = pixel[i] & alphaMask
        }
        
        return Data(bytes: buffer, count: data.count)
    }
}

private func grayscaleImage(from data: Data, width: Int, height: Int) -> NSImage? {
    
    var p: UnsafeMutablePointer<UInt8>? = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
    guard let pp = p else { return nil }
    data.copyBytes(to: pp, count: data.count)
    defer { pp.deallocate() }
    
    return NSBitmapImageRep(bitmapDataPlanes: &p,
                            pixelsWide: width,
                            pixelsHigh: height,
                            bitsPerSample: bitsPerComponent,
                            samplesPerPixel: bytesPerPixel,
                            hasAlpha: true,
                            isPlanar: false,
                            colorSpaceName: NSColorSpaceName.deviceWhite,
                            bytesPerRow: bytesPerPixel * width,
                            bitsPerPixel: bytesPerPixel * bitsPerComponent)
        .flatMap { $0.tiffRepresentation }
        .flatMap { NSImage(data: $0) }
}
