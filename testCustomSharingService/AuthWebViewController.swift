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
    
    private var webView: WKWebView?
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        present = .asSheet
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var f = self.view.frame
        f.origin = .zero
        let config = WKWebViewConfiguration()
        let newWebView = WKWebView(frame: f, configuration: config)
        newWebView.autoresizingMask = [.height, .width, .maxXMargin, .minXMargin, .maxYMargin, .minYMargin]
        newWebView.navigationDelegate = self
        self.view.addSubview(newWebView)
        
        webView = newWebView
    }
    
    override func handle(_ url: URL) {
        super.handle(url)
        
        webView?.load(URLRequest(url: url))
    }
    
}

extension AuthWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
        if let url = navigationAction.request.url , url.scheme == "hmsharing" {
            AppDelegate.sharedInstance.applicationHandle(url: url)
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
