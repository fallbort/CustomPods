//
//  ZegoMessageManager.swift
//  MeMe
//
//  Created by fabo on 2022/3/21.
//  Copyright © 2022 sip. All rights reserved.
//

#if ZegoImported

import Foundation

import Foundation
import Cartography
import MeMeKit
import SwiftyJSON
import ZegoExpressEngine

enum ZegoMessageMode {
    case useSEI
    case useSequential
}

class ZegoMessageManager : NSObject {
    
    //MARK:<>外部变量
    var roomId:String?
    var streamId:String?
    var useMode:ZegoMessageMode = .useSEI //是否用SEI发送
    var isBroadcastor:Bool? {
        didSet {
            if let streamId = streamId {
                if isBroadcastor == true {
                    self.manager?.startBroadcasting(streamId)
                }else{
                    self.manager?.stopBroadcasting(streamId)
                }
            }
            
        }
    }
    
    //MARK:<>外部block
    var dataDidFetchedBlock:((_ type:SendDataType,_ streamId:String,_ data:[String:Any]?)->())?
    
    //MARK:<>生命周期开始
    override init() {
        
    }
    //MARK:<>功能性方法
    func start() {
        if let roomId = roomId {
            if useMode == .useSequential, self.manager == nil {
                self.manager = ZegoExpressEngine.shared().createRealTimeSequentialDataManager(roomId)
                self.manager?.setEventHandler(self)
                if let streamId = streamId {
                    if isBroadcastor == true {
                        self.manager?.startBroadcasting(streamId)
                    }
                }
                
            }
        }
        
    }
    
    func end() {
        if let manager = manager {
            if let streamId = streamId {
                self.manager?.stopSubscribing(streamId)
                self.manager?.stopBroadcasting(streamId)
            }
            ZegoExpressEngine.shared().destroy(manager)
            self.manager = nil
        }
    }
    
    func updateOtherUser(isAdd:Bool,streamId:String) {
        if isAdd {
            self.manager?.startSubscribing(streamId)
        }else{
            self.manager?.stopSubscribing(streamId)
        }
    }
    
    func sendData(data:Data,forceMode:ZegoMessageMode? = nil) {
        let curMode = forceMode ?? useMode
        if curMode == .useSEI {
            ZegoExpressEngine.shared().sendSEI(data)
        }else{
            if let streamId = streamId {
                self.manager?.sendRealTimeSequentialData(data, streamID: streamId, callback: { [weak self] ret in
                    
                })
            }
        }
    }
    
    //MARK:<>内部View
    
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    fileprivate var manager
    :ZegoRealTimeSequentialDataManager?
    
    //MARK:<>内部block
    
}

extension ZegoMessageManager : ZegoRealTimeSequentialDataEventHandler {
    func manager(_ manager: ZegoRealTimeSequentialDataManager, receiveRealTimeSequentialData data: Data, streamID: String) {
        if manager == self.manager {
            self.dealData(data: data, streamID: streamID)
        }
    }
    
    func dealData(data: Data, streamID: String) {
        let dict:[String:Any]?
        do {
            let json = try? JSON(data: data)
            dict = json?.dictionaryObject
        } catch {
           
        }
        if let typeStr = dict?["type"] as? String,let type = SendDataType.init(rawValue: typeStr) {
            dataDidFetchedBlock?(type,streamID,dict)
        }
    }
}


#endif
