//
//  BankService.swift
//  MeMe
//
//  Created by 邢海华 on 16/6/22.
//  Copyright © 2016年 sip. All rights reserved.
//

import Foundation
import RxSwift
import Result
import MeMeKit
import ObjectMapper


public class BankService {

    /// 充值回执
    ///
    /// - Parameters:
    ///   - productId: 商品id
    ///   - amount: 价格
    ///   - currency: 货币类型 人民币 美元 。。。
    ///   - receipt: 苹果订单回执标记
    ///   - adid: 唯一标识
    ///   - isSubscribePay: 是否是订阅支付
    ///   - extParamater: 回执拓展字段
    public class func deposit(productId: String, amount: Double, currency: String, receipt: String, preorderId:String?,transactionId:String, toUid: Int?, isSubscribePay:Bool ,extParamater: [String: Any]? = nil, passthrough: String? = nil, completion: @escaping (Result<UserBank, MemeCommonError>) -> Void) {
        // deposit { sessionToken:%s, type:%s, amount:%f, currency:%s, receipt:%s, adID:%s }
        // { ticket:%d, diamond:%d, depositCount:%d }   //-- 购买之后的balance和总充值次数
        var params: [String: Any] = ["channel": "appleiap", "receipt": receipt, "amount": amount, "currency": currency ,"productId": productId, "language": LanguageService.currentLanguageCode,"transactionId":transactionId,"countryCode":"zh_CN"]
        if let extParamater = extParamater {
            params.merge(with: extParamater)
        }

        if let preorderId = preorderId {
            params["preorderId"] = preorderId
        }

        if let passthrough = passthrough {
            params["passthrough"] = passthrough
        }
        
        MMPayConfig.requestBlock(.deposit,params) { result in
            switch result {
            case let .success(info):
                if let userBank = Mapper<UserBank>().map(JSONObject: info) {
                    MMPayConfig.balanceChangedBlock(userBank.balance)
                    completion(.success(userBank))
                } else {
                    completion(.failure(.network))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    public class func getPayChannelList(completion: @escaping ((Result<PayChannelList?, MemeCommonError>) -> Void)) {
        MMPayConfig.requestBlock(.payList,[:]) { result in
            switch result {
            case let .success(info):
                if let packet = Mapper<PayChannelList>().map(JSONObject: info) {
                    completion(.success(packet))
                } else {
                    completion(.success(nil))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    public class func preOrder(productId:String,amount:Double,currency:String, passthrough:String, detail: String, completion: @escaping (Result<String?, MemeCommonError>)->Void) {
        let params: [String: Any] = ["channel":"appleiap","productId":productId,"appid":"10001", "amount":"\(amount)","currency":currency,"passthrough":passthrough,"sign":"","detail": detail]
        
        MMPayConfig.requestBlock(.preOrder,params) { result in
            switch result {
            case let .success(info):
                if let dict = info as? [String:Any], let preorderId = dict["orderId"] as? String {
                    completion(.success(preorderId))
                } else {
                    completion(.failure(.network))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
}

