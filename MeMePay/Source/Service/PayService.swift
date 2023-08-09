//
//  PayService.swift
//  MeMe
//
//  Created by FengMengtao on 2018/7/26.
//  Copyright © 2018年 sip. All rights reserved.
//

import ObjectMapper
import Result
import SwiftyJSON
import MeMeKit
import RxSwift

private let FunBankDuplicatedCode = 3006
private let GetDefaultIAPProductsListKey: String = "GetDefaultIAPProductsListKey"
private let GetFirstChargeIAPProductsKey: String = "GetFirstChargeIAPProductsKey"

public protocol PayProductDelegate {
    func customProductsLoaded(iapProducts: [SKProduct]?, requestKey: String)
    func customPurchasedCompleted(success: Bool?,resultInfo:NEPurchaseResultInfo, productId: String, error: MemeCommonError?)
}

public class PayService: NSObject {
    
    public static var shared: PayService = PayService()
    
    public var productsLoaded:((_ channelList: PayChannelList?)->Void)?
    public var purchasedCompleted: ((_ success: Bool, _ product: ChannelProduct?, _ error: MemeCommonError?)->Void)?
    public var startLastFailedOrder: VoidBlock?
    
    public lazy var allChannelLoadedBehaviorObser:BehaviorSubject<[String:ChannelProduct]?> = {  //所有服务器中的商品信息已获取
        let products = channelList?.channelsInfo?[PayChannelKey.appleiap.rawValue]?.packageDict
        let obser = BehaviorSubject<[String:ChannelProduct]?>(value: products)
        return obser
    }()
    public lazy var allIAPLoadedBehaviorObser:BehaviorSubject<[String:SKProduct]?> = {  //所有苹果产品信息已获取
        let products = channelList?.channelsInfo?[PayChannelKey.appleiap.rawValue]?.skProducts
        let obser = BehaviorSubject<[String:SKProduct]?>(value: products)
        return obser
    }()
    public var channelList: PayChannelList?
    public var _channelList: PayChannelList?
    public var allChannelList: PayChannelList?
    fileprivate var allCustomSkProducts:[String:SKProduct] = [:]
    public var isloadingChannelList = false
    
    // 底层支付SDK
    fileprivate var payKit: NEPayKit?
    
    fileprivate var currentOrders: [PayChannelKey: ChannelProduct] = [:]
    fileprivate var losingOrders: [String: [LosingOrderInfo]] = [:]
    
    fileprivate var callbackStr: String? // 用于记录微信的回调请求链接
    
    // 监听获取苹果商品信息回调、支付成功失败回调
    fileprivate var delegates = WeakReferenceArray<PayProductDelegate>()
    
    public var firstChargeProductsLoaded: ((_ products: [SKProduct]?) -> Void)?
    
    fileprivate var currencyGlobal: String? // 用于打点记录数据

    public var subscribedProductInfos:[SubscribePayRestoreInfo] {
        get {
            return restoreObject.getRestoreInfos()
        }
    }
    public var subscribedProductsObser = PublishSubject<Void>()  //存储的已购订阅档位列表变更
    fileprivate lazy var restoreObject:SubscribePayRestoreObject = {
        let object = SubscribePayRestoreObject()
        object.changedBlock = { [weak self] in
            self?.subscribedProductsObser.onNext(())
        }
        return  object
    }()
    
    fileprivate var loadLosingDelayDispatch: DispatchWorkItem?
    
    override public init() {
        super.init()
        payKit = NEPayKit.shared()
        payKit?.setup()
        restoreObject.setup()
    }
    
    public func setup() {
        payKit?.delegate = self
        payKit?.iapReceiptiOS7HigherFormat = true
        payKit?.cacheOrderPath = purchasedItemsURL()  // 设置appleiap未完成订单的存储路径;与老版本同路径;避免新老版本兼容问题
        payKit?.enableListener = true
        
        PayService.traceIAPPaymentStatus(step: 200, productId: nil, amount: nil, currency_now: nil, currency_global: nil, server_json: "willFinishLaunchingWithOptions")
    }
    
    public func sovleLastFailedTransaction() {
        payKit?.sovleLastFailedTransaction()
    }
    
    public func loadChannelAndProductList() {
        guard isloadingChannelList == false else {
            return
        }
        isloadingChannelList = true
        self.currencyGlobal = nil
        
        let resultBlock:((_ normResult:Result<PayChannelList?, MemeCommonError>,_ allResult:Result<PayChannelList?, MemeCommonError>) -> ()) = { [weak self] (result,result2) in
            self?.isloadingChannelList = false
            if case var .success(package) = result,case var .success(package2) = result2 {
                // BI log: 1.记录纯的从服务来的数据
                PayService.traceIAPPaymentStatus(step: 1, productId: nil, amount: nil, currency_now: nil, currency_global: nil, server_json: package?.description)
                
                if let channels = package?.channelsOrder {
                    for channel in channels {
                        if PayChannelKey(rawValue: channel) == nil {
                            if let index = package?.channelsOrder?.index(of: channel), index < channels.count {
                                package?.channelsOrder?.remove(at: index)
                            }
                            package?.channelsInfo?.removeValue(forKey: channel)
                        }
                    }
                }
                
                if let channels = package2?.channelsOrder {
                    for channel in channels {
                        if PayChannelKey(rawValue: channel) == nil {
                            if let index = package2?.channelsOrder?.index(of: channel), index < channels.count {
                                package2?.channelsOrder?.remove(at: index)
                            }
                            package2?.channelsInfo?.removeValue(forKey: channel)
                        }
                    }
                }
                if var iapAllList = package2?.channelsInfo?[PayChannelKey.appleiap.rawValue],let customProducts = self?.allCustomSkProducts {
                    if iapAllList.skProducts != nil {
                        iapAllList.skProducts?.merge(with: customProducts)
                    }else{
                        iapAllList.skProducts = customProducts
                    }
                    package2?.channelsInfo?[PayChannelKey.appleiap.rawValue] = iapAllList
                }
                
                // BI log: 2.记录从服务来的数据经过重组之后的数据
                PayService.traceIAPPaymentStatus(step: 2, productId: nil, amount: nil, currency_now: nil, currency_global: nil, server_json: package?.description)
                
                self?.channelList = package
                self?._channelList = package
                self?.productsLoaded?(package)
                self?.allChannelList = package2
                self?.allChannelLoadedBehaviorObser.onNext(package2?.channelsInfo?[PayChannelKey.appleiap.rawValue]?.packageDict)
                if let _ = package2?.channelsInfo?[PayChannelKey.appleiap.rawValue] {
                    // 如果能查询到苹果支付方式，那么需要拉取苹果商品信息
                    self?.loadIAPProducts()
                }
            }else{
                self?.productsLoaded?(nil)
                self?.allChannelLoadedBehaviorObser.onNext(nil)
            }
        }
        
        BankService.getPayChannelList { [weak self] result in
            resultBlock(result,result)
        }
    }

    
    // 现在不用缓存，在充值页面退出时，清掉缓存
    public func cleanCache() {
        self.channelList = nil
        self.allChannelList = nil
        self.allCustomSkProducts.removeAll()
        self.allChannelLoadedBehaviorObser.onNext(nil)
        self.allIAPLoadedBehaviorObser.onNext(nil)
        self.productsLoaded = nil
        self.purchasedCompleted = nil
        self.startLastFailedOrder = nil
    }
    
    public func switchUserCleanCache() {
        cleanCache()
        self.currentOrders.removeAll()
        self.currencyGlobal = nil
        self.payKit?.cleanCache()
        
        PayService.traceIAPPaymentStatus(step: 302, productId: nil, amount: nil, currency_now: nil, currency_global: nil, server_json: "switchUserCleanCache")
    }
    
    fileprivate func loadIAPProducts() {
        payKit?.delegate = self
        guard let products = allChannelList?.channelsInfo?[PayChannelKey.appleiap.rawValue]?.packages else {
            return
        }

        let productIds = products.map({ $0.productId })
        payKit?.loadAppleIAPProducts(productIds, requestKey: GetDefaultIAPProductsListKey)
    }
}

extension PayService {
    
    public func loadIAPProducts(productIds: [String]) {
        payKit?.loadAppleIAPProducts(productIds, requestKey: GetFirstChargeIAPProductsKey)
    }
    
    public func getSKProductInfo(byProductId: String?) -> SKProduct? {
        guard let byProductId = byProductId, let channelList = allChannelList, let channelInfo = channelList.channelsInfo?[PayChannelKey.appleiap.rawValue] else {
            return nil
        }
        
        let skProduct: SKProduct? = channelInfo.skProducts?[byProductId]
        return skProduct
    }
    
    public func getIAPProductInfo(byProductId: String?) -> (product:ChannelProduct, skProduct:SKProduct?,attributes:ChannelAttributes?)? {
        guard let byProductId = byProductId, let channelList = allChannelList, let channelInfo = channelList.channelsInfo?[PayChannelKey.appleiap.rawValue] else {
            return nil
        }
        
        guard let product: ChannelProduct = channelInfo.packages?.filter({ $0.productId == byProductId }).first else {
            return nil
        }
        let skProduct: SKProduct? = channelInfo.skProducts?[byProductId]
        return (product, skProduct,channelInfo.attributes)
    }
    
    public func getProductInfo(channel:PayChannelKey,byIndex: Int?) -> (product:ChannelProduct, skProduct:SKProduct?,attributes:ChannelAttributes?)? {
        guard let byIndex = byIndex, let channelList = allChannelList, let channelInfo = channelList.channelsInfo?[channel.rawValue] else {
            return nil
        }
        
        guard let packages = channelInfo.packages,byIndex < packages.count else {
            return nil
        }

        let product: ChannelProduct = packages[byIndex]
        let skProduct: SKProduct? = channelInfo.skProducts?[product.productId]
        return (product, skProduct,channelInfo.attributes)
    }
}

extension PayService {
    
    // MARK: 充值页外 支付相关的功能
    
    public func addListener(observer: PayProductDelegate) {
        delegates.addObject(observer)
    }
    
    public func removeListener(observer: PayProductDelegate) {
        delegates.removeObject(observer)
    }
    
    /**
     des: 在充值页外，获取iap 商品信息的接口
     - parameter: productId  商品id
     - parameter: requestKey 自定义的唯一id，用于判断回来的信息是否是自己需要处理的数据; 必填参数
     */
    public func loadCustomIAPProductInfo(productId: String, requestKey: String) {
        
        // 先从充值页商品列表检查一下，是否有需要的数据，如果有直接返回，不用走苹果查询了
        if let product = getSKProductInfo(byProductId: productId) {
            self.delegates.excuteObject({ weakDelegate in
                weakDelegate?.customProductsLoaded(iapProducts: [product], requestKey: requestKey)
            })
            return
        }
        
        // 拉取苹果的信息
        payKit?.loadAppleIAPProducts([productId], requestKey: requestKey)
    }
    
}

extension PayService {
    
    // MARK: - 购买商品
    
    /**
     des: 通过 ChannelProduct来进行购买商品; 传递所有的相关的ChannelProduct，以及ChannelAttributes信息;
     - parameter: product  从服务器接口获得的product信息
     - parameter: skProduct 这个是IAP支付时，购买的IAP商品信息,这个如果外层有的话，最好带上，可以减少重新获取的时间; 外层最好带上！！！
     - parameter: channel  通过哪个渠道进行购买
     - parameter: channelAttr  当前渠道相关的属性信息;主要跳转h5页面的渠道需要用到profile这个字段的数据
     - parameter: extensionDict  其他的额外的字段
     - parameter: isSubscribePay  是否是订阅类型
     */
    public func purchaseProduct(product: ChannelProduct,
                         skProduct: SKProduct? = nil,
                         channel: PayChannelKey,
                         channelAttr: ChannelAttributes? = nil,
                         isSubscribePay:Bool,
                         extensionDict: [String: Any]? = nil,
                         needStore: Bool = false,
                         ext: [String: Any]? = nil) { // 是否需要存储

        guard let money = Double(product.amount), money > 0 else {
            finishedPurchased(success: false,
                              resultInfo: .none,
                              channel: channel,
                              productId: product.productId,
                              amount: nil,
                              currency: product.currency,
                              error: MemeCommonError.normal(code: PurchasedErrorCode.invalidParams.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true))
            return
        }
        
        currentOrders[channel] = product
        
        if channel == .appleiap {
            purchaseProductByIAP(productId: product.productId, amount: money, currency: product.currency, skProduct: skProduct,isSubscribePay:isSubscribePay, passthrough: extensionDict, ext: ext)
        }
    }
    
    /**
     des: 苹果支付
     - parameter: productId 商品ID
     - parameter: amount  金额
     - parameter: currency 货币类型代码;这个用于后续的验签环节，必须要带上;
     - parameter: skProduct 这个是IAP支付时，购买的IAP商品信息,这个如果外层有的话，最好带上，可以减少重新获取的时间; 外层最好带上！！！
     - parameter: passthrough 额外首充拉新需要传递的字段
     - parameter: isSubscribePay  是否是订阅类型
     */
    public func purchaseProductByIAP(productId: String,
                              amount: Double,
                              currency: String,
                              skProduct: SKProduct? = nil,
                              isSubscribePay:Bool,
                              passthrough: [String: Any]? = nil,
                              ext: [String: Any]? = nil) {
//         guard let uid = LocalUserService.currentAccount?.id else
        guard let uid = Optional(MeMeKitConfig.userIdBlock()),uid > 0 else {
            finishedPurchased(success: false,
                              resultInfo: .none,
                              channel: PayChannelKey.appleiap,
                              productId: productId,
                              amount: amount,
                              currency: currency,
                              error: MemeCommonError.auth)
            return
        }
        
        if let hasLastOrder = payKit?.sovleLastFailedTransaction(), hasLastOrder {
            MeMeKitConfig.showHUDBlock("restore unfinished order.")
            delegates.excuteObject { weakDelegate in
                weakDelegate?.customPurchasedCompleted(success: nil,resultInfo:.restore, productId: productId, error: nil)
            }
            return
        }
        
        var passthroughNew: [String : Any] = ["language": LanguageService.currentLanguageCode]
        if var passthrough = passthrough {
            if var passthroughStr = passthrough["passthrough"] as? String,var passthroughObject = passthroughStr.convertToDictionary() {
                passthroughObject["deviceId"] = DeviceInfo.deviceId
                passthroughStr = passthroughObject.toJsonString() ?? ""
                passthrough["passthrough"] = passthroughStr
            }
            passthroughNew.merge(with: passthrough)
        }
        
        let order = NEPayOrderItem()
        order.productId = productId
        order.price = amount
        order.currency = currency
        order.currentUserId = "\(uid)"
        order.isSubscribePay = isSubscribePay
        
        if let skProduct = skProduct {
            order.product = skProduct
        }
        
        let extJson = JSON(passthroughNew)
        if let extStr = extJson.rawString() {
            order.extension = extStr
        }
        
        if var ext = ext {
            ext["deviceId"] = DeviceInfo.deviceId
            if let extstring = JSON(ext).rawString() {
                order.extensionString = extstring
            }
        }
        
        // BI log: 20. 开启一个苹果支付
         let passthroughStr:String = order.extensionString == nil ? ((passthrough?["passthrough"] as? String) ?? "") : (order.extensionString ?? "")
        PayService.traceIAPPaymentStatus(step: 20, productId: productId, amount: amount, currency_now: currency, currency_global: currencyGlobal, server_json: passthroughStr, ext: order.extension)
        BankService.preOrder(detail: PayService.getLogJsonString(productId: productId,passthrough:passthroughStr, isBadOrder: false)) { [weak self] result in
            switch result {
            case .success(let orderId):
                order.preorderId = orderId
                self?.payKit?.startPurchaseProduct(order, payChannel: NEPayChannel.appleIAP)
                break
            case .failure(_):
                self?.finishedPurchased(success: false,
                                        resultInfo: .none,
                                        channel: PayChannelKey.appleiap,
                                        productId: productId,
                                        amount: amount,
                                        currency: currency,
                                        error: MemeCommonError.normal(code: PurchasedErrorCode.getPreorderIdFailed.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true))
                break
            }
        }
    }

    fileprivate func finishedPurchased(success: Bool,
                                       resultInfo:NEPurchaseResultInfo,
                                       channel: PayChannelKey?,
                                       productId: String?,
                                       amount: Double?,
                                       currency: String?,
                                       preorderId: String? = nil,
                                       payKitResponseCode: Int? = nil,
                                       error: MemeCommonError?) {
        
        if !success {
            // BI log: 100. 支付失败的情况都记录；这里记录错误码
            PayService.traceIAPPaymentStatus(step: 100, productId: productId, amount: amount, currency_now: currency, currency_global: currencyGlobal, server_json: "[errorCode:\(error?.errorCode ??? unknown),response code:\(payKitResponseCode ??? unknown)]", preorderId: preorderId)
        } else {

        }
        
        guard let channel = channel else {
            return
        }
        purchasedCompleted?(success, currentOrders[channel], nil)
        currentOrders.removeValue(forKey: channel)
        
        
        if let productId = productId {
//            if success {
//                ControlService.shared.setOpen(false, controlType: .FirstRecharge)
//            }
            delegates.excuteObject { weakDelegate in
                weakDelegate?.customPurchasedCompleted(success: success,resultInfo:resultInfo, productId: productId, error: error)
            }
        }
    }
    
    //isRepeat为是否重复订单
    fileprivate func verifyReceipt(order: NEPayOrderItem?, transaction: SKPaymentTransaction?, extParamater: [String: Any]?, completion: @escaping ((Bool,_ isRepeat:Bool)->Void)) {
        if let order = order, let productId = order.productId, let currency = order.currency {
//            var toUid: Int? = LocalUserService.currentAccount?.id
            var toUid: Int? = MeMeKitConfig.userIdBlock()
            if let tmpUid = order.currentUserId {
                toUid = Int(tmpUid)
            }
            let receipt: String = order.iapRecepit ?? ""
            let transactionId = transaction?.transactionIdentifier ?? "0"
            
            // BI log: 21. 苹果支付成功
            PayService.traceIAPPaymentStatus(step: 21,
                                             productId: productId,
                                             amount: order.price,
                                             currency_now: currency,
                                             restoreFromFailedOrder: order.isRestoreFromLastFailedOrder,
                                             currency_global: currencyGlobal,
                                             server_json: nil,
                                             depositUid: toUid,
                                             receiptIsNil: order.iapRecepit == nil,
                                             transactionId: transaction?.transactionIdentifier,
                                             preorderId: order.preorderId,
                                             ext: order.extension)
            
            
            BankService.deposit(productId: productId,
                                amount: order.price,
                                currency: currency,
                                receipt: receipt,
                                preorderId: order.preorderId,
                                transactionId:transactionId,
                                toUid: toUid,
                                isSubscribePay:order.isSubscribePay,
                                extParamater: extParamater,
                                passthrough: order.extensionString) { [weak self] result in
                switch result {
                case .success(let userBank):
                    self?.restoreObject.dealedTransaction(transaction:transaction,isSuccess:true,isDuplicated:false)
                    completion(true,false)
                    
                    var transactionId = ""
                    if let tid = transaction?.transactionIdentifier {
                        transactionId = tid
                    }
                    
                    var extString = transactionId
                    if let transactionTime = transaction?.transactionDate?.timeIntervalSince1970 {
                        extString += "\(transactionTime)"
                    }
                    
                    // BI log: 31. 苹果支付成功
                    PayService.traceIAPPaymentStatus(step: 31,
                                                     productId: productId,
                                                     amount: order.price,
                                                     currency_now: currency,
                                                     restoreFromFailedOrder: order.isRestoreFromLastFailedOrder,
                                                     currency_global: self?.currencyGlobal,
                                                     server_json: userBank.description,
                                                     depositUid: toUid,
                                                     transactionId: transaction?.transactionIdentifier,
                                                     preorderId: order.preorderId,
                                                     ext: extString)
                    
                    // Adjust 打点
                    // adjust pay user
//                    if let depositCount = result.value?.depositCount, depositCount == 1 {
//                        AdjustTracker.track(eventToken: .payingUser, price: order.price, currency: currency, transactionIdentifier: transactionId)
//                    }
//                    AdjustTracker.track(eventToken: .revenue, price: order.price, currency: currency, transactionIdentifier: transactionId)
//                    TraceCustomTracker.tracePayment(productId: productId, price: order.price, currency: currency, transactionId: transactionId)
                    // 回头问下，这个product是不是必须的，如果不是这里不需要加了。
                case .failure(let error):
                    //if not duplicated, the transaction will stay inflight
                    //it will give another try when next purchase or next launch
                    if let dulpicate = self?.checkDuplicatedTransaction(error: error), dulpicate {
                        // 如果是重复订单
                        
                        // BI log: 33. fpnn重复订单
                        PayService.traceIAPPaymentStatus(step: 33,
                                                         productId: productId,
                                                         amount: order.price,
                                                         currency_now: currency,
                                                         restoreFromFailedOrder: order.isRestoreFromLastFailedOrder,
                                                         currency_global: self?.currencyGlobal,
                                                         server_json: error.localizedDescription,
                                                         depositUid: toUid,
                                                         transactionId: transaction?.transactionIdentifier,
                                                         preorderId: order.preorderId)
                        gLog("repeat_buy,productId=\(productId),extParamater=\(extParamater ?? [:]),passthrough=\(order.extensionString ?? "")")
                        self?.restoreObject.dealedTransaction(transaction:transaction,isSuccess:true,isDuplicated:true)
                        gLog("depositError,dulpicate,productId=\(productId),extParamater=\(extParamater ?? [:]),passthrough=\(order.extensionString ?? ""),errorCode=\(error.errorCode)")
                        completion(true,true)
                        return
                    } else {
                        gLog("depositError,not clean,productId=\(productId),extParamater=\(extParamater ?? [:]),passthrough=\(order.extensionString ?? ""),errorCode=\(error.errorCode)")
                        self?.restoreObject.dealedTransaction(transaction:transaction,isSuccess:false,isDuplicated:false)
                        completion(false,false)
                    }
                    
                    // BI log: 32. deposit支付验证失败
                    PayService.traceIAPPaymentStatus(step: 32,
                                                     productId: productId,
                                                     amount: order.price,
                                                     currency_now: currency,
                                                     restoreFromFailedOrder: order.isRestoreFromLastFailedOrder,
                                                     currency_global: self?.currencyGlobal,
                                                     server_json: error.localizedDescription,
                                                     depositUid: toUid,
                                                     transactionId: transaction?.transactionIdentifier,
                                                     preorderId: order.preorderId)
                }
            }
        } else {
            // 如果是坏账，那直接结束吧。没招啊。
            PayService.traceIAPPaymentStatus(step: 203, productId: "", amount: nil, currency_now: nil, currency_global: nil, server_json: "verifyReceipt坏账结束")
            completion(true,false)
            
            // BI log: 22. 苹果支付成功
            PayService.traceIAPPaymentStatus(step: 22,
                                             productId: transaction?.payment.productIdentifier,
                                             amount: order?.price,
                                             currency_now: order?.currency,
                                             restoreFromFailedOrder: order?.isRestoreFromLastFailedOrder,
                                             currency_global: currencyGlobal,
                                             server_json: "order is nil:\(order == nil)",
                receiptIsNil: order?.iapRecepit == nil,
                transactionId: transaction?.transactionIdentifier,
                preorderId: nil)
        }
    }
}

extension PayService: NEPayDelegate {
    
    // MARK: - 支付相关回调
    
    public func appleIAPProductsLoaded(_ products: [SKProduct]?, requestKey:String?, error: Error?) {
        if requestKey == GetFirstChargeIAPProductsKey {
            firstChargeProductsLoaded?(products)
        } else if requestKey == GetDefaultIAPProductsListKey {
            if var iapList = channelList?.channelsInfo?[PayChannelKey.appleiap.rawValue],var iapAllList = allChannelList?.channelsInfo?[PayChannelKey.appleiap.rawValue]  {
                if let products = products {
                    
                    iapList.skProducts = Dictionary(uniqueKeysWithValues: products.filter({ (oneProduct) -> Bool in
                        return iapList.packages?.contains(where: {$0.productId == oneProduct.productIdentifier}) == true
                    }).map({ ($0.productIdentifier, $0) }))
                    
                    if iapAllList.skProducts != nil {
                        iapAllList.skProducts?.merge(with: Dictionary(uniqueKeysWithValues: products.map({ ($0.productIdentifier, $0) })))
                    }else{
                        iapAllList.skProducts = Dictionary(uniqueKeysWithValues: products.map({ ($0.productIdentifier, $0) }))
                    }
                    
                    // 获取appid所在地区的货币类型
                    if products.count > 0 {
                        let product = products[0]
                        currencyGlobal = product.priceLocale.currencyCode
                    }
                }
                channelList?.channelsInfo?[PayChannelKey.appleiap.rawValue] = iapList
                allChannelList?.channelsInfo?[PayChannelKey.appleiap.rawValue] = iapAllList
                
                productsLoaded?(channelList)
                
                if products != nil {
                    allIAPLoadedBehaviorObser.onNext(iapAllList.skProducts)
                }
                
                // BI log: 3.记录从苹果服务器请求回来的商品列表数据
                PayService.traceIAPPaymentStatus(step: 3,
                                                 productId: nil,
                                                 amount: nil,
                                                 currency_now: nil,
                                                 currency_global: currencyGlobal,
                                                 server_json: channelList?.description)
            }
        } else if let requestKey = requestKey, let orderItems = losingOrders[requestKey] {
            guard let products = products else {
                return
            }
            if let product = products.first(where: {$0.productIdentifier == orderItems.first?.item?.productId}) {
                losingOrders.removeValue(forKey: requestKey)
                for orderItem in orderItems {
                    orderItem.item?.price = product.price.doubleValue
                    orderItem.item?.currency = product.priceLocale.currencyCode ?? ""
                    
                    var extParamater: [String: Any]?
                    if orderItem.item?.extensionString == nil {
                        if let extStr = orderItem.item?.extension {
                            let jsonString = JSON(parseJSON: extStr)
                            if let extDict = jsonString.dictionaryObject {
                                extParamater = extDict
                            }
                        }
                    }
                    let passthroughStr:String = orderItem.item?.extensionString == nil ? ((extParamater?["passthrough"] as? String) ?? "") : (orderItem.item?.extensionString ?? "")
                    BankService.preOrder(detail: PayService.getLogJsonString(productId: product.productIdentifier,passthrough:passthroughStr, isBadOrder: true)) { [weak self] result in
                        switch result {
                        case .success(let preorderId):
                            orderItem.item?.preorderId = preorderId
                            self?.verifyReceipt(order: orderItem.item, transaction: orderItem.transaction, extParamater: nil) { (success,isRepeat) in
                                orderItem.completion?(success,isRepeat)
                            }
                        case .failure(_):
                            self?.finishedPurchased(success: false,
                                                    resultInfo: .none,
                                                    channel: PayChannelKey.appleiap,
                                                    productId: orderItem.item?.productId,
                                                    amount: orderItem.item?.price,
                                                    currency: orderItem.item?.currency,
                                                    preorderId: orderItem.item?.preorderId,
                                                    error: MemeCommonError.normal(code: PurchasedErrorCode.getPreorderIdFailed.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true))
                        }
                    }
                }
            }
        } else if let requestKey = requestKey {
            // 自定义的拉取
            if var iapAllList = allChannelList?.channelsInfo?[PayChannelKey.appleiap.rawValue] {
                if let products = products {
                    if iapAllList.skProducts != nil {
                        iapAllList.skProducts?.merge(with: Dictionary(uniqueKeysWithValues: products.map({ ($0.productIdentifier, $0) })))
                    }else{
                        iapAllList.skProducts = Dictionary(uniqueKeysWithValues: products.map({ ($0.productIdentifier, $0) }))
                    }
                    for product in products {
                        allCustomSkProducts[product.productIdentifier] = product
                    }
                    
                }
                allChannelList?.channelsInfo?[PayChannelKey.appleiap.rawValue] = iapAllList

                if products != nil {
                    allIAPLoadedBehaviorObser.onNext(iapAllList.skProducts)
                }
            }else{
                if let products = products {
                    for product in products {
                        allCustomSkProducts[product.productIdentifier] = product
                    }
                    
                }
            }
            self.delegates.excuteObject { weakDelegate in
                weakDelegate?.customProductsLoaded(iapProducts: products, requestKey: requestKey)
            }
        }
    }
    
    public func startReSolveLastUnfinishedOrder(_ item: NEPayOrderItem) {
        startLastFailedOrder?()
    }
    
    public func purchasedIAPProductVerify(_ order: NEPayOrderItem?, transaction: SKPaymentTransaction?, finish: FinishPurchasesCompletionBlock?) {
        
        var extParamater: [String: Any]?
        if let extStr = order?.extension {
            let jsonString = JSON(parseJSON: extStr)
            if let extDict = jsonString.dictionaryObject {
                extParamater = extDict
            }
        }
        
        if order?.currency == nil {
            // 产生坏账的可能记录，未必有坏账，如果后面有成功处理，就不会有坏账情况；如果处理出现问题，就可能产生坏账；
            PayService.traceIAPPaymentStatus(step: 23,
                                             productId: order?.productId,
                                             amount: order?.price,
                                             currency_now: order?.currency,
                                             currency_global: currencyGlobal,
                                             server_json: nil,
                                             receiptIsNil: order?.iapRecepit == nil,
                                             transactionId: transaction?.transactionIdentifier,
                                             preorderId: order?.preorderId,
                                             ext: order?.extension)
        }
        
        if let order = order, order.currency == nil {
            if let currentCacheOrder = currentOrders[.appleiap], order.productId == currentCacheOrder.productId, let price = Double(currentCacheOrder.amount) {
                // 补救1：如果没有applicationUserName的情况，而且是购买商品流程没有断的情况；
                order.currency = currentCacheOrder.currency
                order.price = price
                
                PayService.traceIAPPaymentStatus(step: 203, productId: nil, amount: nil, currency_now: nil, currency_global: nil, server_json: "没有applicationUserName")
            } else if allChannelList != nil, let (product, skProduct,_) = getIAPProductInfo(byProductId: order.productId ?? "") {
                // 补救2：为商品页面列表里的商品做的补救。currency 为nil，如果当前订单为空时，且channelList不为空的时候
                if let skProduct = skProduct {
                    order.currency = skProduct.priceLocale.currencyCode
                    order.price = skProduct.price.doubleValue
                   
                    PayService.traceIAPPaymentStatus(step: 203, productId: nil, amount: nil, currency_now: nil, currency_global: nil, server_json: "有skProduct")
                } else {
                    order.currency = product.currency
                    order.price = Double(product.amount) ?? 0
                    
                    PayService.traceIAPPaymentStatus(step: 203, productId: nil, amount: nil, currency_now: nil, currency_global: nil, server_json: "没有skProduct")
                }
            } else if let tid = transaction?.transactionIdentifier {
              
                // 先获取商品列表
                let losingOrder = LosingOrderInfo()
                losingOrder.item = order
                losingOrder.transaction = transaction
                losingOrder.completion = finish
                
                var keyId = tid
                if let originId = transaction?.original?.transactionIdentifier,originId.count > 0,originId != transaction?.transactionIdentifier {
                    keyId = originId
                }
                var items = losingOrders[keyId] ?? []
                items.append(losingOrder)
                losingOrders[keyId] = items
                
                loadLosingDelayDispatch?.cancel()
                loadLosingDelayDispatch = delay(0.1) { [weak self] in
                    if let productId = order.productId {
                        // 从苹果拉取商品信息；以丢失的订单id作为 requestKey
                        self?.payKit?.loadAppleIAPProducts([productId], requestKey: keyId)
                    }
                    
                    if self?.channelList == nil {
                        // 如果商品列表全部为空的话，需要去拉取商品列表
                        self?.loadChannelAndProductList()
                    }
                }
                
                if let originId = transaction?.original?.transactionIdentifier,originId.count > 0,originId != transaction?.transactionIdentifier {
                    PayService.traceIAPPaymentStatus(step: 501, productId: tid, amount: nil, currency_now: nil, currency_global: nil, server_json: "续费订单,originId=\(originId)")
                }else{
                    PayService.traceIAPPaymentStatus(step: 203, productId: tid, amount: nil, currency_now: nil, currency_global: nil, server_json: "构造losingOrder")
                }
                
                return;
            }
        }
        
        if order?.preorderId == nil {
            PayService.traceIAPPaymentStatus(step: 203, productId: "", amount: nil, currency_now: nil, currency_global: nil, server_json: "preorderId不存在")
            let passthroughStr:String = order?.extensionString == nil ? ((extParamater?["passthrough"] as? String) ?? "") : (order?.extensionString ?? "")
            // 如果preorderId 不存在，说明是处理一笔坏账订单,重新生成一个preorderId
            BankService.preOrder(detail: PayService.getLogJsonString(productId: order?.productId,passthrough:passthroughStr, isBadOrder: true)) { [weak self] result in
                switch result {
                case .success(let preorderId):
                    order?.preorderId = preorderId
                    self?.verifyReceipt(order: order, transaction: transaction, extParamater: extParamater, completion: { (success,isRepeat) in
                        finish?(success,isRepeat)
                    })
                case .failure(_):
                    self?.finishedPurchased(success: false,
                                            resultInfo: .none,
                                            channel: PayChannelKey.appleiap,
                                            productId: order?.productId,
                                            amount: order?.price,
                                            currency: order?.currency,
                                            preorderId: order?.preorderId,
                                            error:MemeCommonError.normal(code: PurchasedErrorCode.getPreorderIdFailed.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true))
                }
            }
        } else {
            verifyReceipt(order: order, transaction: transaction, extParamater: extParamater) { (success,isRepeat) in
                finish?(success,isRepeat)
            }
        }
    }
    
    public func purchased(with response: NEPayResponse?, channel: NEPayChannel, resultInfo: NEPurchaseResultInfo) {
        
        var success = false
        var error: MemeCommonError? = nil

        if let response = response {
            switch response.code {
            case .ResponseCode_Success, .ResponseCode_Repeat:
                success = true
            case .ResponseCode_RequestParamsError:
                success = false
                error = MemeCommonError.normal(code: PurchasedErrorCode.invalidParams.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true)
            case .ResponseCode_GetIAPProductFailed:
                error = MemeCommonError.normal(code: PurchasedErrorCode.getIAPProductFailed.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true)
            case .ResponseCode_IAPCantMakePurchase:
                error = MemeCommonError.normal(code: PurchasedErrorCode.IAPCantMakePurcahse.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true)
            case .ResponseCode_Canceled:
                error = MemeCommonError.normal(code: PurchasedErrorCode.canceled.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true)
            case .ResponseCode_VerifyFailedOther:
                error = MemeCommonError.normal(code: PurchasedErrorCode.IAPVerifyFailedOther.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true)
            case .ResponseCode_IAPPurchasedFail:
                error = MemeCommonError.normal(code: PurchasedErrorCode.IAPPurchaseFail.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true)
            default:
                error = MemeCommonError.normal(code: PurchasedErrorCode.faildUnknown.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true)
            }
        } else {
            error = MemeCommonError.normal(code: PurchasedErrorCode.faildUnknown.rawValue, msg: NELocalize.localizedString("Purchase Failed",comment: ""), isCustom: true)
        }

        var responseCode: Int? = nil
        if let code = response?.code.rawValue {
            responseCode = Int(code)
        }
        
        let channelKey = PayChannelKey(rawValue: NEPayChannelEnumToString(channel))
        finishedPurchased(success: success,
                          resultInfo: resultInfo,
                          channel: channelKey,
                          productId: response?.productId,
                          amount: response?.totalAmount,
                          currency: response?.currency,
                          preorderId: nil,
                          payKitResponseCode: responseCode,
                          error: error)
    }
    
    public func purchasedSuccess(_ toUserId: Int, productId: String, passthrough: String?, transactionId: String) {
        self.restoreObject.addSuccessTransaction(toUserId:toUserId, productId: productId, passthrough: passthrough, transactionId: transactionId)
    }
}

extension PayService {
    
    // MARK: private method
    
    fileprivate func checkDuplicatedTransaction(error: MemeCommonError) -> Bool {
        if let exDic = JsonUtil.jsonToDic(error.description),
            let funBankCode = exDic["code"] as? Int,
            funBankCode == FunBankDuplicatedCode {
            return true
        } else {
            return false
        }
    }
    
    public func purchasedItemsURL() -> URL {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
    
        let uid = MeMeKitConfig.userIdBlock()
        
        return URL(fileURLWithPath: documentsDirectory).appendingPathComponent("\(uid)_meme_purchased.plist")
    }
    
    fileprivate class func getLogJsonString(productId: String?,passthrough:String, isBadOrder: Bool) -> String {
//        "uid": LocalUserService.currentAccount?.id ?? 0
//        "country": LocalUserService.countryRegionCode,   // 当前用户的国家码
        let uid = MeMeKitConfig.userIdBlock()
        var dicts: [String: Any] = ["uid": uid,
                                    "product_id": productId ?? "",                    // 商品id
                                    "is_bad_order": isBadOrder,                        // 是否是处理的坏账订单
                                    "device": DeviceInfo.modelName,                  // 设备类型 如 iphone6，iphone6s，iphone7p等等
                                    "os": DeviceInfo.systemName,                     // 设备的系统 eg. iOS
                                    "os_version":DeviceInfo.systemVersion,           // 设备系统的版本 eg. 10, 11, 12
                                    "lang":DeviceInfo.appLanguage,                   // 设备当前语言
                                    "is_jailbroken_device": "0", // 是否是越狱设备
                                    "channel": "0",
                                    "country": "zh_CN",   // 当前用户的国家码
                                    "meme_build": "\(DeviceInfo.appBuild)",       // meme的build号
                                    "meme_version": "\(DeviceInfo.appShortVersion)",   // meme的大版本号
                                    "passthrough": "\(passthrough)",
                                    "push_token": PushService.pushToken ?? "unknown"] // push token
       
        dicts["device_id"] = DeviceInfo.deviceId
        
        let jsonObject = JSON(dicts)
        if let jsonString = jsonObject.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.prettyPrinted) {
            let tmpString = jsonString.replace("\n", withString: "")
            return tmpString
        }
        
        return ""
    }
}

extension PayService {
    
    // 传字符串
    public class func traceIAPPaymentStatus(step: Int?,
                                     productId: String?,
                                     amount: Double?,
                                     currency_now: String?,
                                     restoreFromFailedOrder: Bool? = nil,
                                     currency_global: String?,
                                     server_json: String?,
                                     depositUid: Int? = nil,
                                     receiptIsNil: Bool? = nil,
                                     transactionId: String? = nil,
                                     preorderId: String? = nil,
                                     ext: String? = nil,errorCode:Int = -1) {
     
        var detail: [String: Any] =
            ["productId": productId ?? "unknown",
             "amount": "\(amount ?? -1.0)",
             "currency_now": currency_now ?? "unknown",        /* 本次支付的。*/
             "isRestoreFromFailedOrder": restoreFromFailedOrder ?? "unknown",        /* 本次支付的。*/
             "currency_global": currency_global ?? "unknown",  /* 进入列表后，请求苹果成功的同时赋值的。*/
             "transactionId": transactionId ?? "unknown",      /* 苹果的订单Id*/
             "server_json": server_json ?? "unknown",          /* cms返回的大Json数据*/
             "extension": ext ?? "unknown",                    /* 额外属性字段*/
             "preorderId": preorderId ?? "unknown",            /* MeMe的订单号*/
             "errorCode": "\(errorCode)",
             "receiptIsNil": receiptIsNil == nil]           /* 收据是否为空*/
      
        if let depositUid = depositUid {
            detail["depositUid"] = depositUid
        }
        
        /* 列表页刷新 档
         step_1.进入到充值页面，获取充值列表成功。成功数据赋值 = server_json;   纯的服务端数据
         step_2.进入到充值页面，获取充值列表成功。成功数据赋值 = server_json;   经过客户端处理并重组之后的数据
         step_3.刷新苹果列表成功。
        
         // IAP充值 档
         step_20.点击充值按钮，走支付流程。
         step_21.进入充值流程，充值成功。
         step_22.苹果充值成功，但是找不到订单。也就是坏账。。
         step_23.苹果充值成功，但是附加信息都不存在的情况。有产生坏账的可能。
         step_24.苹果充值成功，有未完成订单返回。（包括 正常充值 + 之前充值成功重新启动程序返回的）
         step_25.苹果充值失败。
         step_26.苹果充值中。
         step_27.苹果重试充值
         
         step_28.有苹果未完成订单回来，此时未做任何逻辑判断，所有成功订单都有此打点，可以根据此点判断有没有无法走入验签逻辑的判断；
         
         // FPNN 档
         step_30.调用FPNN接口前。 这个信息和苹果充值成功的打点是一样的，所以就不打了。移步step_21
         step_31.调用FPNN接口成功后。成功数据赋值 = server_json
         step_32.调用FPNN接口失败后。失败数据赋值 = server_json
         step_33. deposit接口返回重复订单错误码
         
         step_100.errorString 最后统一错误回调，主要记录错误码
         
         // 初始化档位
         step_200.willFinishLaunchingWithOptions 启动初始化
         step_201.addTransactionObserver / removeTransactionObserver 添加observer
       

         */
        
        
        // 步骤可随意扩展，也可多埋点。
        let stepStatus = "step_" + "\(step ?? -1)"
        
        gLog("paystep:\(stepStatus)")
    }
    
    public class func traceObjcIAPPaymentStatus(step: Int,
                                               productId: String,
                                               server_json: String,
                                               transactionId: String,
                                               errorStr: String,
                                               errorCode:Int = -1) {
        traceIAPPaymentStatus(step: step, productId: productId, amount: nil, currency_now: nil, currency_global: nil, server_json: server_json, transactionId: transactionId, ext: errorStr,errorCode:errorCode)
    }
}

public class LosingOrderInfo {
    public var item: NEPayOrderItem?
    public var transaction: SKPaymentTransaction?
    public var completion: FinishPurchasesCompletionBlock?
}
