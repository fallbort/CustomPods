//
//  PurchasedError.swift
//  MeMe
//
//  Created by FengMengtao on 2018/8/6.
//  Copyright © 2018年 sip. All rights reserved.
//

import ObjectMapper

public enum PurchasedErrorCode: Int {
    case invalidParams = 1001
    case invalidToken = 1002
    case getIAPProductFailed = 1003
    case IAPCantMakePurcahse = 1004
    case canceled = 1005
    case IAPVerifyFailedOther = 1006
    case IAPPurchaseFail = 1007
    case faildUnknown = 1008
    case getPreorderIdFailed = 1009
}

public struct PurchasedError: Mappable, PurchasedErrorProtocol {

    public var code = 0
    public var message = ""
    
    public init(code: PurchasedErrorCode) {
        self.code = code.rawValue
    }
    
    public init?(map: Map) {
    }
    
    mutating public func mapping(map: Map) {
        code <- map["code"]
    }
    
    public var description: String {
        return ""
    }
}
