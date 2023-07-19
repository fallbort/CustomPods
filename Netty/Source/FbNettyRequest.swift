//
//  FbNettyRequest.swift
//  aaaa
//
//  Created by fabo on 2020/5/28.
//  Copyright © 2020 meme. All rights reserved.
//

import Foundation
import MeMeKit

public enum FbNettyMsgType : Int {
    case unknown = -10
    case join = 1
    case ack = 2
    case ping = 3
    case pong = 4
    case error = 5
    case exit = 6
    case group = 10
    case system = 11
    case send = 12
}

protocol FbNettyPackProtocol {
    var header:FbNettyContentHeader? {get}
    var contentBody:FbNettyContentBody? {get}
}

extension FbNettyPackProtocol {
    func packString() -> String? {
        let headerDict = header?.getRequestObject()
        let contentDict = contentBody?.getRequestObject()
        var lastDict:[String:Any] = [:]
        if let headerDict = headerDict {
            lastDict = lastDict.merged(with: headerDict)
        }
        if let contentDict = contentDict {
            lastDict = lastDict.merged(with: contentDict)
        }
        var jsonString: String?
        do {
            var jsonData = try JSONSerialization.data(withJSONObject: lastDict, options: [])
            jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
        } catch let error {

        }
        return jsonString
    }
    
    func pack() -> Data {
        let jsonString = packString()
        if let data = jsonString?.base64EncodeToData() {
            return self.makeCombineSendData(data)
        }
        
        return Data()
    }
    
    func makeCombineSendData(_ data:Data) -> Data {
        var dist = UnsafeMutableRawPointer.allocate(byteCount: 4+data.count, alignment: MemoryLayout<Int8>.alignment)
        dist.initializeMemory(as: Int8.self, repeating: 0, count: 4+data.count)
        
        defer {
            dist.deallocate()
        }
        
        let headerData = FbNettyConnectHeader.data(from: FbNettyConnectHeader.init(totalLen: UInt32(data.count)))
        var aaa = dist.assumingMemoryBound(to: UInt8.self)
        
        headerData.copyBytes(to: aaa, count: headerData.count)
        
        var dist2 = dist.advanced(by: headerData.count)
        var ccc = dist2.assumingMemoryBound(to: UInt8.self)
        
        data.copyBytes(to: ccc, count: data.count)
        
        let newData = Data.init(bytes: dist, count: headerData.count+data.count)
        return newData
    }
}
//不用用class,线程不安全
struct FbNettyRequest : FbNettyPackProtocol {
    var header:FbNettyContentHeader?
    var contentBody:FbNettyContentBody?
    
    
    
    var cTime: TimeInterval = 0
    var timeout: TimeInterval?
    var retry = 0
    var uniqueKey:String
    
    init() {
        cTime = Date().timeIntervalSince1970
        
        uniqueKey = "\(NSDate().timeIntervalSince1970*1000)_\(Int(arc4random() % UInt32(100000000)))"
    }
    
}

