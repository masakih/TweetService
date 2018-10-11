//
//  AuthWebViewController.swift
//  testCustomSharingService
//
//  Created by Hori,Masaki on 2018/10/08.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa
import WebKit

import OAuthSwift

class AuthWebViewController: OAuthWebViewController {
    
    private let callbackScheme: String
    
    private var webView: WKWebView { return self.view as! WKWebView }
    
    init(callbackScheme: String) {

        self.callbackScheme = callbackScheme

        super.init(nibName: nil, bundle: nil)
        
        present = .asSheet
    }
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        
        view = WKWebView(frame: NSRect(x: 0, y: 0, width: 350, height: 550),
                         configuration: WKWebViewConfiguration())
        webView.navigationDelegate = self
    }
    
    override func handle(_ url: URL) {
        
        super.handle(url)
        
        webView.load(URLRequest(url: url))
    }
}

extension AuthWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
        if let url = navigationAction.request.url , url.scheme == callbackScheme {
            
            OAuthSwift.handle(url: url)
            decisionHandler(.cancel)
            
            self.dismissWebViewController()
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        print("\(error)")
        self.dismissWebViewController()
        // maybe cancel request...
    }
    
}
