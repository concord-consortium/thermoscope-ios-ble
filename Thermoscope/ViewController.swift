//
//  Copyright © 2017 Paul Theriault & David Park. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import UIKit
import WebKit

class ViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate,WKUIDelegate {

    enum prefKeys: String {
        case bookmarks
        case lastLocation
        case version
    }

    // MARK: - Properties
    let currentPrefVersion = 1

    // MARK: IBOutlets
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet var tick: UIImageView!

    @IBOutlet var goBackButton: UIBarButtonItem!
    @IBOutlet var goForwardButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIBarButtonItem!

    @IBOutlet var webView: WBWebView!
    var wbManager: WBManager? {
        didSet {
            self.webView.wbManager = wbManager
        }
    }

    @IBAction func reload() {
        if (self.webView?.url?.absoluteString ?? "about:blank") == "about:blank",
            let text = self.locationTextField.text,
            !text.isEmpty {
            self.loadLocation(text)
        } else {
            self.webView.reload()
        }
    }

    // MARK: - Event handling
    override func viewDidLoad() {
       
        super.viewDidLoad()

        // connect view to other objects
        self.locationTextField.delegate = self
        self.webView.wbManager = self.wbManager
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self

        for path in ["canGoBack", "canGoForward"] {
            self.webView.addObserver(self, forKeyPath: path, options: NSKeyValueObservingOptions.new, context: nil)
        }

        // Load app location
        var homeLocation: String
        homeLocation = "https://thermoscope.concord.org/branch/master/"
        self.loadLocation(homeLocation)

        self.goBackButton.target = self.webView
        self.goBackButton.action = #selector(self.webView.goBack)
        self.goForwardButton.target = self.webView
        self.goForwardButton.action = #selector(self.webView.goForward)
        self.refreshButton.target = self
        self.refreshButton.action = #selector(self.reload)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.loadLocation(textField.text!)
        return true
    }
    
    func loadLocation(_ location: String) {
        var location = location
        if !location.hasPrefix("http://") && !location.hasPrefix("https://") {
            location = "https://" + location
        }
        locationTextField.text = location
        self.webView.load(URLRequest(url: URL(string: location)!))
        
    }

    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let man = self.wbManager {
            man.clearState()
        }
        self.wbManager = WBManager()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let urlString = webView.url?.absoluteString,
            urlString != "about:blank" {
            self.locationTextField.text = urlString
            UserDefaults.standard.setValue(urlString, forKey: ViewController.prefKeys.lastLocation.rawValue)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.loadHTMLString("<p>Fail Navigation: \(error.localizedDescription)</p>", baseURL: nil)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.loadHTMLString("<p>Fail Provisional Navigation: \(error.localizedDescription)</p>", baseURL: nil)
    }

    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (@escaping () -> Void)) {
        let alertController = UIAlertController(
            title: frame.request.url?.host, message: message,
            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(
            title: "OK", style: .default, handler: {_ in completionHandler()}))
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: - Observe protocol
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard
            let defKeyPath = keyPath,
            let defChange = change
        else {
            NSLog("Unexpected change with either no keyPath or no change dictionary!")
            return
        }

        switch defKeyPath {
        case "canGoBack":
            self.goBackButton.isEnabled = defChange[NSKeyValueChangeKey.newKey] as! Bool
        case "canGoForward":
            self.goForwardButton.isEnabled = defChange[NSKeyValueChangeKey.newKey] as! Bool
        default:
            NSLog("Unexpected change observed by ViewController: \(String(describing: keyPath))")
        }
    }

    // MARK: - Private

}