//
//  MeMeSharePayManager.swift
//  Pods
//
//  Created by xfb on 2023/6/12.
//

import Foundation
import WechatOpenSDK
import UMSocialSDK

public class MeMeSharePayManager {
    public static let shared = MeMeSharePayManager()
    //MARK: <>外部变量
    
    //MARK: <>外部block
    
    
    //MARK: <>生命周期开始
    fileprivate init() {
        
    }
    //MARK: <>功能性方法
    public static func startup(UmengAppkey:String,channel:String = "App Store") {
        UMCommonLogManager.setUp()
        UMConfigure.initWithAppkey(UmengAppkey, channel: channel)
    }
    public func register(type:MeMeSharedPayType,appKey:String,appSecret:String,universalLink:String,redirectURL:String) {
        self.configPaySetting(type: type, appKey: appKey, appSecret: appSecret, universalLink: redirectURL)
        self.confitUShareSettings(type: type, universalLink: universalLink)
        self.configUSharePlatforms(type: type, appKey: appKey, appSecret: appSecret, redirectURL: redirectURL)
    }
    
    func configPaySetting(type:MeMeSharedPayType,appKey:String,appSecret:String,universalLink:String) {
        switch type {
        case .wechat:
            WXApi.registerApp(appKey, universalLink: universalLink)
        case .qq:
            break
        }
    }
    
    func confitUShareSettings(type:MeMeSharedPayType,universalLink:String) {
        var oldDict:[AnyHashable:Any] = UMSocialGlobal.shareInstance().universalLinkDic ?? [:]
        if type == .qq {
            oldDict[UMSocialPlatformType.QQ] = universalLink
        }else if type == .wechat {
            oldDict[UMSocialPlatformType.wechatSession.rawValue] = universalLink
        }
        
        UMSocialGlobal.shareInstance().universalLinkDic = oldDict;
    }
    
    func configUSharePlatforms(type:MeMeSharedPayType,appKey:String,appSecret:String,redirectURL:String) {
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
    
    //MARK: <>内部View
    
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    
    //MARK: <>内部block
    
}

extension MeMeSharePayManager {
    
}
