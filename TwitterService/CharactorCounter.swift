//
//  CharactorCounter.swift
//  TwitterService
//
//  Created by Hori,Masaki on 2018/10/14.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa


// MARK: - CharactorCounter

class CharactorCounter: NSView {
    
    
    // MARK: Internal
    
    @objc dynamic var max: Int = 100
    
    @objc dynamic var current: Int = 0 {
        
        didSet {
            
            needsDisplay = true
        }
    }
    
    
    // MARK: NSView

    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        
        let margin = CGFloat(2.0)
        
        let drawArea = NSInsetRect(bounds, margin, margin)
        
        let d = min(drawArea.size.width, drawArea.size.height)
        
        let ratio = 1.0 - (CGFloat(current) / CGFloat(max))
        
        let center = NSPoint(x: drawArea.maxX / 2.0, y: 10)
        
        let endAngle = CGFloat(min(90 + 180 * ratio, 90 + 180))
        
        let cgContext = NSGraphicsContext.current?.cgContext
        cgContext?.addArc(center: center,
                          radius: d / 2.0,
                          startAngle: degreeToRadian(angle: 90),
                          endAngle: degreeToRadian(angle: endAngle),
                          clockwise: true)
        cgContext?.addLine(to: center)
        cgContext?.closePath()
        
        color(ratio: ratio).set()
        cgContext?.fillPath()
    }
    
    
    // MARK: Private
    
    private func degreeToRadian(angle: CGFloat) -> CGFloat {
        
        let radian = CGFloat(-angle - 90) * CGFloat(Double.pi / 180)
        return radian
        
    }
    
    private func color(ratio: CGFloat) -> NSColor {
        
        switch ratio {
            
        case 0..<0.93: return #colorLiteral(red: 0, green: 0.8595900078, blue: 0, alpha: 1)
            
        case 0.93..<1.0: return NSColor.orange
            
        default: return NSColor.red
        }
    }
}
