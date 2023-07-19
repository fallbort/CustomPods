//
//  FbNettyManager.swift
//  aaaa
//
//  Created by fabo on 2020/5/28.
//  Copyright © 2020 meme. All rights reserved.
//

import Foundation
import MeMeKit

public protocol FbNettyDelegate {
    func nettyConnectRefreshed(_ isConnected:Bool)
    func nettyReceiveServerAnswerObject(_ answer:FbNettyAnswer)
    func nettyReceiveServerAnswerObjectInSubThread(_ answer:FbNettyAnswer)
}

public extension FbNettyDelegate {
    func nettyConnectRefreshed(_ isConnected:Bool) {
        
    }
    
    func nettyReceiveServerAnswerObject(_ answer:FbNettyAnswer) {
        
    }
    
    func nettyReceiveServerAnswerObjectInSubThread(_ answer:FbNettyAnswer) {
        
    }
}

public class FbNettyManager {
    public static let shared:FbNettyManager = FbNettyManager()
    //MARK:<>外部变量
    public var host:(host:String,port:UInt16)? {
        didSet {
            if let host = host,host.host == oldValue?.host && host.port == oldValue?.port {} else {
                let oldHeaders = client?.exitAll() ?? [:]
                client = nil
                if let host = host {
                    gLog("netty create,host=\(host.host),port=\(host.port)")
                    client = FbNettyClient.init(host: host.host, port: host.port, timeout: 30)
                    client?.refreshJoins(oldHeaders)
                    client?.end()
                    client?.getTokenByUserBlock = { [weak self] in
                        return self?.getTokenByUserBlock?()
                    }
                    client?.connectRefreshBlock = { [weak self] isConnected in
                        self?.delegates.excuteObject({ (object) in
                            object?.nettyConnectRefreshed(isConnected)
                        })
                    }
                    client?.receiveServerMsg = { [weak self] answer in
                        self?.delegates.excuteObject({ (object) in
                            object?.nettyReceiveServerAnswerObjectInSubThread(answer)
                        })
                        DispatchQueue.main.async {
                            self?.delegates.excuteObject({ (object) in
                                object?.nettyReceiveServerAnswerObject(answer)
                            })
                        }
                        
                    }
                    
                }
            }
        }
    }
    
    //MARK:<>外部block
    public var getTokenByUserBlock:(()->(userId:Int,token:String)?)?
    
    //MARK:<>生命周期开始
    fileprivate init() {
        
    }

    deinit {
        
    }
    
    //MARK:<>功能性方法
    public func active() {
        client?.active()
    }
    public func start(header:FbNettyContentHeader) -> String? {
        return client?.joinInRoom(header:header)
    }
    
    public func stop(uniqueId:String?) {
        guard let uniqueId = uniqueId else {return}
        client?.exitRoom(uniqueId:uniqueId)
    }
    
    public func stopAll() {
        client?.exitAll()
    }
    
    public func addDelegate(delegate: FbNettyDelegate) {
        delegates.addObject(delegate)
    }

    public func removeDelegate(delegate: FbNettyDelegate) {
        delegates.removeObject(delegate)
    }
    
    public func getHeader(uniqueId:String) -> FbNettyContentHeader? {
        return client?.getHeader(uniqueId: uniqueId)
    }
    
    //群消息toUid是0
    public func sendMsg(uniqueId:String?, contentBody:FbNettyCommonBody?, toUid:Int = 0 ,timeout:TimeInterval? = nil, callback: FbNettyCallback?) {
        if let client = client,let uniqueId = uniqueId,var header = self.getHeader(uniqueId: uniqueId) {
            header.rid = toUid
            var request = FbNettyRequest.init()
            request.header = header
            contentBody?.type = .send
            request.contentBody = contentBody
            request.timeout = timeout
            client.send(request, callback: callback)
        }else{
            callback?(.failure(.notInit))
        }
    }
    
    //MARK:<>内部View
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    var client:FbNettyClient?
    var delegates:WeakReferenceArray = WeakReferenceArray<FbNettyDelegate>()
    //MARK:<>内部block
}

