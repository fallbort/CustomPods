//
//  FbNettyAnswer.swift
//  aaaa
//
//  Created by fabo on 2020/5/28.
//  Copyright © 2020 meme. All rights reserved.
//

import Foundation
import MeMeKit
import ObjectMapper

open class FbNettyContentBody {
    public var type:FbNettyMsgType = .group
    public var _body:String?
    public var body:String {
        get {
            if let body = _body {
                return body
            }
            return ""
        }
    }
    
    fileprivate var _bodyObject:[String:Any]?
    
    func getRequestObject() -> [String:Any] {
        return [
                "type":type.rawValue,
                "body":body,
            ]
    }
    
    func makeBodyObject() {
        if let map:[String: Any] = body.convertToDictionary() {
            _bodyObject = map
            if (_bodyObject?.count == 0) {
                _bodyObject = nil
            }
        }else{
            _bodyObject = nil
        }
    }
    
    public func getBodyObject() -> [String:Any]? {
        return _bodyObject
    }
    
    public init() {
        
    }
}

public class FbNettyAnswer : FbNettyPackProtocol {
    public var header:FbNettyContentHeader?
    public var contentBody:FbNettyContentBody?
    
    public var cTime: TimeInterval
    public var seqNum: UInt32
    public var answerMap:[String: Any]?
    
    init(seqNum:UInt32) {
        self.seqNum = seqNum
        cTime = Date().timeIntervalSince1970
        
    }
    
    init?(data: Data) {
        do {
            seqNum = 0
            var subData = data.subdata(in: 0 ..< data.count)
            subData = Data.init(base64Encoded: subData) ?? subData
            let dataStr = String.init(data: subData, encoding: .utf8)

            guard let decodedString = dataStr, let map:[String: Any] = decodedString.convert() else {
                return nil
            }
            self.answerMap = map
            cTime = Date().timeIntervalSince1970
            
            var header = Mapper<FbNettyContentHeader>().map(JSONObject: map)
            header?.headerType = .response
            self.header = header
            
            let body = FbNettyContentBody()
            body._body = map["body"] as? String
            if let typeInt = map["type"] as? Int {
                body.type = FbNettyMsgType.init(rawValue: typeInt) ?? .unknown
            }else{
                body.type = .unknown
            }
            body.makeBodyObject()
            self.contentBody = body
            if body.type == .join || body.type == .exit {
                //log.verbose("netty response type=\(body.type.rawValue),mtype=\(header?._mType ?? 0),groupId=\(header?.groupId ?? 0),streamId=\(header?.streamId ?? 0)")
            }
            if body.type == .pong {
                //log.verbose("netty response pong")
            }
            gLog("nettyresponse nettymsg decodedString=\(decodedString)")
        } catch {
            return nil
        }
    }
}

class FbNettyJoinBody : FbNettyContentBody {
    var token:String = ""
    var isReconnect = false
    
    override var body:String {
        get {
            let data:[String : Any] = [
                "userToken":token,
                "isReconn":isReconnect,
                ]
            return JsonUtil.dicToJson(data) ?? ""
        }
    }
}

open class FbNettyCommonBody : FbNettyContentBody {
    public var params:[String:Any] = [:]
    
    
    
    public override var body:String {
        get {
            return JsonUtil.dicToJson(params) ?? "{}"
        }
    }
}
