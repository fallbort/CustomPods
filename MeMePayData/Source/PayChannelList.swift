//
//  PayChannelList.swift
//  MeMe
//
//  Created by FengMengtao on 2018/7/25.
//  Copyright © 2018年 sip. All rights reserved.
//

import ObjectMapper
import SwiftyJSON
import MeMeKit
import StoreKit

public enum PayChannelKey: String {
    case appleiap = "appleiap"
}

/**
 des: 渠道列表
 */
public struct PayChannelList: Mappable, CustomStringConvertible  {
    
    public var channelsOrder: [String]?
    fileprivate var _channelsList: [ChannelInfo]?
    public var channelsInfo: [String: ChannelInfo]?
    
    public init() {
        
    }
    
    public init?(map: Map) {
        mapping(map: map)
    }
    
    mutating public func mapping(map: Map) {
        _channelsList <- map["list"]
        if let channelsList = _channelsList, channelsInfo == nil {
            channelsInfo = [:]
            channelsOrder = []
            for channel in channelsList {
                channelsInfo?[channel.channel] = channel
                channelsOrder?.append(channel.channel)
            }
        }
    }
    
    public var description: String {
        return "PayChannelList[channelsOrder=\(channelsOrder ??? unknown),channelsInfo=\(channelsInfo ??? unknown)]"
    }
}

/**
 des: 单个支付渠道的属性信息类
 */
public struct ChannelInfo: Mappable, CustomStringConvertible {
    
    public var packages: [ChannelProduct]?
    public var packageDict:[String:ChannelProduct]?
    public var attributes: ChannelAttributes?
    var channel:String = ""
    
    public var skProducts: [String: SKProduct]? // 每个productId 对应的SKProduct
    
    public init() {
        
    }
    
    public init?(map: Map) {
        
    }
    
    mutating public func mapping(map: Map) {
        channel <- map["channel"]
        packages <- map["products"]
        if attributes == nil {
            attributes = ChannelAttributes.init(map: map)
        }
        
        if let packages = packages {
            var dict:[String:ChannelProduct] = [:]
            for oneProduct in packages {
                dict[oneProduct.productId] = oneProduct
            }
            self.packageDict = dict
        }
        
    }
    
    fileprivate func skProductsDescription() -> String? {
        if let tmpSKProducts = skProducts {
            var productsString = "["
            for (key, tmpProduct) in tmpSKProducts {
                productsString += "\(key):\(tmpProduct.localizedDescription),"
            }
            productsString += "]"
            return productsString
        }
        
        return nil
    }
    
    public var description: String {
        return "ChannelInfo[packages=\(packages ??? unknown),attributes=\(attributes ??? unknown),skProducts=\(skProductsDescription() ??? unknown)]"
    }
}

/**
 des: 支付渠道的附加属性
 */
public struct ChannelAttributes: Mappable, CustomStringConvertible {

    public var profile: String = ""
    
    public init() {
        
    }
    
    public init?(map: Map) {
        
    }
    
    mutating public func mapping(map: Map) {
        profile <- map["logo"]
    }
    
    public var description: String {
        return "ChannelAttributes[]"
    }
}

/**
 des: 支付渠道的单个商品信息
 */
public struct ChannelProduct: Mappable, CustomStringConvertible {
    
    public var channelName: String = ""      // 渠道名称/字符串类型
    public var productId: String = ""        // 商品id
    public var currency: String = ""         // 货币类型号码 如 CN
    public var currencySymbol: String = ""   // 货币类型符号 如 ¥
    public var amount: String = ""           // 购买金额
    public var coin: String = ""           // 获得币

    
    public init() {
        
    }
    
    public init?(map: Map) {
        
    }
    
    mutating public func mapping(map: Map) {
        channelName <- map["description"]
        productId <- map["productId"]
        currency <- map["currency"]
        currencySymbol <- map["currency_symbol"]
        amount <- map["amount"]
        coin <- map["coin"]
    }
    
    public var description: String {
        return "ChannelProduct[channelName=\(channelName),productId=\(productId),currency=\(currency),amount=\(amount)]"
    }
}

