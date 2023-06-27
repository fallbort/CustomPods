//
//  MeMeIMManager.swift
//  Alamofire
//
//  Created by xfb on 2023/6/25.
//

import Foundation
import NECoreKit
import NIMSDK
import NECoreIMKit
import NEConversationUIKit
import NEChatUIKit

@objc public class MeMeIMManager : NSObject {
    @objc public static var shared = MeMeIMManager()
    //MARK: <>外部变量
    
    //MARK: <>外部block
    
    
    //MARK: <>生命周期开始
    override init() {
        super.init()
        
    }
    //MARK: <>功能性方法
    @objc public func startup(appKey:String,pushCerName:String) {
        let option = NIMSDKOption()
        option.appKey = appKey
        option.apnsCername = pushCerName
        IMKitClient.instance.setupCoreKitIM(option)
        
        registerAPNS()
    }
    
    //    regist router
    func loadService() {
//        ChatRouter.register()
//        ConversationRouter.register()
    }
    
    func registerAPNS(){
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            center.requestAuthorization(options: [.badge, .sound, .alert]) { grant, error in
                if grant == false {
                    ////toast
                }
            }
        } else {
            let setting = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(setting)
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    @objc public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        NIMSDK.shared().updateApnsToken(deviceToken)
    }
    //MARK: <>内部View
    
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    
    //MARK: <>内部block
    
}

extension MeMeIMManager : UNUserNotificationCenterDelegate {
    
}
