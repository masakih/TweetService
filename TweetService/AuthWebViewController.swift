//
//  AuthWebViewController.swift
//  TweetService
//
//  Created by Hori,Masaki on 2018/10/08.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Cocoa
import WebKit

import OAuthSwift


// MARK: - AuthWebViewController

final class AuthWebViewController: OAuthWebViewController {
    
    
    // MARK: - Internal
    
    init(callbackScheme: String) {

        self.callbackScheme = callbackScheme

        super.init(nibName: nil, bundle: nil)
        
        present = .asSheet
    }
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - NSViewController
    
    override func loadView() {
        
        view = WKWebView(frame: NSRect(x: 0, y: 0, width: 350, height: 550),
                         configuration: WKWebViewConfiguration())
        webView.navigationDelegate = self
    }
    
    
    // MARK: - OAuthSwiftURLHandlerType
    
    override func handle(_ url: URL) {
        
        super.handle(url)
        
        webView.load(URLRequest(url: url))
    }
    
    
    // MARK: - Private
    
    private var webView: WKWebView { return self.view as! WKWebView }
    
    private let callbackScheme: String
}


// MARK: - WKNavigationDelegate

extension AuthWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            
            decisionHandler(.allow)
            
            return
        }
        
        if url.scheme == callbackScheme {
            
            OAuthSwift.handle(url: url)
            decisionHandler(.cancel)
            
            self.dismissWebViewController()
            
            return
        }
        
        if let host = url.host, host != "api.twitter.com" {
            
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            
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
