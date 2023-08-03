//
//  ZGAppGlobalConfig.swift
//  MeMe
//
//  Created by 田家鑫 on 2021/7/19.
//  Copyright © 2021 sip. All rights reserved.
//

#if ZegoImported

import UIKit
import MeMeGlobals

struct ZGKeyCenter {
    static func appID(_ isProduction:Bool) -> UInt32 {
        if isProduction {
            return LSGlobals.ZegoAppID_product
        }else{
            return LSGlobals.ZegoAppID_dev
        }
    }
    
    static func appSign(_ isProduction:Bool) -> String {
        if isProduction {
            return LSGlobals.ZegoAppSign_product
        }else{
            return LSGlobals.ZegoAppSign_dev
        }
    }
}

#endif
