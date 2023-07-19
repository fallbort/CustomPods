//
//  FbNettyClient.swift
//  aaaa
//
//  Created by fabo on 2020/5/28.
//  Copyright © 2020 meme. All rights reserved.
//

import CocoaAsyncSocket
import Foundation
import Alamofire
import MeMeKit

private enum NettyTag: Int {
    case header = 1
    case body
}

private enum NettyJoinStatus : Int {
    case beforeJoin = 1
    case joining
    case normal
    case beforeExit
    case exiting
}

private class AnswerTask {
    var quest: FbNettyRequest
    var callback: FbNettyCallback
    var cancelTask: CancelableTimeoutBlock

    init(quest: FbNettyRequest, callback: @escaping FbNettyCallback, cancelTask: CancelableTimeoutBlock) {
        self.quest = quest
        self.callback = callback
        self.cancelTask = cancelTask
    }
}

let NettyHeaderLength: UInt = 4

class FbNettyClient : NSObject {
    //MARK:<>外部变量
    var isStarted:Bool = false
    
    //MARK:<>外部block
    var receiveServerMsg:((_ answer:FbNettyAnswer)->())?
    var connectRefreshBlock:((_ isConnected:Bool)->())?
    var getTokenByUserBlock:(()->(userId:Int,token:String)?)?
    
    //MARK:<>生命周期开始
    deinit {
        //log.verbose("nettycreate deinit")
        stop()
    }
    init(host: String, port: UInt16, timeout: TimeInterval) {
        //log.verbose("nettycreate init")
        self.host = (host,port)
        readTimeout = timeout

        queue = DispatchQueue(label: "fb.nettyclient.queue")
        socket = GCDAsyncSocket()
        super.init()
        
        startNetworkWatcher()
    }
    
    func startNetworkWatcher() {
        reachablityManager?.startListening(onUpdatePerforming: { [weak self] (status) in
            if status != .notReachable {
                if self?.isStarted == true {
                    self?.start()
                }
            }else{
                if self?.isStarted == true {
                    self?.disconnect()
                }
            }
        })
    }
    
    @objc func timerHeartAction() {
        //log.verbose("FbNettyClient timerHeartAction")
        timeCount = timeCount > 1000000 ? 0 : timeCount
        timeCount = timeCount + 1
        let canHeart = timeCount % 2 == 1 ? false : true
        joinsLock.lock()
        let request = joinRequests.first?.value
        joinsLock.unlock()
        if var request = request {
            if socket.isConnected == true {
                if canHeart {
                    var body = FbNettyContentBody()
                    body.type = .ping
                    request.contentBody = body
                    //log.verbose("netty heart ,mtype=\(request.header?._mType ?? 0),groupId=\(request.header?.groupId ?? 0),streamId=\(request.header?.streamId ?? 0)")
                    self.send(request, callback: nil)
                }
                reCheckJoin()
                
            }else{
                if reachablityManager == nil || reachablityManager?.isReachable == true {
                    if isStarted == true {
                        strconnect()
                    }
                }
            }
        }
        if socket.isConnected == true {
            reCheckExit()
        }
    }
    
    func active() {
        if isStarted == true,socket.isConnected == false {
            start()
        }
    }
    
    fileprivate func start() {
        isStarted = true
        if reachablityManager == nil || reachablityManager?.isReachable == true {
            //log.verbose("FbNettyClient start to connect")
            strconnect()
        }
        if self.heartTimer == nil {
            self.heartTimer = Timer.scheduledTimer(timeInterval: 4.5, target: self, selector:  #selector(timerHeartAction), userInfo: nil, repeats: true)
            RunLoop.main.add(heartTimer!, forMode: .common)
        }
    }
    
    fileprivate func stop() {
        isStarted = false
        disconnect()
        joinsLock.lock()
        joinOutUniqueIds.removeAll()
        joinRequests.removeAll()
        joinStatus.removeAll()
        joinsLock.unlock()
        self.heartTimer?.invalidate()
        self.heartTimer = nil
        self.checkDelayDispatch?.cancel()
    }
    
    func end() {
        stop()
        reachablityManager?.stopListening()
    }
    
    @discardableResult
    func exitRoom(uniqueId outUniqueId:String) -> Bool {
        var needExit = false
        var status:NettyJoinStatus?
        joinsLock.lock()
        let uniqueId = joinOutUniqueIds[outUniqueId]
        if let uniqueId = uniqueId {
            if joinOutUniqueIds.allValuesDict(value: uniqueId).count > 1 {
                joinOutUniqueIds.removeValue(forKey: outUniqueId)
            }else{
                status = joinStatus[uniqueId]
                if status == .beforeJoin {
                    needExit = true
                    joinStatus.removeValue(forKey: uniqueId)
                    joinRequests.removeValue(forKey: uniqueId)
                    joinOutUniqueIds.removeAllValues(value: uniqueId)
                }else if status == .joining || status == .normal  {
                    needExit = true
                    joinStatus[uniqueId] = .beforeExit
                    joinOutUniqueIds.removeAllValues(value: uniqueId)
                }
            }
        }
        joinsLock.unlock()
        if needExit == true {
            reCheckExit()
        }
        return status != nil
    }
    
    //返回值为[outUniqueKey:request]
    @discardableResult
    func exitAll() -> [String:FbNettyContentHeader] {
        joinsLock.lock()
        var exitDict:[String:FbNettyContentHeader] = [:]
        var headers:[FbNettyContentHeader] = []
        for (key,uniqueKey) in self.joinOutUniqueIds {
            if let header = self.joinRequests[uniqueKey]?.header {
                exitDict[key] = header
            }
        }
        var needExit = false
        var newRequests:[String:FbNettyRequest] = [:]
        var newStatus:[String:NettyJoinStatus] = [:]
        for (key,status) in self.joinStatus {
            if status == .beforeJoin {
                
            }else if status == .joining || status == .normal  {
                needExit = true
                newRequests[key] = self.joinRequests[key]
                newStatus[key] = .beforeExit
            }else if status == .beforeExit || status == .exiting {
                newRequests[key] = self.joinRequests[key]
                newStatus[key] = status
            }
        }
        self.joinRequests = newRequests
        self.joinStatus = newStatus
        self.joinOutUniqueIds = [:]
        joinsLock.unlock()
        if needExit == true {
            reCheckExit(flush:true)
        }
        return exitDict
    }
    
    fileprivate func reCheckExit(flush:Bool = false) {
        queue.async {
            if self.socket.isConnected == true,self.connectInited.get() == true {
                var requests:[FbNettyRequest] = []
                var keys:[String] = []
                self.joinsLock.lock()
                for (key,status) in self.joinStatus {
                    if let request = self.joinRequests[key] {
                        if status == .beforeExit {
                            requests.append(request)
                            keys.append(key)
                        }
                    }else{
                        //log.verbose("netty FbNettyClient self.joinRequests not has Key")
                    }
                }
                for key in keys {
                    self.joinStatus[key] = .exiting
                }
                self.joinsLock.unlock()
                for request in requests {
                    var exitReq = self.getExitFromJoinRequest(request: request)
                    //log.verbose("netty exit,groupId=\(exitReq.header?.groupId ?? 0),streamId=\(exitReq.header?.streamId ?? 0),mtype=\(exitReq.header?._mType ?? 0)")
                    exitReq.header?.refreshMid(seqNum: self.nextSequenceNumber())
                    self.doSend(exitReq) { [weak self] result in
                        guard let strongSelf = self else { return}
                        var responeAnswer:FbNettyAnswer? = nil
                        if case .success(let answer) = result {
                            //log.verbose("netty exit,completeBlock,groupId=\(exitReq.header?.groupId ?? 0),streamId=\(exitReq.header?.streamId ?? 0),mtype=\(exitReq.header?._mType ?? 0)")
                            responeAnswer = answer
                            
                        }else if case .failure(.responeError(let error)) = result {
                            //退出房间暂时不重试
                            //log.verbose("netty exit,failed,groupId=\(exitReq.header?.groupId ?? 0),streamId=\(exitReq.header?.streamId ?? 0),mtype=\(exitReq.header?._mType ?? 0)")
                            let answer = error.userInfo["answer"] as? FbNettyAnswer
                            responeAnswer = answer
//                            if let header = answer?.header {
//                                strongSelf.joinsLock.lock()
//                                var foundKey:String? = nil
//                                for (key,status) in strongSelf.joinStatus {
//                                    if status == .exiting {
//                                        let request = strongSelf.joinRequests[key]
//                                        if request?.header?.isTheSameHeader(header: header) == true {
//                                            foundKey = key
//                                            break
//                                        }
//                                    }
//                                }
//                                if let foundKey = foundKey {
//                                    strongSelf.joinStatus[foundKey] = .beforeExit
//                                }
//                                strongSelf.joinsLock.unlock()
//                            }
                        }
                        if let header = responeAnswer?.header {
                            strongSelf.joinsLock.lock()
                            var foundKey:String? = nil
                            for (key,status) in strongSelf.joinStatus {
                                if status == .exiting {
                                    let request = strongSelf.joinRequests[key]
                                    if request?.header?.isTheSameHeader(header: header) == true {
                                        foundKey = key
                                        break
                                    }
                                }
                            }
                            if let foundKey = foundKey {
                                strongSelf.joinStatus.removeValue(forKey: foundKey)
                                strongSelf.joinRequests.removeValue(forKey: foundKey)
                            }
                            strongSelf.joinsLock.unlock()
                            if let foundKey = foundKey {
                                strongSelf.checkStopAsync(flush: true)
                            }
                        }
                    }
                }
                self.joinsLock.lock()
                let statusCount = self.joinStatus.count
                self.joinsLock.unlock()
                if requests.count > 0 || statusCount == 0 {
                    if statusCount == 0 {
                        self.checkStopAsync(flush: true, force: true)
                    }else if flush == true {
                        self.checkStopAsync(flush: true, force: true)
                    }else{
                        self.checkStopAsync()
                    }
                    
                }
            }else{
                self.joinsLock.lock()
                let statusCount = self.joinStatus.count
                self.joinsLock.unlock()
                if statusCount == 0 {
                    self.checkStopAsync(flush: true, force: true)
                }
            }
        }
    }
    //force,强制停止
    fileprivate func checkStopAsync(flush:Bool = false,force:Bool = false) {
        DispatchQueue.main.async {
            if flush == false {
                self.checkDelayDispatch?.cancel()
                self.checkDelayDispatch = delay(1.5) { [weak self] in
                    self?.realCheckStop(force:force)
                }
            }else{
                self.realCheckStop(force:force)
            }
        }
    }
    
    fileprivate func realCheckStop(force:Bool) {
        self.joinsLock.lock()
        var newRequests:[String:FbNettyRequest] = [:]
        var newStatus:[String:NettyJoinStatus] = [:]
        for (key,status) in self.joinStatus {
            if status == .beforeJoin || status == .joining || status == .normal || (status == .beforeExit && force == false) {
                newRequests[key] = joinRequests[key]
                newStatus[key] = status
            }
        }
        self.joinStatus = newStatus
        self.joinRequests = newRequests
        //不应该会影响到joinOutUniqueIds变量
        let count = newStatus.count
        self.joinsLock.unlock()
        if count == 0,isStarted == true {
            stop()
        }
    }
    
    fileprivate func reCheckJoin() {
        var keys:[String] = []
        self.joinsLock.lock()
        for (key,status) in joinStatus {
            if status == .joining {
                keys.append(key)
            }
        }
        for key in keys {
            joinStatus[key] = .beforeJoin
        }
        self.joinsLock.unlock()
        if keys.count > 0 {
            //log.verbose("netty reCheckJoin doJoin")
            doJoin()
        }
    }
    
    func refreshJoins(_ otherHeaders:[String:FbNettyContentHeader]) {
        var needJoin:Bool = false
        joinsLock.lock()
        for (key,newHeader) in otherHeaders {
            var saveRequest = FbNettyRequest()
            saveRequest.header = newHeader
            var hasOld = false
            var removeOldKey:String? = nil
            var outUniqueKey = key
            var uniqueKey = saveRequest.uniqueKey
            for (key,oneJoin) in self.joinRequests {
                if oneJoin.header?.isTheSameHeader(header: newHeader) == true {
                    let status = self.joinStatus[key]
                    if status == .beforeExit || status == .exiting {
                        removeOldKey = key
                    }else{
                        uniqueKey = key
                        hasOld = true
                    }
                    break
                }
            }
            if let key = removeOldKey {
                self.joinRequests.removeValue(forKey: key)
                self.joinStatus.removeValue(forKey: key)
            }
            if hasOld == false {
                self.joinRequests[uniqueKey] = saveRequest
                self.joinStatus[uniqueKey] = .beforeJoin
                self.joinOutUniqueIds[outUniqueKey] = uniqueKey
                needJoin = true
            }else{
                self.joinOutUniqueIds[outUniqueKey] = uniqueKey
            }
        }
        joinsLock.unlock()
        
        if socket.isConnected == false {
            start()
        }else{
            if isStarted == false {
                start()
            }
            if needJoin == true {
                doJoin()
            }
        }
        
    }
    
    func joinInRoom(header:FbNettyContentHeader) -> String {
        var saveRequest = FbNettyRequest()
        saveRequest.header = header
        
        var hasOld = false
        var removeOldKey:String? = nil
        var outUniqueKey = self.makeOutUniqueKey()
        var uniqueKey = saveRequest.uniqueKey
        joinsLock.lock()
        for (key,oneJoin) in self.joinRequests {
            if oneJoin.header?.isTheSameHeader(header: header) == true {
                let status = self.joinStatus[key]
                if status == .beforeExit || status == .exiting {
                    removeOldKey = key
                }else{
                    uniqueKey = key
                    hasOld = true
                }
                break
            }
        }
        if let key = removeOldKey {
            self.joinRequests.removeValue(forKey: key)
            self.joinStatus.removeValue(forKey: key)
        }
        if hasOld == false {
            self.joinRequests[uniqueKey] = saveRequest
            self.joinStatus[uniqueKey] = .beforeJoin
            self.joinOutUniqueIds[outUniqueKey] = uniqueKey
        }else{
            self.joinOutUniqueIds[outUniqueKey] = uniqueKey
        }
        joinsLock.unlock()
        
        if socket.isConnected == false {
            start()
        }else{
            if isStarted == false {
                start()
            }
            if hasOld == false {
                doJoin()
            }
        }
        return outUniqueKey
    }
    
    fileprivate func doJoin() {
        var user:(userId:Int,token:String)? = nil
        if Thread.current.isMainThread == true {
            user = self.getTokenByUserBlock?()
        }else{
            DispatchQueue.main.sync {
                user = self.getTokenByUserBlock?()
            }
        }
        queue.async { [weak self] in
            if self?.socket.isConnected == true,self?.connectInited.get() == true {
                guard let strongSelf = self else { return}
                if let user = user {
                    var requests:[FbNettyRequest] = []
                    var keys:[String] = []
                    strongSelf.joinsLock.lock()
                    for (key,status) in strongSelf.joinStatus {
                        if let request = strongSelf.joinRequests[key] {
                            if status == .beforeJoin {
                                requests.append(request)
                                keys.append(key)
                            }
                        }else{
                            //log.verbose("netty FbNettyClient self.joinRequests not has Key")
                        }
                    }
                    for key in keys {
                        strongSelf.joinStatus[key] = .joining
                    }
                    strongSelf.joinsLock.unlock()
                    for request in requests {
                        strongSelf.realDoJoin(request, userId: user.userId, token: user.token)
                    }
                }
            }
        }
    }
    
    //MARK:<>功能性方法
    fileprivate func strconnect(useQueue:Bool = true) -> Bool {
        objc_sync_enter(self)
        let isConnecting = connecting.get()
        var isNewConnect = false
        if isConnecting == false && socket.isConnected == false && connectInited.get() == false {
            connecting.set(true)
            connectedSeqNumber.getAndSet(nextConnectNumber())
            isNewConnect = true
        }
        objc_sync_exit(self)
        
        guard isNewConnect == true else {
            return true
        }

        
        var ret = false
        if useQueue {
            self.queue.async { [weak self] in
                guard let `self` = self else {return}
                do {
                    self.startConnectTime = Date().timeIntervalSince1970
                    self.socket.delegate = self
                    self.socket.delegateQueue = self.queue
                    //log.verbose("netty socket.connect")
                    try self.socket.connect(toHost: self.host.host, onPort: self.host.port, withTimeout: self.readTimeout)
                }catch{
                    //log.verbose("netty socket.connect failed")
                }
            }
            if ret == true {
                return true
            }else {
                return false
            }
        }else{
            do {
                self.startConnectTime = Date().timeIntervalSince1970
                self.socket.delegate = self
                self.socket.delegateQueue = self.queue
                //log.verbose("netty socket.connect")
                try self.socket.connect(toHost: self.host.host, onPort: self.host.port, withTimeout: self.readTimeout)
                ret = true
            }catch{
                //log.verbose("netty socket.connect failed")
                ret = false
            }
            if ret == true {
                return true
            }else {
                disconnect()
                return false
            }
        }
    }

    fileprivate func disconnect() {
        //log.verbose("netty user call disconnect")
        socket.delegateQueue = nil
        socket.delegate = nil
        let oldSocket = socket
        queue.async {
            oldSocket.disconnect()
        }
        connectInited.set(false)
        connecting.set(false)
        clearAllSendTask()
    }

    func send(_ quest: FbNettyRequest, callback: FbNettyCallback?) {
        //log.verbose("FbNettyClient send req")
        let connected = strconnect()
        if (connected && connectInited.get()) || (connected && quest.contentBody?.type == .exit) {
            queue.async {
                var newQuest = quest
                newQuest.header?.refreshMid(seqNum: self.nextSequenceNumber())
                self.doSend(newQuest, callback: callback)
            }
        } else {
            if socket.isConnected == true {
                callback?(.failure(.notInit))
            }else{
                callback?(.failure(.network))
            }
        }
    }

    fileprivate func recievedAnswer(_ sourceAnswer: FbNettyAnswer) {
        let answer = recievedAnswerWithDealedAck(sourceAnswer)
        if let answer = answer,let header = answer.header {
            answerLock.lock()
            let task = answerTaskCache.removeValue(forKey: header.mid)
            answerLock.unlock()
            if answer.contentBody?.type != .ack,let answerStore = task {
                answerStore.cancelTask.cancel()
                if header.code == 0 {
                    answerStore.callback(.success(answer))
                }else if answer.contentBody?.type == .join,header.code == 100001 {
                    answerStore.callback(.success(answer))
                }else{
                    let error = NSError.init(domain: "", code: header.code, userInfo: ["answer":answer])
                    answerStore.callback(.failure(.responeError(error)))
                }
                
            } else {
                if let answer = recievedNoRepeatAnswerWithAnswer(answer) {
                    self.receiveServerMsg?(answer)
                }
            }
        }
    }
    
    fileprivate func recievedAnswerWithDealedAck(_ answer: FbNettyAnswer) -> FbNettyAnswer? {
        if var header = answer.header,let content = answer.contentBody,let myId = getSendUid(groupId:header.groupId,type:content.type) {
            if content.type != .ack,content.type != .ping,content.type != .pong {
                let sid = header.sid
                header.sid = myId
                header.rid = sid
                var body = FbNettyContentBody()
                body.type = .ack
                var ackRequest = FbNettyRequest()
                ackRequest.header = header
                ackRequest.contentBody = body
                //不能有callback,因为服务器不会发ack的callback
                self.doSend(ackRequest,callback:nil)
            }
            return answer
        }
        
        return nil
    }
    
    fileprivate func recievedNoRepeatAnswerWithAnswer(_ answer: FbNettyAnswer) -> FbNettyAnswer? {
        if var header = answer.header,let content = answer.contentBody {
            if header.mid.count > 0 {
                if answerMidSet.contains(header.mid) == false {
                    answerMidSet.append(header.mid)
                    if answerMidSet.count > 500 {
                        answerMidSet.removeFirst()
                    }
                    return answer
                }else{
                    //log.verbose("FbNettyClient nettymsg header.mid[\(header.mid)] answer repeat")
                }
            }else{
                gLog("netty answer mid is empty!")
            }
            
        }
        
        return nil
    }

    fileprivate func doSend(_ quest: FbNettyRequest, callback: FbNettyCallback?) {
        var newReq = quest
        newReq.header?.refreshSendTime()
        if let header = newReq.header {
            if let callback = callback {
                
                let rtimeout = quest.timeout ?? readTimeout * 2
                let task = timeout(rtimeout, queue: queue) { [weak self] in
                    guard let wself = self else {
                        return
                    }
                    self?.answerLock.lock()
                    let answerStore = wself.answerTaskCache.removeValue(forKey: header.mid)
                    self?.answerLock.unlock()
                    if let answerStore = answerStore {
                        //log.verbose("FbNettyClient header.mid[\(header.mid)] request timeout")
                        answerStore.callback(.failure(.network))
                        self?.disconnect()
                    }
                }
                answerLock.lock()
                let answerTask = answerTaskCache.removeValue(forKey: header.mid)
                answerTaskCache[header.mid] = AnswerTask(quest: quest, callback: callback, cancelTask: task)
                answerLock.unlock()
                if let answerTask = answerTask {
                    answerTask.cancelTask.cancel()
                    //answerTask.callback(.failure(.cancel))   //因为这个任务会重启，所以不需要调用cancel
                }
            }
            //log.verbose("FbNettyClient nettymsg doSend req,pack=\(newReq.packString())")
            queue.async { [weak self] in
                guard let `self` = self else {return}
                self.socket.write(newReq.pack() as Data, withTimeout: newReq.timeout ?? -1, tag: 0)
            }
            
        }else {
            let error = NSError.init(domain: "send no header", code: 1, userInfo: nil)
            callback?(.failure(.other(error)))
        }
        
    }
    
    func clearAllSendTask() {
        answerLock.lock()
        let newCache = answerTaskCache
        answerTaskCache.removeAll()
        answerLock.unlock()
        for (key,answerStore) in newCache {
            answerStore.cancelTask.cancel()
            let userInfo = [NSLocalizedFailureReasonErrorKey: "FbNettyClient connection is breakon!"]
            let error = NSError(domain: "FbNettyClient connect breakon", code: 103, userInfo: userInfo)
            answerStore.callback(.failure(.system(error)))
        }
    }
    
    fileprivate func realDoJoin(_ item:FbNettyRequest,userId:Int,token:String) {
        //log.verbose("netty realDoJoin,groupId=\(item.header?.groupId ?? 0),streamId=\(item.header?.streamId ?? 0),mtype=\(item.header?._mType ?? 0)")
        gLog("netty realDoJoin,groupId=\(item.header?.groupId ?? 0),streamId=\(item.header?.streamId ?? 0),mtype=\(item.header?._mType ?? 0)")
        var request = item
        let body = FbNettyJoinBody()
        body.type = FbNettyMsgType.join
        if request.header?.sid == userId {
            body.token = token;
            request.contentBody = body
            request.header?.refreshMid(seqNum: nextSequenceNumber())
            self.doSend(request) { [weak self] result in
                guard let strongSelf = self else { return}
                switch result {
                case let .success(answer):
                    //log.verbose("netty realDoJoin,completeBlock,groupId=\(item.header?.groupId ?? 0),streamId=\(item.header?.streamId ?? 0),mtype=\(item.header?._mType ?? 0)")
                    if let header = answer.header {
                        strongSelf.joinsLock.lock()
                        var foundKey:String? = nil
                        for (key,status) in strongSelf.joinStatus {
                            if status == .joining {
                                let request = strongSelf.joinRequests[key]
                                if request?.header?.isTheSameHeader(header: header) == true {
                                    foundKey = key
                                    break
                                }
                            }
                        }
                        if let foundKey = foundKey {
                            strongSelf.joinStatus[foundKey] = .normal
                        }
                        strongSelf.joinsLock.unlock()
                    }
                case let .failure(error):
                    gLog("netty realDoJoin failed,groupId=\(item.header?.groupId ?? 0),streamId=\(item.header?.streamId ?? 0),mtype=\(item.header?._mType ?? 0),error=\(error)")
                }
            }
        }
    }
    
    fileprivate func getExitFromJoinRequest(request req:FbNettyRequest) -> FbNettyRequest {
        let header = req.header
        var request = FbNettyRequest()
        request.header = header
        var body = FbNettyContentBody()
        body.type = .exit
        request.contentBody = body
        return request
    }
    
    fileprivate func makeOutUniqueKey() -> String {
        return "\(NSDate().timeIntervalSince1970*1000)__\(Int(arc4random() % UInt32(100000000)))"
    }
    
    public func getHeader(uniqueId outUniqueId:String) -> FbNettyContentHeader? {
        joinsLock.lock()
        var header:FbNettyContentHeader?
        if let uniqueId = joinOutUniqueIds[outUniqueId] {
            header = joinRequests[uniqueId]?.header
        }
        joinsLock.unlock()
        return header
    }
    
    fileprivate func nextSequenceNumber() -> UInt32 {
        sendLock.lock()
        self.sequenceNumber += 1
        if self.sequenceNumber >= UInt32.max {
            self.sequenceNumber = 0
        }
        let num = sequenceNumber
        sendLock.unlock()

        return num
    }
    
    fileprivate func nextConnectNumber() -> UInt32 {
        sendLock.lock()
        self.connectNumber += 1
        if self.connectNumber >= UInt32.max {
            self.connectNumber = 0
        }
        let num = connectNumber
        sendLock.unlock()

        return num
    }
    
    fileprivate func getSendUid(groupId:Int,type:FbNettyMsgType) -> Int? {
        joinsLock.lock()
        var uid:Int?
        for (key,oneJoin) in self.joinRequests {
            if oneJoin.header?.groupId == groupId || (groupId == 0 && type == .system) {
                uid = oneJoin.header?.sid
                break
            }
        }
        joinsLock.unlock()
        return uid
    }
    
    //MARK:<>内部View
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    fileprivate let socket: GCDAsyncSocket
    fileprivate var host:(host:String,port:UInt16)
    fileprivate let readTimeout: TimeInterval
    fileprivate let queue: DispatchQueue
    fileprivate var connecting = AtomValue(false)
    fileprivate var connectedSeqNumber = AtomValue(UInt32(0))
    fileprivate var connectInited = AtomValue(false)
    fileprivate var startConnectTime:TimeInterval = 0
    fileprivate var joinOutUniqueIds:[String:String] = [:]  //key:对外的uniqueId,value:内部的uniqueId
    fileprivate var joinRequests:[String:FbNettyRequest] = [:]  //key:内部的uniqueId,value:request
    fileprivate var joinStatus:[String:NettyJoinStatus] = [:]  //key:内部的uniqueId,value:status
    fileprivate var joinsLock:NSLock = NSLock()
    fileprivate var answerTaskCache = [String: AnswerTask]()
    fileprivate var answerMidSet:Array<String> = [] //收到的消息的mid的缓存,排重
    fileprivate var answerLock:NSLock = NSLock()
    fileprivate var sequenceNumber: UInt32 = 0   //发送的mid增加计数
    fileprivate var connectNumber: UInt32 = 0   //connecting增加计数
    fileprivate var sendLock:NSLock = NSLock()
    fileprivate var heartTimer:Timer?
    fileprivate var timeCount:Int = 0
    fileprivate var checkDelayDispatch: DispatchWorkItem?
    
    private let reachablityManager:NetworkReachabilityManager? = NetworkReachabilityManager()
    
    //MARK:<>内部block
}

extension FbNettyClient: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        connecting.set(false)
        //log.verbose("netty connected")
        gLog("netty didConnectToHost")
        var user:(userId:Int,token:String)? = nil
        DispatchQueue.main.sync {
            user = self.getTokenByUserBlock?()
        }

        if let user = user {
            var requests:[FbNettyRequest] = []
            var keys:[String] = []
            self.joinsLock.lock()
            for (key,status) in self.joinStatus {
                if let request = self.joinRequests[key] {
                    if status == .beforeJoin || status == .joining || status == .normal {
                        requests.append(request)
                        keys.append(key)
                    }
                }else{
                    //log.verbose("netty FbNettyClient self.joinRequests not has Key")
                }
            }
            for key in keys {
                self.joinStatus[key] = .joining
            }
            self.joinsLock.unlock()
            for request in requests {
                self.realDoJoin(request, userId: user.userId, token: user.token)
            }
        }

        sock.readData(toLength: NettyHeaderLength, withTimeout: readTimeout * 2, tag: NettyTag.header.rawValue)
        
        connectInited.compareAndSet(false, update: true)
        
        
        DispatchQueue.main.async { [weak self] in
            if self?.socket.isConnected == true {
                self?.connectRefreshBlock?(true)
            }
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        guard let tag = NettyTag(rawValue: tag) else {
            return
        }

        switch tag {
        case .header:
            guard let header = FbNettyConnectHeader.header(from: data) else {
                sock.disconnect()
                break
            }

            sock.readData(toLength: header.bodySize, withTimeout: readTimeout * 2, tag: NettyTag.body.rawValue)
        case .body:
            if let answer = FbNettyAnswer(data: data) {
                recievedAnswer(answer)
            } else {
                
            }
            sock.readData(toLength: NettyHeaderLength, withTimeout: readTimeout * 2, tag: NettyTag.header.rawValue)
        }
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        connecting.set(false)
        //log.verbose("netty disconnected,err=\(err)")
        gLog("netty socketDidDisconnect,error=\(err)")
        self.joinsLock.lock()
        var newRequests:[String:FbNettyRequest] = [:]
        var newStatus:[String:NettyJoinStatus] = [:]
        for (key,status) in joinStatus {
            if status == .beforeJoin || status == .joining || status == .normal {
                newRequests[key] = joinRequests[key]
                newStatus[key] = status
            }
        }
        //不应该影响joinOutUniqueIds变量
        self.joinStatus = newStatus
        self.joinRequests = newRequests
        let count = newStatus.count
        self.joinsLock.unlock()

        self.connectInited.set(false)
        if let error = err as NSError?,canReconnectionCode(error) && count>0 && self.strconnect(useQueue: false) {
            answerLock.lock()
            let newCache = answerTaskCache
            var removeKey:[String] = []
            for (key, answerTask) in newCache {
                let asyncSocketError = GCDAsyncSocketError.init(_nsError: error)
                if asyncSocketError.code == .writeTimeoutError {
                    removeKey.append(key)
                    answerTaskCache.removeValue(forKey: key)
                }else if answerTask.quest.contentBody?.type == .join || answerTask.quest.contentBody?.type == .exit {
                    removeKey.append(key)
                    answerTaskCache.removeValue(forKey: key)
                }
            }
            answerLock.unlock()
            for oneKey in removeKey {
                if let answerTask = newCache[oneKey] {
                    let asyncSocketError = GCDAsyncSocketError.init(_nsError: error)
                    if asyncSocketError.code == .writeTimeoutError {
                        let userInfo = [NSLocalizedFailureReasonErrorKey: "FbNettyClient connection is breakon!"]
                        let error = NSError(domain: "FbNettyClient connection is breakon!", code: 101, userInfo: userInfo)
                        answerTask.cancelTask.cancel()
                        answerTask.callback(.failure(.system(error)))
                    }else if answerTask.quest.contentBody?.type == .join || answerTask.quest.contentBody?.type == .exit {
                        answerTask.cancelTask.cancel()
                        answerTask.callback(.failure(.cancel))
                    }
                }
            }
            
        }else{
            answerLock.lock()
            let newCache = answerTaskCache
            answerTaskCache.removeAll()
            answerLock.unlock()
            for (key,answerStore) in newCache {
                answerStore.cancelTask.cancel()

                let userInfo = [NSLocalizedFailureReasonErrorKey: "FbNettyClient connection is breakon!"]
                let error = NSError(domain: "FbNettyClient connection is breakon!", code: 102, userInfo: userInfo)
                answerStore.callback(.failure(.system(error)))
            }

            self.disconnect()
            checkStopAsync(flush: true,force: true)
            DispatchQueue.main.async { [weak self] in
                if self?.socket.isConnected == false {
                    self?.connectRefreshBlock?(false)
                }
            }
            
        }
    }
    
    fileprivate func canReconnectionCode(_ error: NSError) -> Bool {
        let asyncSocketError = GCDAsyncSocketError.init(_nsError: error)
        
        switch asyncSocketError.code {
        case .connectTimeoutError, .readTimeoutError, .writeTimeoutError, .readMaxedOutError:
            return true
        default:
            return false
        }
    }

}
