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
    static let pushToken = DefaultsKey<String?>("meme.apple.push.token")
    static let pushRequested = DefaultsKey<Bool>("meme.push.requested", defaultValue: false)
    static let alertDenial = DefaultsKey<Bool>("meme.push.alert.denial", defaultValue: false)
}

public class PushService {
    public static var pushToken: String? {
        get {
            return Defaults[key: DefaultsKeys.pushToken]
        }
        set {
            guard let newValue = newValue , newValue != pushToken else {
                return
            }
            Defaults[key: DefaultsKeys.pushToken] = newValue
        }
    }
    
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
    
    fileprivate(set) public static var denialAlert: Bool {
        get {
            return Defaults[key: DefaultsKeys.alertDenial]
        }
        set {
            guard newValue != denialAlert else {
                return
            }
            Defaults[key: DefaultsKeys.alertDenial] = newValue
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
    
    fileprivate class func showRequestAlert() {
        let appName = DeviceInfo.appDisplayName
        let title = String(format: NELocalize.localizedString("System prevents %@ to access notification",bundlePath: MeMeCustomPodsBundle, comment: ""), appName)
        let message = String(format: NELocalize.localizedString("To grant the permission: settings -> %@ -> notification",bundlePath: MeMeCustomPodsBundle, comment: ""), appName)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let actionCancel = UIAlertAction(title: NELocalize.localizedString("Do not ask again",bundlePath: MeMeCustomPodsBundle, comment: ""), style: .cancel) { action in
            PushService.denialAlert = true
        }
        alert.addAction(actionCancel)

        let actionSet = UIAlertAction(title: NELocalize.localizedString("Settings",bundlePath: MeMeCustomPodsBundle, comment: ""), style: .default) { action in
            if let URL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.openURL(URL as URL)
            }
        }
        alert.addAction(actionSet)

        ScreenUIManager.topViewController()?.present(alert, animated: true)
    }

    public class func cleanPushToken() {
        Defaults.remove(DefaultsKeys.pushToken)
    }

}


