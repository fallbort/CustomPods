//
//  LocalNotificationUtils.swift
//  MeMe
//
//  Created by funplus on 2017/2/23.
//  Copyright © 2017年 sip. All rights reserved.
//

import UIKit
import MeMeKit
public class LocalNotificationUtils: NSObject {
    public class func add(fireDate: Date, alertBody: String, userInfo: [String: Any]) {
        let localNoti = UILocalNotification()
        localNoti.fireDate = fireDate
        localNoti.timeZone = TimeZone.current
        localNoti.alertBody = alertBody
        localNoti.soundName = UILocalNotificationDefaultSoundName
        localNoti.applicationIconBadgeNumber = 1
        localNoti.userInfo = userInfo
        UIApplication.shared.scheduleLocalNotification(localNoti)
    }

    @discardableResult
    public class func deleteNotification(type: String) -> Bool {
        var ret = false
        if let locals = UIApplication.shared.scheduledLocalNotifications {
            for localNoti in locals {
                if let dict = localNoti.userInfo {
                    if dict.keys.contains("type") && dict["type"] is String && (dict["type"] as! String) == type {
                        UIApplication.shared.cancelLocalNotification(localNoti)
                        ret = true
                    }
                }
            }
        }
        return ret
    }


    public class func deleteUserRegister() {
        LocalNotificationUtils.deleteNotification(type: "userRegister")
    }
}
