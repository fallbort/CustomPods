//
//  PayTask.swift
//  MeMeMainPayData
//
//  Created by robot on 2022/5/17.
//

import Foundation

public struct PayTask {
    public var productIndex: Int?
    public var productId: String?
    public var isSubscribePay: Bool? //是否订阅类型
    
    public init(productIndex: Int?, productId: String?, isSubscribePay:Bool?) {
        self.productIndex = productIndex
        self.productId = productId
        self.isSubscribePay = isSubscribePay
    }
}
