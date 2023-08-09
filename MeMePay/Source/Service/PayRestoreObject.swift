//
//  PayRestoreObject.swift
//  MeMe
//
//  Created by fabo on 2021/5/26.
//  Copyright © 2021 sip. All rights reserved.
//

import Foundation
import ObjectMapper
import MeMeKit

//订阅档位已购买的关系数据
public class SubscribePayRestoreInfo: NSObject, Mappable {
    public var ownerId: Int = 0
    public var passthrough: String?
    public var productId: String = ""
    public var transactionId:String = ""
    public var fromServer:Bool = false
    public var isDealed = false
    
    override public init() {
        super.init()
    }
    required public init?(map: Map) {
    }
    
    public func mapping(map: Map) {
        ownerId <- map["uid"]
        passthrough <- map["passthrough"]
        productId <- map["productId"]
        transactionId <- map["transactionId"]
        fromServer <- map["fromServer"]
        isDealed <- map["isDealed"]
    }
    
    public override var description: String {
        return ""
    }
}

public class SubscribePayRestoreObject {
    //MARK:<>外部变量
    
    //MARK:<>外部block
    public var changedBlock:(()->())?
    
    //MARK:<>生命周期开始
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    public init() {
        restoreFromDisk(justNow: false)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func appDidEnterBackground() {
        self.storeToDisk()
    }
    
    @objc func willTerminate() {
        self.storeToDisk()
    }
    

    //MARK:<>功能性方法
    func setup() {
        
    }
    
    func dealedTransaction(transaction: SKPaymentTransaction?,isSuccess:Bool,isDuplicated:Bool) {
        restoreFromDisk()
        if isSuccess == true {
            let transactionId = transaction?.transactionIdentifier ?? ""
            let originId = transaction?.original?.transactionIdentifier ?? ""
            if let info = findUndealInfo(transactionId: transactionId) {
                let productId = info.productId
                let dealedKey = productId
                if let dealedInfo = restoreDealedInfos?[dealedKey] {
                    if dealedInfo.ownerId == info.ownerId {
                        if isDuplicated == true {
                            removeUndealInfo(transactionId: transactionId)
                        }else{
                            removeUndealInfo(transactionId: transactionId)
                        }
                    }else{
                        if isDuplicated == true {
                            removeUndealInfo(transactionId: transactionId)
                            changedBlock?()
                        }else{
                            removeUndealInfo(transactionId: transactionId)
                            refreshRelationShip(productId: productId, originId: originId,transactionId:transactionId)
                        }
                    }
                    
                }else{
                    if isDuplicated == true {
                        removeUndealInfo(transactionId: transactionId)
                        if info.passthrough != nil {
                            refreshRelationShip(productId: productId, originId: originId,transactionId:transactionId)
                        }
                    }else{
                        info.isDealed = true
                        if info.passthrough != nil {
                            restoreDealedInfos?[dealedKey] = info
                            infoChanged = true
                        }
                        removeUndealInfo(transactionId: transactionId)
                        changedBlock?()
                        refreshRelationShip(productId: productId, originId: originId,transactionId:transactionId)
                    }
                }
            }
        }else{
            changedBlock?()
        }
    }
    //ret为数据变化了
    func dealTransactionFromNet(infos:[SubscribePayRestoreInfo]) -> Bool {
        restoreFromDisk()
        var changed = false
        var needClear = false
        
        for oneInfo in infos {
            let dealedKey = oneInfo.productId
            if let oldInfo = restoreDealedInfos?[dealedKey] {
                if oldInfo.ownerId == oneInfo.ownerId {
                    //无操作
                }else{
                    if oldInfo.fromServer == false {
                        restoreDealedInfos?[dealedKey] = oneInfo
                        infoChanged = true
                        changed = true
                    }else{
                        needClear = true
                        break
                    }
                }
            }else{
                oneInfo.isDealed = true
                oneInfo.fromServer = true
                restoreDealedInfos?[dealedKey] = oneInfo
                infoChanged = true
                changed = true
            }
        }
        if needClear == true {
            restoreDealedInfos?.removeAll()
            infoChanged = true
            for oneInfo in infos {
                oneInfo.isDealed = true
                oneInfo.fromServer = true
                let dealedKey = oneInfo.productId
                restoreDealedInfos?[dealedKey] = oneInfo
                infoChanged = true
                changed = true
            }
        }
        
        return changed
    }
    
    func addSuccessTransaction(toUserId:Int,productId:String,passthrough:String?,transactionId:String) {
        restoreFromDisk()
        let undealedKey = "\(toUserId)::\(productId)"
        let value = restoreUnDealedInfos?[undealedKey]
        if value == nil,transactionId.count > 0 {
            let info = SubscribePayRestoreInfo()
            info.ownerId = toUserId
            info.passthrough = passthrough
            info.productId = productId
            info.transactionId = transactionId
            
            restoreUnDealedInfos?[undealedKey] = info
            infoChanged = true
        }
    }
    
    
    func getRestoreInfos() -> [SubscribePayRestoreInfo] {
        restoreFromDisk()
        var infos:[String:SubscribePayRestoreInfo] = restoreDealedInfos ?? [:]
        for (_,oneItem) in (restoreUnDealedInfos ?? [:]) {
            if infos[oneItem.productId] == nil {
                infos[oneItem.productId] = oneItem
            }
        }
        
        return Array(infos.values)
    }
    
    fileprivate func restoreFromDisk(justNow:Bool = true) {
        if restoreDealedInfos == nil {
            if justNow == true {
                readFromDisk()
            }else{
                DispatchQueue.global().async { [ weak self] in
                    self?.readFromDisk()
                }
            }
        }
    }
    
    fileprivate func readFromDisk() {
        var array:[SubscribePayRestoreInfo] = []
        
        do {
            let jsonArray = try String(contentsOfFile: Self.payStoreFile.path, encoding: String.Encoding.utf8)
            if let list = Mapper<SubscribePayRestoreInfo>().mapArray(JSONString: jsonArray) {
                array = list
            }
        } catch let error {
            gLog(error)
        }
        var dealed:[String:SubscribePayRestoreInfo] = [:]
        var undeal:[String:SubscribePayRestoreInfo] = [:]
        for oneItem in array {
            if oneItem.isDealed == true {
                dealed[oneItem.productId] = oneItem
            }else{
                let undealedKey = "\(oneItem.ownerId)::\(oneItem.productId)"
                undeal[undealedKey] = oneItem
            }
        }
        
        if Thread.current.isMainThread == true {
            self.restoreDealedInfos = dealed
            self.restoreUnDealedInfos = undeal
        }else{
            DispatchQueue.main.async { [weak self] in
                if self?.restoreDealedInfos == nil {
                    self?.restoreDealedInfos = dealed
                    self?.restoreUnDealedInfos = undeal
                }
            }
        }
        
    }
    
    fileprivate func setNeedStore() {
        storeDelayDispatch?.cancel()
        storeDelayDispatch = delay(3.0) {
            self.storeToDisk()
        }
    }
    
    fileprivate func storeToDisk() {
        if infoChanged == true {
            infoChanged = false
            var array:[SubscribePayRestoreInfo] = []
            if let restoreDealedInfos = restoreDealedInfos {
                array.append(contentsOf: Array(restoreDealedInfos.values))
            }
            if let restoreUnDealedInfos = restoreUnDealedInfos {
                array.append(contentsOf: Array(restoreUnDealedInfos.values))
            }
            let jsonStr = Mapper<SubscribePayRestoreInfo>().toJSONString(array)
            do {
                try jsonStr?.write(toFile: Self.payStoreFile.path, atomically: true,encoding: String.Encoding.utf8)
            } catch let error {
                infoChanged = true
                gLog(error)
            }
        }
    }
    
    fileprivate func findUndealInfo(transactionId:String) -> SubscribePayRestoreInfo? {
        var info:SubscribePayRestoreInfo?
        if transactionId.count > 0,let infos = restoreUnDealedInfos {
            for (_,oneInfo) in infos {
                if oneInfo.transactionId == transactionId {
                    info = oneInfo
                    break
                }
            }
        }
        return info
    }
    
    fileprivate func removeUndealInfo(transactionId:String) {
        var findKey:String?
        if transactionId.count > 0,let infos = restoreUnDealedInfos {
            for (key,oneInfo) in infos {
                if oneInfo.transactionId == transactionId {
                    findKey = key
                    break
                }
            }
            if let findKey = findKey {
                restoreUnDealedInfos?.removeValue(forKey: findKey)
                infoChanged = true
            }
        }
    }
    
    func refreshRelationShip(productId:String,originId:String,transactionId:String) {
        if requestingOrderIds.contains(originId) == false,needRequestOrderIds.contains(originId) == false {
            needRequestOrderIds.append(originId)
            _ = delay(1.0) { [weak self] in
                self?.startNextRequest()
            }
        }
    }
    
    func startNextRequest(endToRefresh:Bool = false) {
        guard isRequsting == false,needRequestOrderIds.count > 0 else {
            if endToRefresh == true {
                changedBlock?()
            }
            return
        }
        isRequsting = true
        let orderIds = needRequestOrderIds
        needRequestOrderIds.removeAll()
        requestingOrderIds = orderIds
        requestingOrderIds.removeAll()
        DispatchQueue.main.async { [weak self] in
            _ = delay(1.0) { [weak self] in
                self?.isRequsting = false
                self?.startNextRequest(endToRefresh: true)
            }
        }
    }
    
    //MARK:<>内部View
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    public var restoreDealedInfos:[String:SubscribePayRestoreInfo]?  //key为：productid
    public var restoreUnDealedInfos:[String:SubscribePayRestoreInfo]?  //key为："userid::productid"
    
    public var requestingOrderIds:[String] = []
    public var needRequestOrderIds:[String] = []
    public var isRequsting = false
    
    fileprivate var requestDelayDispatch: DispatchWorkItem?
    
    public var infoChanged = false {
        didSet {
            if infoChanged == true {
                setNeedStore()
            }
        }
    }
    
    fileprivate var storeDelayDispatch: DispatchWorkItem?
    
    
    fileprivate static var _payStoreFile: URL?
    fileprivate static var payStoreFile: URL {
        if let dir = _payStoreFile {
            return dir
        }else{
            let url = FileUtils.libraryDirectory.appendingPathComponent("subscribePay")
            if !FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    gLog(error)
                }
            }
            let newUrl = url.appendingPathComponent("restore.plist")
            _payStoreFile = newUrl
            return newUrl
        }
    }
    //MARK:<>内部block
}
