//
//  BlurWindowController.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/10.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

class BlurWindowController: NSWindowController {
    
    init() {
        
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                         styleMask: [.titled],
                         backing: .buffered,
                         defer: true)
        
        window.backgroundColor = .black
        window.alphaValue = 0.2
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
