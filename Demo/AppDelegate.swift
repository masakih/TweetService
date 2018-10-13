//
//  AppDelegate.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/07.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa

import OAuthSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    private let contentViewController = ViewController()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    override func awakeFromNib() {
        
        window.contentViewController = contentViewController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}
