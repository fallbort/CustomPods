//
//  PushService.swift
//  MeMe
//
//  Created by LuanMa on 16/9/14.
//  Copyright © 2016年 sip. All rights reserved.
//

import UserNotifications
import MeMeKit
import SwiftyUserDefaults

private extension DefaultsKeys {
    static let pushRequested = DefaultsKey<Bool>("meme.push.requested", defaultValue: false)
}

public class PushService {
    
    fileprivate(set) public static var pushReqeusted: Bool {
        get {
            return Defaults[key: DefaultsKeys.pushRequested]
        }
        set {
            guard newValue != pushReqeusted else {
                return
            }
            Defaults[key: DefaultsKeys.pushRequested] = newValue
        }
    }
    
    public static var isPushPermission: Bool {
        if UIApplication.shared.currentUserNotificationSettings?.types != [] {
            return true
        }
        return false
    }

    public class func requestPushPermission(silent: Bool = true, _ continueBlock: ((_ needShow:Bool)->())? = nil,complete:((Bool)->())? = nil) {
//        log.verbose("isPushPermission=\(isPushPermission)")
        guard !isPushPermission else {
            continueBlock?(false)
            complete?(true)
            return
        }

//        log.verbose("pushReqeusted=\(pushReqeusted)")
        if pushReqeusted {
            continueBlock?(true)
        } else {
            pushReqeusted = true
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]) { ret, error in
                complete?(ret)
            }
            continueBlock?(true)
        }
    }


}


