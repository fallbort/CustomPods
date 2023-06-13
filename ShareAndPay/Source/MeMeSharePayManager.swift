//
//  MeMeSharePayManager.swift
//  Pods
//
//  Created by xfb on 2023/6/12.
//

import Foundation
import WechatOpenSDK
import UMSocialSDK

fileprivate class WxRespObject : NSObject, WXApiDelegate {
    var onPayRespBlock:((_ resp: PayResp)->())?
    func onResp(_ resp: BaseResp) {
        if let payResp = resp as? PayResp {
            self.onPayRespBlock?(payResp)
        }
    }
}

@objc public class MeMeSharePayManager : NSObject {
    @objc public static let shared = MeMeSharePayManager()
    //MARK: <>外部变量
    
    //MARK: <>外部block
    
    
    //MARK: <>生命周期开始
    fileprivate override init() {
        super.init()
        self.wxDelegateObject.onPayRespBlock = { [weak self] payResp in
            guard let `self` = self else {return}
            self.resultCompletes.forEach({ [weak self] resultComplete in
                resultComplete(payResp)
            })
            self.resultCompletes.removeAll()
        }
    }
    //MARK: <>功能性方法
    @objc public static func startup(UmengAppkey:String,channel:String = "App Store") {
        UMCommonLogManager.setUp()
        UMConfigure.initWithAppkey(UmengAppkey, channel: channel)
    }
    @objc public func register(type:MeMeSharedPayType,appKey:String,appSecret:String,universalLink:String,redirectURL:String) {
        self.configPaySetting(type: type, appKey: appKey, appSecret: appSecret, universalLink: redirectURL)
        self.confitUShareSettings(type: type, universalLink: universalLink)
        self.configUSharePlatforms(type: type, appKey: appKey, appSecret: appSecret, redirectURL: redirectURL)
    }
    
    fileprivate func configPaySetting(type:MeMeSharedPayType,appKey:String,appSecret:String,universalLink:String) {
        switch type {
        case .wechat:
            WXApi.registerApp(appKey, universalLink: universalLink)
        case .qq:
            break
        }
    }
    
    fileprivate func confitUShareSettings(type:MeMeSharedPayType,universalLink:String) {
        var oldDict:[AnyHashable:Any] = UMSocialGlobal.shareInstance().universalLinkDic ?? [:]
        if type == .qq {
            oldDict[UMSocialPlatformType.QQ] = universalLink
        }else if type == .wechat {
            oldDict[UMSocialPlatformType.wechatSession.rawValue] = universalLink
        }
        
        UMSocialGlobal.shareInstance().universalLinkDic = oldDict;
    }
    
    fileprivate func configUSharePlatforms(type:MeMeSharedPayType,appKey:String,appSecret:String,redirectURL:String) {
        var platformType:UMSocialPlatformType?
        switch type {
        case .wechat:
            platformType = .wechatSession
        case .qq:
            platformType = .QQ
        }
        if let platformType = platformType {
            UMSocialManager.default().setPlaform(platformType, appKey: appKey, appSecret: appSecret, redirectURL: redirectURL)
        }
        
    }
    
    @objc public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var result = UMSocialManager.default().handleOpen(url,options: options)
        if (!result) {
            // 其他如支付等SDK的回调
            result = WXApi.handleOpen(url, delegate: self.wxDelegateObject);

        }
        return result;
    }
    
    @objc public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return UMSocialManager.default().handleUniversalLink(userActivity,options: nil)
    }
    
    /**demo
    PayReq *request = [[PayReq alloc] init];
    request.partnerId = json[@"data"][@"partnerid"];
    request.prepayId= json[@"data"][@"prepayid"];
    request.package = json[@"data"][@"app_package"];
    request.nonceStr= json[@"data"][@"noncestr"];
    request.timeStamp=[json[@"data"][@"timeStamp"]intValue];
    request.sign= json[@"data"][@"sign"];
     **/
    @objc public func sendWxPay(payResp:PayResp,sendComplete:((Bool)->())? =  nil,resultComplete:((PayResp)->())? = nil) {
        WXApi.send(payResp,completion: sendComplete)
        if let resultComplete = resultComplete {
            resultCompletes.append(resultComplete)
        }
    }
    
    //MARK: <>内部View
    
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    fileprivate lazy var wxDelegateObject = {
        let object = WxRespObject()
        return object
    }()
    
    fileprivate var resultCompletes:[((PayResp)->())] = []
    
    //MARK: <>内部block
    
}

extension MeMeSharePayManager {
    
}
