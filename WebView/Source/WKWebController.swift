//
//  WKWebController.swift
//  MeMe
//
//  Created by funplus on 2017/1/17.
//  Copyright © 2017年 sip. All rights reserved.
//

import UIKit
import Cartography
import MeMeKit
import WebKit
import RxSwift

let WhiteUrls: [String] = {
    return [
        
    ]
}()

public class WKWebController: UIViewController {
    
    public static var webViewHasExtra = false
    
    fileprivate static var sharedWebView: WKWebView?
    
    fileprivate var innerWebView: WKWebView?
    fileprivate var bridge: WKWebViewJavascriptBridge?
    
    fileprivate lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.progressTintColor = UIColor.init(hex: 0xff596a)
        return view
    }()
    
    fileprivate var activityView: UIActivityIndicatorView?
    fileprivate var activityBackView: UIView?
    
    fileprivate var titled = false

    public var url: String? {
        didSet {
            if let url = url,url.count > 0 {
                if let url = URL.init(string: url) {
                    let request = URLRequest.init(url: url)
                    self.request = request
                }else{
                    gLog("WKWebController url failed")
                }
            }else{
                gLog("WKWebController url empty")
            }
        }
    }
    
    var request: URLRequest? {
        didSet {
            if let request = request {
                self.createWeb()
                innerWebView?.load(request)
                debugLabel.text = "\(request.url?.absoluteString ?? "")"
            }else{
            
            }
        }
    }

    public var callBack: ((Any) -> Void)?
    public var destroyH5: VoidBlock?
    
    var scrollBounces: Bool {
        get {
            return innerWebView?.scrollView.bounces ?? false
        }
        set {
            innerWebView?.scrollView.bounces = newValue
        }
    }
    
    public var titleChangeObser = BehaviorSubject<String?>(value: nil)
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.innerWebView?.removeObserver(self, forKeyPath: "estimatedProgress")
        self.innerWebView?.navigationDelegate = nil
        self.innerWebView?.uiDelegate = nil
        self.innerWebView?.scrollView.delegate = nil
        self.innerWebView?.stopLoading()
        callBack = nil
        bridge = nil
        url = nil
        request = nil
    }
    
    public static func lanuch() {
        prepareWebView()
    }
    
    fileprivate static func getWebView() -> WKWebView {
        let webView:WKWebView
        if let sharedWebView = sharedWebView {
            webView = sharedWebView
        }else{
            webView = prepareWebView()
        }
        prepareWebView()
        return webView
    }
    
    @discardableResult
    fileprivate static func prepareWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }
        if #available(iOS 13.0, *) {
            config.defaultWebpagePreferences.preferredContentMode = .mobile
        } else {
            // Fallback on earlier versions
        }

        let webview = WKWebView(frame: UIScreen.main.bounds, configuration: config)
        //        webview.isHidden = true
        self.sharedWebView = webview
        if let url = URL.init(string: "") {
            let request = URLRequest.init(url: url)
            webview.load(request)
        }
        return webview
    }
    
    public override func viewDidLoad() {
        automaticallyAdjustsScrollViewInsets = false
        edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        self.view.backgroundColor = UIColor.black
        self.createWeb()
        loadBridge()
        super.viewDidLoad()
        
        if let innerWebView = innerWebView {
            if #available(iOS 11.0, *) {
                innerWebView.scrollView.contentInsetAdjustmentBehavior = .never
            } else {
                // Fallback on earlier versions
            }
            innerWebView.removeFromSuperview()
            view.addSubview(innerWebView)
            constrain(innerWebView) {
                $0.edges == $0.superview!.edges
            }
            if Self.webViewHasExtra == true{
                let btn = UIButton.init()
                btn.setTitle("reload", for: .normal)
                btn.setTitleColor(.red, for: .normal)
                btn.handleControlEvent(.touchUpInside) { [weak self,weak innerWebView] in
                    if let innerWebView = innerWebView {
                        innerWebView.reload()
                    }
                }
                view.addSubview(btn)
                constrain(btn) {
                    $0.leading == $0.superview!.leading + 4
                    $0.top == $0.superview!.top + 4
                    $0.height == 30
                }
                
                let copybtn = UIButton.init()
                copybtn.setTitle("copy", for: .normal)
                copybtn.setTitleColor(.red, for: .normal)
                copybtn.handleControlEvent(.touchUpInside) { [weak self,weak innerWebView] in
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = self?.request?.url?.absoluteString ?? ""
                    MeMeKitConfig.showHUDBlock(NELocalize.localizedString("copied_toast"))
                }
                view.addSubview(copybtn)
                constrain(copybtn,btn) {
                    $0.leading == $1.trailing + 5
                    $0.top == $0.superview!.top + 4
                    $0.height == 30
                }
                
                view.addSubview(debugLabel)
                constrain(debugLabel) {
                    $0.leading == $0.superview!.leading + 4
                    $0.trailing == $0.superview!.trailing - 4
                    $0.bottom == $0.superview!.bottom - 4
                    $0.height >= 15
                }
                
            }
        }
        
        view.addSubview(progressView)
        self.innerWebView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        constrain(progressView) {
            $0.left == $0.superview!.left
            $0.right == $0.superview!.right
            $0.top == $0.superview!.top
        }
        innerWebView?.backgroundColor = UIColor.white
        
        titled = title != nil && title!.count > 0
        if !titled {
            if let appName = Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String {
                title = appName
                titleChangeObser.onNext(appName)
            }
        }
        
        let backView = UIView()
        backView.layer.cornerRadius = 8
        backView.clipsToBounds = true
        backView.isHidden = true
        backView.backgroundColor = UIColor.hexString(toColor:"66000000")
        backView.frame = CGRect(x:0,y:0,width:60,height:60)
        self.activityBackView = backView
        self.view.addSubview(backView)
        let viewBounds = self.view.bounds
        self.activityBackView?.center = CGPoint(x: viewBounds.width / 2, y: viewBounds.height / 2 - 50)
        self.activityView = UIActivityIndicatorView(style: .white)
        self.activityView?.hidesWhenStopped = true
        self.activityView?.center = CGPoint(x: 30.0, y: 30.0)
        backView.addSubview(activityView!)
        self.activityView?.startAnimating()
        DispatchQueue.main.async { [weak self] in
            backView.isHidden = false
            let viewBounds = self?.view.bounds ?? CGRect.init()
            self?.activityBackView?.center = CGPoint(x: viewBounds.width / 2, y: viewBounds.height / 2 - viewBounds.height*0.1)
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //  加载进度条
        if keyPath == "estimatedProgress"{
            progressView.alpha = 1.0
            progressView.setProgress(Float(self.innerWebView?.estimatedProgress ?? 0.0), animated: true)
            if let progress = self.innerWebView?.estimatedProgress, progress >= 1.0 {
                innerWebView?.evaluateJavaScript("document.title") { [weak self] obj, _ in
                    if let title = obj as? String {
                        self?.title = title
                        self?.titleChangeObser.onNext(title)
                    }
                }
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut, animations: {
                    self.progressView.alpha = 0
                    self.activityView?.removeFromSuperview()
                    self.activityView = nil
                    self.activityBackView?.removeFromSuperview()
                    self.activityBackView = nil
                }, completion: { (finish) in
                    self.progressView.setProgress(0.0, animated: false)
                })
            }
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = StatusBarStyleDarkContent

    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    class func whiteUrl(_ url: String) -> Bool {
        if url.count > 0 {
            for whiteUrl in WhiteUrls {
                if url.hasPrefix(whiteUrl) {
                    return true
                }
            }
        }
        return false
    }
    
    fileprivate func createWeb() {
        if innerWebView == nil {
            self.innerWebView = Self.getWebView()
            self.innerWebView?.navigationDelegate = self
            self.innerWebView?.uiDelegate = self
        }
    }
    
    func loadHtml(_ html: String) {
        self.innerWebView?.loadHTMLString(html, baseURL: nil)
    }
    
    func refresh() -> Bool {
        if let selfUrl = url {
            self.url = selfUrl
            return true
        } else if let urlStr = request?.url?.absoluteString,let url = URL.init(string: urlStr) {
            request = URLRequest.init(url: url)
            return true
        }
        return false
    }
    
    @objc func clickCloseBtn(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
        clean()
    }
    
    var debugLabel:UILabel = {
        let view = UILabel()
        view.textColor = UIColor.red
        view.font = ThemeLite.Font.medium(size:10)
        return view
    }()
    
    func addExtraBridge(handleName:String,handler:@escaping WVJBHandler) {
        extraBridgeDict[handleName] = handler
        dealExtraBridge()
    }
    
    fileprivate func dealExtraBridge() {
        if let bridge = bridge {
            for (handleName,handler) in extraBridgeDict {
                bridge.registerHandler(handleName, handler: handler)
            }
            extraBridgeDict.removeAll()
        }
    }
    
    fileprivate var extraBridgeDict:[String:WVJBHandler] = [:]
}

extension WKWebController {
    @objc func backNative() {
        if let canBack = self.innerWebView?.canGoBack,canBack == true {
            self.innerWebView?.goBack()
            self.innerWebView?.evaluateJavaScript("backSuccess(true)")
        } else {
            clean()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    fileprivate func clean() {
        innerWebView?.stopLoading()
        innerWebView?.loadHTMLString("", baseURL: nil)
        innerWebView?.uiDelegate = nil
        innerWebView?.navigationDelegate = nil
        innerWebView?.removeFromSuperview()
    }
}

extension WKWebController: WKUIDelegate {
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
            completionHandler()
        }
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
            completionHandler(true)
        }
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
            completionHandler(false)
        }
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

extension WKWebController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        //log.verbose("wkwebview didStartProvisionalNavigation,url=\(webView.url?.absoluteString ?? "")")
        debugLabel.text = "didStartProvisionalNavigation"
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        //log.verbose("wkwebview didCommit,url=\(webView.url?.absoluteString ?? "")")
        debugLabel.text = "didCommit"
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debugLabel.text = "didFailProvisionalNavigation"
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugLabel.text = "didFail"
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //log.verbose("wkwebview didFinish,url=\(webView.url?.absoluteString ?? "")")
        webView.isHidden = false
        self.activityView?.isHidden = true
        self.activityBackView?.isHidden = true
        debugLabel.text = "didFinish"
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        //log.verbose("wkwebview ContentProcessDidTerminate,url=\(webView.url?.absoluteString ?? "")")
        debugLabel.text = "DidTerminate"
    }
    
}

extension WKWebController {
    func loadBridge() {
        self.createWeb()
        guard let bridge = WKWebViewJavascriptBridge(for: innerWebView) else {
            return
        }
        
        self.bridge = bridge
        bridge.setWebViewDelegate(self)

        dealExtraBridge()
    }
}


class ComonBottomWkWebController: WKWebController {
    override init() {
        super.init()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.innerWebView?.backgroundColor = .clear
        self.innerWebView?.isOpaque = false
        self.activityView = UIActivityIndicatorView(style: .whiteLarge)
        self.activityView?.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: self.contentSizeInPopup.height/2)
        self.view.addSubview(activityView!)
        self.activityView?.startAnimating()
    }
    
}
