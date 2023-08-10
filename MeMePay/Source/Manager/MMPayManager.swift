//
//  MMPayManager.swift
//  MeMe
//
//  Created by admin on 2019/10/31.
//  Copyright © 2019 sip. All rights reserved.
//

import MeMeKit
import RxSwift

public class MMPayManager : PayProductDelegate{

    // MARK:out params
    
    public lazy var allIAPLoadedBehaviorObser:BehaviorSubject<(channel:[String:ChannelProduct]?,sk:[String:SKProduct]?)> = { [weak self] in  //所有苹果产品信息已获取
        var products:[String:SKProduct]?
        if let olds = try? PayService.shared.allIAPLoadedBehaviorObser.value() {
            products = olds
        }
        var channels:[String:ChannelProduct]?
        if let olds = try? PayService.shared.allChannelLoadedBehaviorObser.value() {
            channels = olds
        }
        let obser = BehaviorSubject<(channel:[String:ChannelProduct]?,sk:[String:SKProduct]?)>(value: (channels,products))
        
        Observable.combineLatest(PayService.shared.allChannelLoadedBehaviorObser,PayService.shared.allIAPLoadedBehaviorObser).subscribe(onNext:{ [weak self] (channels,products) in
            obser.onNext((channels,products))
        }).disposed(by: disposeBag)
        return obser
    }()
    
    public var subscribedProductsObser = PublishSubject<Void>()  //存储的已购订阅档位列表变更
    public var subscribedProductInfos:[SubscribePayRestoreInfo] {
        get {
            return PayService.shared.subscribedProductInfos
        }
    }
    
    // MARK:private params
    fileprivate var waitingPayTask:PayTask?
    fileprivate var loadedPayInfo:Bool = false
    fileprivate var loadingPayInfo:Bool = false
    
    fileprivate var payTask:PayTask?
    fileprivate var passthrough:String?
    
    fileprivate var payCompleteClosure:((_ success: Bool?,_ resultInfo:NEPurchaseResultInfo)->())?
    
    // MARK:init
    public init() {
        self.begin()
    }
    deinit {
        self.end()
    }
    
    // MARK:logic
    //此方法因为PayService.shared.addListener(observer: self)之前设计成会被其他类使用的妥协
    public func begin() {
        guard hasBegined == false else {return }
        hasBegined = true
        // 这个必须在支付之前添加
        PayService.shared.addListener(observer: self)
        
        if PayService.shared.channelList == nil {
            self.loadingPayInfo = true
            self.loadInfoClosure()
        }
        PayService.shared.allIAPLoadedBehaviorObser.subscribe(onNext:{ [weak self] skProducts in
            if self?.canRealStart() == true {
                self?.waitingPayTask = nil
                self?.realStartRecharge()
            }else if skProducts != nil {
                if self?.waitingPayTask != nil {
                    self?.waitingPayTask = nil
                    self?.buyDone(success: false,resultInfo: .none)
                }
            }
        }).disposed(by: disposeBag)
        PayService.shared.allChannelLoadedBehaviorObser.subscribe(onNext:{ [weak self] package in
            self?.loadingPayInfo = false
            guard let _ = package else {
                if self?.waitingPayTask != nil {
                    self?.waitingPayTask = nil
                    self?.buyDone(success: false,resultInfo: .none)
                }
                return
            }
            self?.loadedPayInfo = true
            if self?.canRealStart() == true {
                self?.waitingPayTask = nil
                self?.realStartRecharge()
            }
        }).disposed(by: disposeBag)
        PayService.shared.subscribedProductsObser.subscribe(onNext:{ [weak self] in
            self?.subscribedProductsObser.onNext(())
        }).disposed(by: disposeBag)
    }
    
    public func refreshIAPProductInfo(productId: String) {
        PayService.shared.loadCustomIAPProductInfo(productId: productId, requestKey: iAPRefreshKey + productId )
    }
    
    fileprivate func loadIAPProductInfo(productId: String) {
        PayService.shared.loadCustomIAPProductInfo(productId: productId, requestKey: iAPRequestKey + productId )
    }
    
    //productId与productIndex二选一
    public func startRecharge(productId:String?,productIndex:Int? = nil,isSubscribePay:Bool = false,depositKey:String?,depositId:String?,complete:@escaping ((_ success: Bool?,_ resultInfo:NEPurchaseResultInfo)->())) {
        var passthroughStr:String?
        if let depositKey = depositKey,let depositId = depositId {
            passthroughStr = "{\"\(depositKey)\":\"\(depositId)\"}"
        }else{
            gLog("pay depositKey=\(depositKey ?? ""),depositId=\(depositId ?? "")")
        }
        let task = PayTask(productIndex: productIndex, productId: productId,isSubscribePay: isSubscribePay)
        self.startRecharge(task: task, passthrough: passthroughStr, complete: complete)
    }
    public func startRecharge(productId:String?,productIndex:Int? = nil,isSubscribePay:Bool = false,passthrough:String? = nil,complete:@escaping ((_ success: Bool?,_ resultInfo:NEPurchaseResultInfo)->())) {
        let task = PayTask(productIndex: productIndex, productId: productId,isSubscribePay: isSubscribePay)
        self.startRecharge(task: task, passthrough: passthrough, complete: complete)
    }
    
    public func startRecharge(task:PayTask,passthrough:String? = nil,complete:@escaping ((_ success: Bool?,_ resultInfo:NEPurchaseResultInfo)->())) {
        guard waitingPayTask == nil else {
            complete(false,.none)
            return
        }
        self.payTask = task
        self.passthrough = passthrough
        self.payCompleteClosure = complete
    
        waitingPayTask = task
        if canRealStart() == true {
            waitingPayTask = nil
            self.realStartRecharge()
        }else{
            if loadingPayInfo == false {
                self.loadingPayInfo = true
                self.loadInfoClosure()
                if let productId = task.productId {
                    self.loadIAPProductInfo(productId: productId)
                }
            }
        }
    }
    
    fileprivate func canRealStart() -> Bool {
        guard waitingPayTask != nil else {
            return false
        }
        guard loadedPayInfo == true else {
            return false
        }
        var channels:[String:ChannelProduct]?
        if let oldChannels = try? PayService.shared.allChannelLoadedBehaviorObser.value() {
            channels = oldChannels
        }
        guard channels != nil else {
            return false
        }
        if let productId = waitingPayTask?.productId {
            var products:[String:SKProduct]?
            if let olds = try? PayService.shared.allIAPLoadedBehaviorObser.value() {
                products = olds
            }
            if products?[productId] == nil {
                return false
            }
        }
        return true
    }
    
    fileprivate func realStartRecharge() {
        guard let task = self.payTask else { return}
        self.payTask = nil
        let channel = PayChannelKey.appleiap
        if let isSubscribePay = task.isSubscribePay, let productIndex = task.productIndex {
            if let productInfo = PayService.shared.getProductInfo(channel: channel, byIndex: productIndex) {
                var productNew = productInfo.product
                if let currencyCode = productInfo.skProduct?.priceLocale.currencyCode, let money = productInfo.skProduct?.price.stringValue,channel == PayChannelKey.appleiap {
                    productNew.currency = currencyCode
                    productNew.amount = money
                }
                var extensionDict:[String: Any]? = nil
                if let passthrough = passthrough {
                    extensionDict = ["passthrough": passthrough]
                }
                PayService.shared.purchaseProduct(product: productNew, skProduct: productInfo.skProduct, channel: channel, channelAttr: productInfo.attributes,isSubscribePay:isSubscribePay,extensionDict: extensionDict)
            }else{
                buyDone(success: false,resultInfo: .none)
                gLog("get productInfo error,id=\(task.productId ?? ""),index=\(task.productIndex ?? -1)")
            }
        }else if let isSubscribePay = task.isSubscribePay, let productId = task.productId {
            if let skProduct = PayService.shared.getSKProductInfo(byProductId: productId) {
                var extensionDict:[String: Any]? = nil
                if let passthrough = passthrough {
                    extensionDict = ["passthrough": passthrough]
                }
                
                PayService.shared.purchaseProductByIAP(productId: productId, amount: skProduct.price.doubleValue, currency: skProduct.priceLocale.currencyCode ?? "", skProduct: skProduct,isSubscribePay:isSubscribePay, passthrough: extensionDict, ext: nil)
                if skProduct.priceLocale.currencyCode == nil {
                    gLog("currencyCode error,id=\(task.productId ?? ""),index=\(task.productIndex ?? -1)")
                }
            }else{
                buyDone(success: false,resultInfo: .none)
                gLog("get productInfo error,id=\(task.productId ?? ""),index=\(task.productIndex ?? -1)")
            }
        }else{
            buyDone(success: false,resultInfo: .none)
            gLog("task error,id=\(task.productId ?? ""),index=\(task.productIndex ?? -1)")
        }
        
    }
    
    // 支付完成后的事件，在这里处理
    fileprivate func buyDone(success: Bool?,resultInfo:NEPurchaseResultInfo) {
        self.payTask = nil
        if self.payCompleteClosure != nil {
            self.payCompleteClosure!(success,resultInfo)
            self.payCompleteClosure = nil
            if success == false {
                gLog("buy error")
            }
        }
    }
    
    fileprivate func end() {
        guard hasEnded == false else {return}
        hasEnded = true
        PayService.shared.removeListener(observer: self)
        self.payCompleteClosure = nil
        self.payTask = nil
    }
    
    // MARK: delegate
    
    public func customPurchasedCompleted(success: Bool?,resultInfo:NEPurchaseResultInfo, productId: String, error: MemeCommonError?) {
        buyDone(success: success,resultInfo: resultInfo)
    }
    
    public func customProductsLoaded(iapProducts: [SKProduct]?, requestKey: String) {
        if let productId = waitingPayTask?.productId {
            let oldKey = iAPRequestKey + productId
            if iapProducts == nil,oldKey == requestKey {
                self.waitingPayTask = nil
                self.buyDone(success: false,resultInfo: .none)
            }
        }
    }
    
    fileprivate var hasBegined = false
    fileprivate var hasEnded = false
    
    //内部block
    var loadInfoClosure:(()->()) = {
        PayService.shared.loadChannelAndProductList()
    }
    
    private let disposeBag = DisposeBag()
    
    private let iAPRequestKey = "paymanagerRequest"
    private let iAPRefreshKey = "paymanagerRefresh"
}
