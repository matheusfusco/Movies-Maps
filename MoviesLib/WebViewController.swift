//
//  WebViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 04/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    //MARK: - Lets and Vars
    var url: String!
    
    //MARK: - IBOutlets
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webpageURL = URL(string: url)
        let request = URLRequest(url: webpageURL!)
        webView.loadRequest(request)
    }

    //MARK: - Button Actions
    @IBAction func closeWebViewBtnClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func executeBtnClicked(_ sender: Any) {
        webView.stringByEvaluatingJavaScript(from: "alert('Rodando Javascript na Webview')")
    }
    //MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WebViewController : UIWebViewDelegate {
    func webViewDidStartLoad(_ webView: UIWebView) {
        activityIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url?.absoluteString.range(of: "ads") != nil {
            return false
        }
        return true
    }
}
