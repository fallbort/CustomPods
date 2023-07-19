//
//  FbNettyHeader.swift
//  aaaa
//
//  Created by fabo on 2020/5/28.
//  Copyright © 2020 meme. All rights reserved.
//

import Foundation
import ObjectMapper

public enum FbNettyHeaderType : Int {
    case request = 0
    case response
}

struct FbNettyConnectHeader {
    var totalLen:UInt32 = 0
    static func header(from data: Data) -> FbNettyConnectHeader? {

        var header = FbNettyConnectHeader()
        let usmp = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: MemoryLayout<Int8>.alignment)
        let destBuffer = UnsafeMutableRawBufferPointer.init(start: usmp, count: 4)
        let destBufferInt = destBuffer.bindMemory(to: UInt8.self)
        
        let bufferP = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: MemoryLayout<Int8>.alignment)
        _ = data.copyBytes(to: bufferP)
        
        defer {
            usmp.deallocate()
            bufferP.deallocate()
        }
        
        for i in 0..<4 {
            destBufferInt[i] = bufferP[4-1-i]
        }
        
        let usmpInt = usmp.bindMemory(to: UInt32.self, capacity: 1)
        header.totalLen = usmpInt.pointee

        return header
    }
    
    var bodySize: UInt {
        return UInt(totalLen)
    }
    
    static func data(from header:FbNettyConnectHeader) -> Data {
        let a = header.totalLen
        var dataP = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: MemoryLayout<Int8>.alignment)
        dataP.initializeMemory(as: Int8.self, repeating: 0, count: 4)
        var lenP = dataP.bindMemory(to: UInt32.self, capacity: 1)
        lenP.initialize(to: a)

        var dist = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: MemoryLayout<Int8>.alignment)
        dist.initializeMemory(as: Int8.self, repeating: 0, count: 4)
        
        defer {
            dataP.deallocate()
            dist.deallocate()
        }
        
        var aaa = dataP.bindMemory(to: UInt8.self, capacity: 4)
        var bbb = dist.bindMemory(to: UInt8.self, capacity: 4)
        for i in 0..<4 {
            let pointee = aaa.advanced(by: 4-1-i).pointee
            let data2 = bbb.advanced(by: i)
            data2.initialize(to: pointee)
        }
        
        let newData = Data.init(bytes: dist, count: 4)
        return newData
    }
}

public struct FbNettyContentHeader: Mappable, CustomStringConvertible {
    public var _mType:Int = -10  //是游戏还是什么东西
    public var streamId:Int = 0  //流id
    public var groupId:Int = 0
    public var sid:Int = 0    //发送者id
    public var rid:Int = 0   //接受人 （//系统消息非群消息有rid  群消息是0）
    public var sendTime:TimeInterval = 0  //毫秒
    public var version:String = ""
    public var platform:String = "ios"
    public var channel:Int = 0
    public var role: Int = 0
    
    public var headerType:FbNettyHeaderType = .request
    
    //response var
    public var mid:String = ""
    public var code:Int = 0
    public var body:String?
    
    public init() {
        sendTime = TimeInterval(Int(Date().timeIntervalSince1970*1000))
        if let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.version = buildString
        }
        if let channelStr = Bundle.main.infoDictionary?["MMChannelMode"] as? String, let channel = Int(channelStr)  {
            self.channel = channel
        }
    }
    
    public init?(map: Map) {
        sendTime = TimeInterval(Int(Date().timeIntervalSince1970*1000))
        if let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.version = buildString
        }
        if let channelStr = Bundle.main.infoDictionary?["MMChannelMode"] as? String, let channel = Int(channelStr)  {
            self.channel = channel
        }
    }
    
    mutating public func mapping(map: Map) {
        _mType <- map["mType"]
        streamId <- map["streamId"]
        groupId <- map["groupId"]
        sid <- map["sid"]
        rid <- map["rid"]
        sendTime <- map["sendTime"]
        
        mid <- map["mid"]
        code <- map["code"]
        body <- map["body"]
    }
    
    public var description: String {
        return ""
    }
    
    func getRequestObject() -> [String:Any] {
        return [
                "mType":_mType,
                "streamId":streamId,
                "groupId":groupId,
                "sid":sid,
                "rid":rid,
                "mid":mid,
                "channel":channel,
                "role":role,
                "sendTime":Int(sendTime),
                "version":version,
                "platform":platform,
            ]
    }
    
    mutating func refreshSendTime() {
        sendTime = TimeInterval(Int(Date().timeIntervalSince1970*1000))
    }
    
    mutating func refreshMid(seqNum:UInt32) {
        mid = "\(seqNum)_\(NSDate().timeIntervalSince1970*1000)_\(Int(arc4random() % UInt32(100000000)))"
    }
    
    public func isTheSameHeader(header:FbNettyContentHeader) -> Bool {
        if headerType != header.headerType {
            if header._mType == self._mType,header.groupId == self.groupId {
                return true
            }else{
                return false
            }
        }else{
            if headerType == .request {
                if header._mType == self._mType,header.groupId == self.groupId {
                    return true
                }else{
                    return false
                }
            }else{
                if header._mType == self._mType,header.groupId == self.groupId {
                    return true
                }else{
                    return false
                }
            }
        }
    }

}
