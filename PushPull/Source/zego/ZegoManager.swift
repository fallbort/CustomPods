//
//  ZegoManager.swift
//  MeMe
//
//  Created by 田家鑫 on 2021/7/19.
//  Copyright © 2021 sip. All rights reserved.
//

#if ZegoImported

import UIKit
import MeMeKit
import SwiftyJSON
import ZegoExpressEngine

// 旁路推流，整个画面的宽、高的默认数值。
fileprivate var TranscodingWindowWidthDefault: CGFloat = 360
fileprivate var TranscodingWindowHeightDefault: CGFloat = 640
fileprivate let TranscodingWindowWidthStr = "ikWidth="
fileprivate let TranscodingWindowHeightStr = "ikHeight="
//fileprivate let TranscodingBackgroundImageUrl = "preset-id://d9iyrkd8y2zpr.cloudfront.net/webapi-assets-test/resources/banners/201811/cms3-message-18yy8y7t3ntdgto3.png"
fileprivate let TranscodingBackgroundImageUrl_test = "preset-id://2898695260_live_pk_background.png"
fileprivate let TranscodingBackgroundImageUrl = "preset-id://2898695260_live_pk_background.png"

// PK窗口布局参数
fileprivate let PKWindowSpaceTop = 130.0 * UIScreen.main.bounds.size.height / 640
fileprivate let PKWindowSpaceTopNew = 100.0 * UIScreen.main.bounds.size.height / 640
fileprivate let PKWindowWidth = UIScreen.main.bounds.size.width / 2
fileprivate let PKWindowSpaceRight = PKWindowWidth
fileprivate let PKWindowHeight = 250 * UIScreen.main.bounds.size.height / 667

protocol ZegoDelegate : NSObjectProtocol {
    func iJoinedChannel(channel: String)
    // 我退出channel频道成功。
    func iLeavedChannel()
    
    // uid 加入当前所在频道
    func didJoinedOfUid(uid: UInt)
    // uid 离开当前所在频道
    func didOfflineOfUid(uid: UInt,reason:LivePushUserOfflineReason?)
    // 当前频道整体质量（定时回调）
    func onPublisherQualityUpdate(_ quality: ZegoPublishStreamQuality, streamID: String)
    
    // 主播PK，PK匹配成功，添加PK者的视图
    func addPKUserWindow(view: UIView)
    // 主播PK，PK一次结束，移除PK者的视图
    func removePKUserWindow(view: UIView)
    
    // uid 该用户关闭了自己的摄像头
    func didVideoMuted(mute: Bool, uid: UInt)
    
    //首针渲染
    func onPlayerRenderVideoFirstFrame(_ uid: Int)
    //token过期了
    func livePushTokenExpired()
    //音频路由改变
    func didAudioRouteChanged(routing: MeMeAudioOutputRouting)
    //是说话人的回调
    func audioSpeakers(speakersId:[UInt])
    //获取数据
    func livePushDataDidFetched(type:SendDataType,uid:Int,data:[String:Any]?)
    //下行码率
    func onPlayerQualityUpdate(videoKBPS: Double)
    //上行码率
    func onPublisherQualityUpdate(videoSendBytes: Double)
}

class ZegoManager: NSObject {
    fileprivate var devMode:Bool = false
    fileprivate var isProductMode:Bool = false
   weak var delegate:ZegoDelegate?
    var logViewBlock:(()->UIView?)?
    var roomID = ""
    var token:String?
    var streamId: String {
        get {
            return Self.getStreamID(roomId: roomID, userId: liveObject.currentUid)
        }
    }
    var publishCdnurl: String? {
        didSet {
            startMixerTask()
        }
    }
    var _myPosition:Int = 0
    var myPosition:Int {
        if _myPosition == 0 {
            return _myPosition
        }else if let orderedUsers = orderedUsers {
            if liveObject.liveType == .multiVideo {
                return orderedUsers.firstIndex(of: UInt(liveObject.currentUid)) ?? -1
            }else{
                return _myPosition
            }
        }else{
            return _myPosition
        }
    }
    
    var isEnableCamera: Bool = true {
        didSet {
            toggleCameraSwitch()
        }
    }
    
    var isEnableMic: Bool = true {
        didSet {
            toggleMicSwitch()
        }
    }
    
    var isEnableSpeaker: Bool = true {
        didSet {
            toggleSpeakerSwitch()
        }
    }
    var loginRoomFailure: VoidBlock?
    var soundLevelUpdateBlock:((_ speakers:[String:String],_ roomId:String)->())?
    
    fileprivate var previewBGView = UIView()
    
    fileprivate var transcodingLayoutWidth: CGFloat = TranscodingWindowWidthDefault    // 旁路推流的初始化宽
    fileprivate var transcodingLayoutHeight: CGFloat = TranscodingWindowHeightDefault  // 旁路推流的初始化高
    
    fileprivate var mixerTask: ZegoMixerTask?
    fileprivate var player: ZegoAudioEffectPlayer?
    
    fileprivate var isFrontCamera:Bool = true
    
    fileprivate var orderedUsers:[UInt?]? //已排序的用户列表
    fileprivate var cameraStates = [String: Bool]()
    fileprivate lazy var addedPlayerIdSet = Set<String>() //所有已加入channel的用户
    fileprivate lazy var allPlayerIDList = Array<String?>.init(repeating: nil, count: self.number) { //所有已加入频道并排序的用户
        didSet {
            if allPlayerIDList != oldValue {
                if _myPosition == 0 {
                    startMixerTask()
                }
            }
        }
    }
    
    fileprivate var streamFinishedList = [String:Bool]()
    fileprivate var streamMixedList = [String:Bool]()
    
    fileprivate let number: Int
    fileprivate let liveObject:MeMeLivePushObject
    fileprivate var showViews:[UIView?] = []
    fileprivate var needRemoveViews:[UIView] = []
    fileprivate var updateTokenTimer: CancelableTimeoutBlock?
    fileprivate var isLoginRoomStage = false
    deinit {
        if self.devMode == true {
            tipLabel.removeFromSuperview()
        }
        clearCacheMixPosition()
        msgManager.end()
    }
    init(liveObject:MeMeLivePushObject,devMode:Bool,isProductMode:Bool) {
        self.devMode = devMode
        self.isProductMode = isProductMode
        self.liveObject = liveObject
        self.number = liveObject.seatNum
        self.showViews = Array<UIView?>.init(repeating: nil, count: self.number)
        if !((liveObject.liveType == .PK || liveObject.liveType == .newPK)) {
            if self.showViews.count > 0 {
                self.showViews[0] = liveObject.preview
            }
        }
        for (index,view) in (liveObject.views ?? []).enumerated() {
            if liveObject.liveType == .connectlive || liveObject.liveType == .Video || liveObject.liveType == .VideoCall {
                let newIndex = index + 1
                if self.showViews.count > newIndex {
                    self.showViews[newIndex] = view
                }
            }else if liveObject.liveType == .PK || liveObject.liveType == .newPK {
                //此处延缓设置
            }else{
                if self.showViews.count > index {
                    self.showViews[index] = view
                }
            }
        }
        super.init()
        self.previewBGView = liveObject.preview ?? UIView()
        createEngine(isBroadcast: liveObject.isAnchor)
        MemeTracker.trace(event: .zegoLog, status: "init", ext: nil, detail: ["showViewsCount":"\(self.showViews.count)","number":"\(number)","isProductMode":"\(isProductMode)","liveType":"\(liveObject.liveType.rawValue)"])
    }
    
    func createEngine(isBroadcast: Bool) {
        let appID: UInt32 = ZGKeyCenter.appID(isProductMode)
        let appSign: String = ZGKeyCenter.appSign(isProductMode)
        let isTestEnv: Bool = self.devMode
        let scenario: ZegoScenario = .general
        
        ZegoExpressEngine.createEngine(withAppID: appID, appSign: appSign, isTestEnv: false, scenario: scenario, eventHandler: self)
        isEngineCreated = true
        
        //视频设置
        if self.liveObject.liveType == .multiVideo {
            let videoConfig = ZegoVideoConfig()
            if number == 4 {
                videoConfig.encodeResolution = CGSize(width: 270, height: 270)
                videoConfig.bitrate = 200
            } else if number == 6 && isBroadcast {
                videoConfig.encodeResolution = CGSize(width: 360, height: 360)
                videoConfig.bitrate = 400
            } else {
                videoConfig.encodeResolution = CGSize(width: 180, height: 180)
                videoConfig.bitrate = 130
            }
            videoConfig.fps = 15
            ZegoExpressEngine.shared().setVideoConfig(videoConfig)
            ZegoExpressEngine.shared().setVideoMirrorMode(.noMirror)
        }else if self.liveObject.liveType == .PK || liveObject.liveType == .newPK {
            let videoConfig = ZegoVideoConfig()
            let size = CGSize(width:720, height:1280)
            videoConfig.encodeResolution = size
            videoConfig.bitrate = 500
            videoConfig.fps = 15
            ZegoExpressEngine.shared().setVideoConfig(videoConfig)
            ZegoExpressEngine.shared().setVideoMirrorMode(.noMirror)
        }else if self.liveObject.liveType == .connectlive {
            let videoConfig = ZegoVideoConfig()
            let size = CGSize(width:720, height:1280)
            videoConfig.encodeResolution = size
            videoConfig.bitrate = 500
            videoConfig.fps = 15
            ZegoExpressEngine.shared().setVideoConfig(videoConfig)
            ZegoExpressEngine.shared().setVideoMirrorMode(.noMirror)
        }else if self.liveObject.liveType == .Video {
            let videoConfig = ZegoVideoConfig()
            let size = CGSize(width:720, height:1280)
            videoConfig.encodeResolution = size
            videoConfig.bitrate = 500
            videoConfig.fps = 15
            ZegoExpressEngine.shared().setVideoConfig(videoConfig)
            if liveObject.isAnchor == true {
                ZegoExpressEngine.shared().setVideoMirrorMode(.noMirror)
            }else{
                ZegoExpressEngine.shared().setVideoMirrorMode(.bothMirror)
            }
        }else if self.liveObject.liveType == .VideoCall {
            let videoConfig = ZegoVideoConfig()
            let size = CGSize(width:720, height:1280)
            videoConfig.encodeResolution = size
            videoConfig.bitrate = 800
            videoConfig.fps = 15
            ZegoExpressEngine.shared().setVideoConfig(videoConfig)
            if liveObject.isAnchor == true {
                ZegoExpressEngine.shared().setVideoMirrorMode(.noMirror)
            }else{
                ZegoExpressEngine.shared().setVideoMirrorMode(.bothMirror)
            }
        }else if self.liveObject.liveType == .Radio || self.liveObject.liveType == .VoiceCall || self.liveObject.liveType == .Voice {
            ZegoExpressEngine.shared().enableCamera(false)
        }
        
        if liveObject.liveType == .Video || liveObject.liveType == .PK || liveObject.liveType == .newPK ,liveObject.isAnchor == false {
 
        }else if self.liveObject.liveType == .Radio || self.liveObject.liveType == .VoiceCall || self.liveObject.liveType == .Voice {
            
        }else{
            let captureConfig = ZegoCustomVideoCaptureConfig()
            captureConfig.bufferType = .cvPixelBuffer
            ZegoExpressEngine.shared().enableCustomVideoCapture(true, config: captureConfig)
            ZegoExpressEngine.shared().setCustomVideoCaptureHandler(self)
        }
        
        
        
        //音频设置
        let audioConfig = ZegoAudioConfig()
        audioConfig.channel = .mono
        audioConfig.bitrate = 44
        audioConfig.codecID = .normal2
        ZegoExpressEngine.shared().setAudioConfig(audioConfig)
        ZegoExpressEngine.shared().startSoundLevelMonitor()

//        //流量控制
        ZegoExpressEngine.shared().enableTrafficControl(true, property: .adaptiveResolution)
    }
    
    // MARK: Exit
    
    func destroyEngine() {
        guard isEngineCreated == true else {return}
        if let task = mixerTask {
            ZegoExpressEngine.shared().stop(task, callback: nil)
        }
//        self.stopPublishingStream()
        //log.verbose("zegolog logoutRoom=\(roomID)")
        ZegoExpressEngine.shared().logoutRoom()
        ZegoExpressEngine.destroy(nil)
        isEngineCreated = false
        isLoginRoomStage = false
        updateTokenTimer?.cancel()
        updateTokenTimer = nil
        
        streamFinishedList.removeAll()
        streamMixedList.removeAll()
        addedPlayerIdSet.removeAll()
        orderedUsers = nil
        for oneView in needRemoveViews {
            oneView.removeFromSuperview()
        }
        needRemoveViews.removeAll()
        
        if self.devMode == true {
            tipLabel.removeFromSuperview()
        }
        if isRoomConnecting == true {
            isRoomConnecting = false
            self.delegate?.iLeavedChannel()
        }
        MemeTracker.trace(event: .zegoLog, status: "destroyEngine", ext: nil, detail: ["roomID":"\(roomID)"])
    }
    
    func setChannelRole(role: LivePushClientRole) {
        guard isRoleBroadcaster != (role == .broadcaster) else {return}
        MemeTracker.trace(event: .zegoLog, status: "setChannelRole", ext: nil, detail: ["role":"\(role.rawValue)"])
        isRoleBroadcaster = role == .broadcaster ? true : false
        if roomID.count > 0 {
            if isRoleBroadcaster == true {
                setStreamExtraInfo()
                startPublishingStream()
            }else {
                self.stopPublishingStream()
            }
        }
        msgManager.isBroadcastor = isRoleBroadcaster
    }
    
    func loginRoom(roomID: String, token: String?) {
        self.roomID = roomID
        isLoginRoomStage = true
        updateTokenTimer?.cancel()
        updateTokenTimer = nil
        
        if liveObject.liveType == .PK || liveObject.liveType == .newPK {
            lazyAddPKViews(uids: [0,0])
        }
        if let token = token,token.count > 0 {
            self.token = token
            let userId = liveObject.currentUid
            let config = ZegoRoomConfig.default()
            config.token = token
            //log.verbose("zegolog loginRoom,roomID=\(roomID),token=\(token)")
            MemeTracker.trace(event: .zegoLog, status: "loginRoom", ext: nil, detail: ["roomID":"\(roomID)","userId":"\(userId)"])
            ZegoExpressEngine.shared().loginRoom(roomID, user: ZegoUser(userID: "\(userId)"), config: config)
            _myPosition = liveObject.myPos
            setStreamExtraInfo()
            var myIdHasSetted = false
            if liveObject.liveType == .Video {
                if liveObject.isAnchor == false {
                    //非自采集走这个逻辑
                    if addedPlayerIdSet.contains(streamId) == false {
                        addedPlayerIdSet.insert(streamId)
                    }
                    myIdHasSetted = true
                    replayStreams()
                }
            }
            if myIdHasSetted == false {
                cameraStates[streamId] = true
                MemeTracker.trace(event: .zegoLog, status: "allPlayerIDList", ext: nil, detail: ["isAdd":"true","position":"\(_myPosition)","streamId":"\(streamId)"])
                if _myPosition >= 0 {
                    allPlayerIDList[_myPosition] = streamId
                }
            }
            
            if isRoleBroadcaster == true {
                setStreamExtraInfo()
                startPublishingStream()
            }
            
            msgManager.streamId = self.streamId
            msgManager.roomId = self.roomID
            msgManager.isBroadcastor = isRoleBroadcaster
        }else{
            self.delegate?.livePushTokenExpired()
        }
    }
    
    func leaveChannel() {
        isLoginRoomStage = false
        if self.roomID.count > 0 {
            if self.devMode == true {
                tipLabel.removeFromSuperview()
            }
            MemeTracker.trace(event: .zegoLog, status: "leaveChannel", ext: nil, detail: ["roomID":"\(roomID)"])
            ZegoExpressEngine.shared().logoutRoom(self.roomID)
            updateTokenTimer?.cancel()
            updateTokenTimer = nil
        }
    }
    
    func setStreamExtraInfo() {
        let extInfo = ["p":_myPosition].toJsonString() ?? ""
        ZegoExpressEngine.shared().setStreamExtraInfo(extInfo, callback: nil)
    }
    
    func startPublishingStream() {
        //log.verbose("zegolog startPublishingStream=\(streamId)")
        isOutPublishingStream = true
        if liveObject.liveType == .Voice {
            if isEnableMic == true {
                MemeTracker.trace(event: .zegoLog, status: "startPublishingStream", ext: nil, detail: ["roomID":"\(roomID)"])
                ZegoExpressEngine.shared().startPublishingStream(streamId)
            }
        }else{
            MemeTracker.trace(event: .zegoLog, status: "startPublishingStream", ext: nil, detail: ["roomID":"\(roomID)"])
            ZegoExpressEngine.shared().startPublishingStream(streamId)
        }
        
    }
    
    private func toggleCameraSwitch() {
        MemeTracker.trace(event: .zegoLog, status: "enableCamera", ext: nil, detail: ["isEnableCamera":"\(isEnableCamera)"])
        ZegoExpressEngine.shared().enableCamera(isEnableCamera)
    }
    
    private func toggleMicSwitch() {
        MemeTracker.trace(event: .zegoLog, status: "muteMicrophone", ext: nil, detail: ["isEnableMic":"\(isEnableMic)"])
        ZegoExpressEngine.shared().muteMicrophone(!isEnableMic)
        if liveObject.liveType == .Voice {
            if isEnableMic == true {
                if isOutPublishingStream {
                    MemeTracker.trace(event: .zegoLog, status: "startPublishingStream", ext: nil, detail: ["roomID":"\(roomID)"])
                    ZegoExpressEngine.shared().startPublishingStream(streamId)
                }
            }else{
                MemeTracker.trace(event: .zegoLog, status: "stopPublishingStream", ext: nil, detail: ["roomID":"\(roomID)"])
                ZegoExpressEngine.shared().stopPublishingStream()
            }
        }
    }
    
    private func toggleSpeakerSwitch() {
        MemeTracker.trace(event: .zegoLog, status: "muteSpeaker", ext: nil, detail: ["isEnableSpeaker":"\(isEnableSpeaker)"])
        ZegoExpressEngine.shared().muteSpeaker(!isEnableSpeaker)
    }
    
    // 重置Token。
    func renewToken(token: String) {
        //log.verbose("renew zegoToken=\(token)")
        updateTokenTimer?.cancel()
        updateTokenTimer = nil
        if token.count > 0 {
            if self.isLoginRoomStage == true {
                if self.token == nil {
                    self.loginRoom(roomID: self.roomID, token: token)
                }else{
                    self.token = token
                    ZegoExpressEngine.shared().renewToken(token, roomID: roomID)
                }
            }
        }else{
            updateTokenTimer?.cancel()
            updateTokenTimer = timeout(2.0) { [weak self] in
                self?.delegate?.livePushTokenExpired()
            }
        }
    }
    
    func playEffectSound(filePath: String, isPublishOut: Bool = true, effectID: UInt32 = 1) {
        if player == nil {
            player = ZegoExpressEngine.shared().createAudioEffectPlayer()
            player?.setEventHandler(self)
        }
        player?.stopAll()
        let playerConfig = ZegoAudioEffectPlayConfig()
        playerConfig.playCount = 1
        playerConfig.isPublishOut = isPublishOut
        MemeTracker.trace(event: .zegoLog, status: "playEffectSound", ext: nil, detail: ["effectID":"\(effectID)"])
        player?.start(effectID, path: filePath, config: playerConfig)
    }
    
    func stopPlayEffectSound(effectID: UInt32 = 1) {
        MemeTracker.trace(event: .zegoLog, status: "stopPlayEffectSound", ext: nil, detail: ["effectID":"\(effectID)"])
        player?.stop(effectID)
    }
    
    func exchangeCameraFrontOrBack() {
        let oldDirection = isFrontCamera
        isFrontCamera = !oldDirection
        ZegoExpressEngine.shared().useFrontCamera(isFrontCamera)
    }
    
    func muteOwnAudio(muted:Bool) {
        isEnableMic = muted == false
    }
    
    func muteOneUserAudio(uid:Int,muted:Bool) {
        let oneStreamId = "\(roomID)_\(uid)"
        if oneStreamId == streamId {
            muteOwnAudio(muted:muted)
        }else{
            MemeTracker.trace(event: .zegoLog, status: "mutePlayStreamAudio", ext: nil, detail: ["oneStreamId":"\(oneStreamId)","muted":"\(muted)"])
            ZegoExpressEngine.shared().mutePlayStreamAudio(muted, streamID: oneStreamId)
        }
    }
    
    func muteOtherUsersAudio(muted:Bool) {
        for (index,oneStreamId) in allPlayerIDList.enumerated() {
            if let oneStreamId = oneStreamId {
                if oneStreamId == streamId {
                    continue
                }else{
                    MemeTracker.trace(event: .zegoLog, status: "mutePlayStreamAudio", ext: nil, detail: ["oneStreamId":"\(oneStreamId)","muted":"\(muted)"])
                    ZegoExpressEngine.shared().mutePlayStreamAudio(muted, streamID: oneStreamId)
                }
            }
        }
    }
    
    // 是否开启外功放
    func enableSpeakerphone(enableSpeaker: Bool) -> Int {
        MemeTracker.trace(event: .zegoLog, status: "setAudioRouteToSpeaker", ext: nil, detail: ["enableSpeaker":"\(enableSpeaker)"])
        ZegoExpressEngine.shared().setAudioRouteToSpeaker(enableSpeaker)
        return 1
    }
    
    //耳返
    func enableInEarMonitoring(enable: Bool) -> Int {
        ZegoExpressEngine.shared().enableHeadphoneMonitor(enable)
        return 0
    }
    
    func syncCapture(sampleBuffer: CMSampleBuffer?) {
        guard let sampleBuffer = sampleBuffer, isStarted == true else { return  }
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        ZegoExpressEngine.shared().sendCustomVideoCapture(pixelBuffer, timestamp: time)
    }
    
    func stopPublishingStream() {
        //log.verbose("zegolog stopPublishingStream")
        isOutPublishingStream = false
        MemeTracker.trace(event: .zegoLog, status: "stopPublishingStream", ext: nil, detail: ["roomID":"\(roomID)"])
        ZegoExpressEngine.shared().stopPublishingStream()
    }
    
    func videoMuteUser(_ isMute: Bool) {
        let myId = liveObject.currentUid
        if  cameraStates["\(roomID)_\(myId)"] == isMute {
            cameraStates["\(roomID)_\(myId)"] = !isMute
            startMixerTask(force:true)
        }
    }
    
    func setCaptureVolume(volume:Int) {
        captureVolume = volume
        MemeTracker.trace(event: .zegoLog, status: "setCaptureVolume", ext: nil, detail: ["volume":"\(volume)"])
        ZegoExpressEngine.shared().setCaptureVolume(Int32(volume))
    }
    
    func getCaptureVolume() -> Int {
        return captureVolume
    }
    
    func getUserId(streamId:String) -> Int? {
        let userIds = streamId.description.components(separatedBy: "_")
        if userIds.count >= 2 {
            return (userIds[1] as NSString).integerValue
        }
        return nil
    }
    
    func sendData(type:SendDataType,params:[String:Any]) {
        var newParams = params
        newParams["type"] = type.rawValue
        DispatchQueue.global().async { [weak self] in
            if let data = newParams.toJsonString()?.data(using: .utf8) {
                self?.msgManager.sendData(data: data)
            }
        }
    }
    
    class func getStreamID(roomId:String,userId:Int) -> String {
        return "\(roomId)_\(userId)"
    }
    
    var tipLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.regular)
        view.textColor =  UIColor.hexString(toColor: "#ff0000")!
        view.text = "zego"
        view.sizeToFit()
        return view
    }()
    
    var isRoomConnecting = false
    var isEngineCreated = false
    private var isStarted = false
    
    private var captureVolume = 100
    private var isRoleBroadcaster = true
    
    private var mixingVolume = 50  //混音音量
    fileprivate var isPausedMix:Bool?
    
    fileprivate var mixPositionTimer: GCDTimer? = nil
    fileprivate var mixPositionTimePassed: TimeInterval = 0
    fileprivate var cacheMixPosition: Int?  //ms
    
    fileprivate var mixStateChangedBlock:((_ state:LivePushAudioMixingStateCode)->())?
    fileprivate var audioMixedID:UInt32? //混音id
    fileprivate var mixPreset:MeMeAudioEffectPreset = .source
    
    fileprivate var dataTypeStream:[SendDataType:Int] = [:]
    
    fileprivate var msgManager:ZegoMessageManager = ZegoMessageManager()
    
    fileprivate var isOutPublishingStream = false
}

extension ZegoManager {
    private func getPreviewView(withPosition position: Int) -> UIView? {
        if showViews.count > position,position >= 0 {
            let pv = showViews[position]
            return pv
        }
        return nil
    }
    
    private func addRemoteViewObjectIfNeedWithStreamID(position: Int, streamID: String) {
        if let previewView = getPreviewView(withPosition: position) {
            let playCanvas = ZegoCanvas(view: previewView)
            playCanvas.viewMode = .aspectFill
            //log.verbose("zegolog startPlayingStream,streamID=\(streamID)")
            MemeTracker.trace(event: .zegoLog, status: "startplay", ext: nil, detail: ["streamId":"\(streamID)","position":"\(position)"])
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: playCanvas)
            if position < number {
                cameraStates[streamID] = true
                MemeTracker.trace(event: .zegoLog, status: "allPlayerIDList", ext: nil, detail: ["isAdd":"true","position":"\(position)","streamId":"\(streamID)"])
                allPlayerIDList[position] = streamID
            }
        }else{
            let playCanvas = ZegoCanvas()
            //log.verbose("zegolog startPlayingStream,streamID=\(streamID)")
            MemeTracker.trace(event: .zegoLog, status: "startplay", ext: nil, detail: ["streamId":"\(streamID)","position":"\(position)"])
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: playCanvas)
            if position < number {
                cameraStates[streamID] = false
                MemeTracker.trace(event: .zegoLog, status: "allPlayerIDList", ext: nil, detail: ["isAdd":"true","position":"\(position)","streamId":"\(streamID)"])
                if position >= 0 {
                    allPlayerIDList[position] = streamID
                }
            }
        }
    }
    
    private func removeViewObjectWithStreamID(streamID: String) {
        //log.verbose("zegolog stopPlayingStream,streamID=\(streamID)")
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
        if let index = allPlayerIDList.firstIndex(of: streamID) {
            cameraStates[streamID] = nil
            MemeTracker.trace(event: .zegoLog, status: "allPlayerIDList", ext: nil, detail: ["isAdd":"false","postion":"\(_myPosition)","streamId":"\("")"])
            allPlayerIDList[index] = nil
        }
    }
    
    func resetCanvasFrame(rect: CGRect, uid: UInt) {
        if liveObject.liveType == .VideoCall {
            //无需逻辑
        }
    }
    
    func resetCanvas(uids: [UInt?]) {
        //log.verbose("zegolog resetCanvas,uids=\(uids)")
        orderedUsers = uids
        let trackerArray:[String] = (orderedUsers ?? [UInt]()).map({"\($0)"})
        MemeTracker.trace(event: .zegoLog, status: "orderedUsers", ext: nil, detail: ["roomID":roomID,"orderedUsers":"\(trackerArray.joined(separator: ","))"])
        if liveObject.liveType == .PK || liveObject.liveType == .newPK {
            self.resetPKCanvas(uids: uids)
        }else if liveObject.liveType == .connectlive {
            self.resetConnectLiveCanvas(uids: uids)
        }else if liveObject.liveType == .Video {
            self.resetVideoCanvas(uids: uids)
        }else if liveObject.liveType == .VideoCall {
            orderedUsers = [UInt(liveObject.currentUid)]
            if let oppUid = uids.first {
                orderedUsers?.append(oppUid)
            }
            let trackerArray:[String] = (orderedUsers ?? [UInt]()).map({"\($0)"})
            MemeTracker.trace(event: .zegoLog, status: "orderedUsers", ext: nil, detail: ["roomID":roomID,"orderedUsers":"\(trackerArray.joined(separator: ","))"])
            self.resetVideoCallCanvas(uids: uids)
        }else if liveObject.liveType == .Voice {
            self.resetVoiceCanvas(uids: uids)
        }else if liveObject.liveType == .multiVideo {
            self.replayStreams()
        }
    }
    
    func setPKWindowHidden(hidden: Bool) {
        //log.verbose("zegolog setPKWindowHidden,hidden=\(hidden)")
        if liveObject.liveType == .PK || liveObject.liveType == .newPK {
            if showViews.count >= 2 {
                let position = 1
                let pkView = self.getPreviewView(withPosition: position)
                pkView?.isHidden = hidden
            }
        }
    }
    
    func resetPKCanvas(uids: [UInt?]) {
        if liveObject.liveType == .PK || liveObject.liveType == .newPK  {
            
        }
    }
    
    func resetConnectLiveCanvas(uids: [UInt?]) {
        if liveObject.liveType == .connectlive {
            
        }
    }
    
    func resetVideoCanvas(uids: [UInt?]) {
        if liveObject.liveType == .Video {
            replayStreams()
        }
    }
    
    func resetVideoCallCanvas(uids: [UInt?]) {
        if liveObject.liveType == .VideoCall {
            replayStreams()
        }
    }
    
    func resetVoiceCanvas(uids: [UInt?]) {
        
    }
    
    func lazyAddPKViews(uids: [UInt]) {
        if liveObject.liveType == .PK || liveObject.liveType == .newPK {
            
            if uids.count >= 2 {
                var contentTop:CGFloat = 0
                var contentBottom:CGFloat = 0
                var top:CGFloat = PKWindowSpaceTop
                if liveObject.liveType == .newPK {
                    top = PKWindowSpaceTopNew
                }
                var height:CGFloat = PKWindowHeight
                let screenBounds = UIScreen.main.bounds
                if screenBounds.height / screenBounds.width < 640.0 / 360.0 {
                    let extraHeight = (640.0 * screenBounds.width / 360.0 - screenBounds.height) / 2.0
                    top = 130.0 * screenBounds.size.width / 360.0 - extraHeight;
                    if liveObject.liveType == .newPK {
                        top = 100.0 * screenBounds.size.width / 360.0 - extraHeight;
                    }
                    height = PKWindowWidth * 4.0 / 3.0
                }
                contentTop = top
                contentBottom = top + height
                for (index,uid) in uids.enumerated() {
                    if uid == 0 {continue}
                    let position = index
                    if self.getPreviewView(withPosition: position) == nil {
                        let hostingView = UIView(frame: CGRect(x: PKWindowSpaceRight * CGFloat(position), y: top, width: PKWindowWidth, height: height))
                        hostingView.isUserInteractionEnabled = false
                        hostingView.translatesAutoresizingMaskIntoConstraints = true
                        self.needRemoveViews.append(hostingView)
                        if self.showViews.count > position {
                            self.showViews[position] = hostingView
                        }
                    }
                    if let userView = self.getPreviewView(withPosition: position) {
                        delegate?.addPKUserWindow(view: userView)
                    }
                }
//                if self.needRemoveViews.contains(where: {$0.tag == 9998123}) == false {
//                    let topView      = UIImageView(image: UIImage(named: "pk_top_bg"))
//                    topView.tag = 9998123
//                    let bottomView   = UIImageView(image: UIImage(named: "pk_bottom_bg"))
//                    topView.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: contentTop)
//                    self.needRemoveViews.append(topView)
//                    delegate?.addPKUserWindow(view: topView)
//                    bottomView.frame = CGRect.init(x: 0, y: contentBottom, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - contentBottom)
//                    self.needRemoveViews.append(bottomView)
//                    delegate?.addPKUserWindow(view: bottomView)
//                }
            }
        }
    }
    
    func replayStreams() {
        if liveObject.liveType == .Video || liveObject.liveType == .VideoCall || liveObject.liveType == .multiVideo {
            if let orderedUsers = orderedUsers {
                var newList = Array<String?>.init(repeating: nil, count: self.number)
                for oneAdded in addedPlayerIdSet {
                    if let uid = getUserId(streamId: oneAdded),
                       let pos = orderedUsers.firstIndex(where: {$0 == UInt(uid)}),
                       allPlayerIDList.count > pos {
                        if allPlayerIDList[pos] != oneAdded {
                            removeViewObjectWithStreamID(streamID: oneAdded)
                            newList[pos] = oneAdded
                        }
                    }else{
                        if allPlayerIDList.contains(oneAdded) == true {
                            removeViewObjectWithStreamID(streamID: oneAdded)
                        }
                    }
                }
                if newList.first(where: {$0 != nil}) != nil {
                    for (pos,item) in newList.enumerated() {
                        if let item = item {
                            addRemoteViewObjectIfNeedWithStreamID(position: pos, streamID: item)
                        }
                    }
                    startMixerTask()
                }
            }
        }
    }
    
    fileprivate func judgeWhoIsSpeaking(speakers: [String:String]) -> [UInt] {
        var speakersNow = [UInt]();
        
        // 不是多人语音房间，不需要执行下面逻辑。
        guard liveObject.liveType == .Voice || liveObject.liveType == .Radio || liveObject.liveType == .VoiceCall else {
            return speakersNow
        }

        for (uidStr,VolumeStr) in speakers {
            let uidInt = (uidStr as NSString).integerValue
            let volumeInt = (VolumeStr as NSString).integerValue
            if isSpeakingJudgeVolume(volume: volumeInt) {
                var uid = uidInt
                
                if uid == 0 { // 如果SDK 返回的UID = 0，表示是自己。
                    uid = liveObject.currentUid
                }
                speakersNow.append(UInt(uid))
            }
        }
        
        return speakersNow
    }
    
    // 通过音量大小，判断是否在说话。
    fileprivate func isSpeakingJudgeVolume(volume: Int) -> Bool {
        if volume > 20 {
            return true
        }
        
        return false
    }
}

//混音
extension ZegoManager {
    func setMusicPitch(_ pitch: Int) -> Int {
        let param = ZegoVoiceChangerParam()
        param.pitch = Float(pitch)
        ZegoExpressEngine.shared().setVoiceChangerParam(param)
        return 1
    }
    
    func getAudioEffectPreset() -> MeMeAudioEffectPreset {
        return mixPreset
    }
    
    func setAudioEffectPreset(present:MeMeAudioEffectPreset) {
        mixPreset = present
        var preset:ZegoReverbPreset = .none
        switch present {
        
        case .source:
            preset = .none
        case .liuxing:
            preset = .popular
        case .rb:
            preset = .none
        case .ktv:
            preset = .KTV
        case .luyin:
            preset = .recordingStudio
        case .yanchang:
            preset = .vocalConcert
        case .liusheng:
            preset = .none
        case .uncle:
            preset = .none
        case .girl:
            preset = .none
        case .liti:
            preset = .none
        }
        ZegoExpressEngine.shared().setReverbPreset(preset)
    }
    
    func startAudioMixing(filePath: String, audioEffectID:UInt32, stageChanged: ((LivePushAudioMixingStateCode) -> ())?) -> Int {
        clearCacheMixPosition()
        mixStateChangedBlock = stageChanged
        self.audioMixedID = audioEffectID
        self.playEffectSound(filePath: filePath, isPublishOut: true, effectID: audioEffectID)
        return 1
    }
    func setAudioMixPosition(pos: Int,audioEffectID:UInt32) {
        clearCacheMixPosition()
        player?.seek(to: UInt64(pos), audioEffectID: audioEffectID, callback: nil)
    }
    
    func getAudioMixPosition(audioEffectID:UInt32) -> Int? {
        if mixPositionTimePassed < 2.0,let cacheMixPosition = cacheMixPosition {
            return Int(cacheMixPosition) + Int(mixPositionTimePassed * 1000)
        }else{
            var mixPos:Int?
            if isPausedMix != nil {
                if let player = player {
                    let pos = Int(player.getCurrentProgress(audioEffectID))
                    mixPos = Int(pos)
                }
            }
            if let mixPos = mixPos {
                clearCacheMixPosition()
                cacheMixPosition = mixPos
                mixPositionTimer?.cancel()
                mixPositionTimer = GCDTimer.init(interval: 0.1, skipFirst: true, block: { [weak self] in
                    guard let `self` = self else {return}
                    self.mixPositionTimePassed += 0.1
                })
            }
            return mixPos
        }
    }
    
    func clearCacheMixPosition() {
        cacheMixPosition = nil
        mixPositionTimePassed = 0
        mixPositionTimer?.cancel()
        mixPositionTimer = nil
    }
    
    func adjustAudioMixingVolume(volume: Int,audioEffectID:UInt32) {
        mixingVolume = volume
        let value = volume * 2
        player?.setVolume(Int32(volume), audioEffectID: audioEffectID)
    }
    
    func getAudioMixingVolum(audioEffectID:UInt32) -> Int {
        return mixingVolume
    }
    
    func pauseAudioMixing(isPause: Bool,audioEffectID:UInt32) {
        isPausedMix = isPause
        if isPause {
            clearCacheMixPosition()
            player?.pause(audioEffectID)
        }else{
            clearCacheMixPosition()
            player?.resume(audioEffectID)
        }
        
    }
    
    func getPauseAudioMixing(audioEffectID:UInt32) -> Bool? {
        return isPausedMix
    }
    
    func stopAudioMixing(audioEffectID:UInt32) {
        isPausedMix = nil
        mixStateChangedBlock = nil
        clearCacheMixPosition()
        self.audioMixedID = nil
        player?.stop(audioEffectID)
    }
    
    func makePosition(roomType:LivePushRoomType,oldPos:Int) -> Int {
        if liveObject.liveType == .Voice {
            for (index,item) in allPlayerIDList.enumerated() {
                if index >= 1 {
                    if item == nil {
                        return index
                    }
                }
            }
            return allPlayerIDList.count
        }
        return oldPos
    }
}

extension ZegoManager: ZegoEventHandler, ZegoAudioEffectPlayerEventHandler {
    func onPlayerQualityUpdate(_ quality: ZegoPlayStreamQuality, streamID: String) {
        self.delegate?.onPlayerQualityUpdate(videoKBPS: quality.videoKBPS)
    }
    
    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        if errorCode != 0 {
            let detail: [String : Any] = ["roomID": roomID,
                          "errorCode":errorCode]
            MemeTracker.trace(event: .zegoLog, status: "loginRoomFailure", detail: detail)
            loginRoomFailure?()
        }
        if state == .connected {
            //log.verbose("zego onRoomStateUpdate connected")
            // 语音，默认使用听筒模式
            if liveObject.liveType == .VoiceCall {
                ZegoExpressEngine.shared().setAudioRouteToSpeaker(false)
            }
            if liveObject.liveType == .Voice {
                msgManager.dataDidFetchedBlock = { [weak self] type,streamId,data in
                    if let uid = self?.getUserId(streamId: streamId) {
                        self?.delegate?.livePushDataDidFetched(type: type, uid: uid, data: data)
                    }
                }
                msgManager.start()
            }
            if self.devMode == true {
                let localPreview = self.logViewBlock?() ?? previewBGView
                tipLabel.removeFromSuperview()
                localPreview.addSubview(tipLabel)
                if liveObject.liveType == .multiVideo {
                    tipLabel.frame = CGRect.init(x: 5, y: 5, width: tipLabel.width, height: tipLabel.height)
                }else{
                    tipLabel.frame = CGRect.init(x: previewBGView.width - tipLabel.width - 5, y: 5, width: tipLabel.width, height: tipLabel.height)
                }
            }
            self.isRoomConnecting = true
            self.delegate?.iJoinedChannel(channel: roomID)
        }else if state == .disconnected {
            //log.verbose("zego onRoomStateUpdate disconnected")
            if self.devMode == true {
                tipLabel.removeFromSuperview()
            }
            msgManager.end()
            streamFinishedList.removeAll()
            streamMixedList.removeAll()
            self.isRoomConnecting = false
            self.isOutPublishingStream = false
            self.delegate?.iLeavedChannel()
        }
    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], roomID: String) {
        let streamIds:[String] = streamList.map({$0.streamID})
        MemeTracker.trace(event: .zegoLog, status: "onRoomStreamUpdate", ext: nil, detail: ["roomID":roomID,"updateType":"\(updateType)","streamIds":"\(streamIds.joined(separator: ","))"])
        if updateType == .add {
            // 主播PK
            if self.liveObject.liveType == .PK || liveObject.liveType == .newPK {
                let userId:Int = ((streamList.first?.user.userID ?? "") as NSString).integerValue
                let ids = [UInt(self.liveObject.anchorUid), UInt(userId)]
                lazyAddPKViews(uids: ids)
            }
            
            var needReplay = false
            for stream in streamList {
                msgManager.updateOtherUser(isAdd: true, streamId: stream.streamID)
                if addedPlayerIdSet.contains(stream.streamID) == false {
                    addedPlayerIdSet.insert(stream.streamID)
                }
                if !allPlayerIDList.contains(stream.streamID) {
                    var position = (stream.extraInfo.convertToDictionary()?["p"] as? Int) ?? 1
                    if liveObject.liveType == .PK || liveObject.liveType == .newPK || liveObject.liveType == .connectlive {
                        position = 1
                        if "\(liveObject.anchorUid)" == stream.user.userID {
                            position = 0
                        }
                        addRemoteViewObjectIfNeedWithStreamID(position: position, streamID: stream.streamID)
                    }else if liveObject.liveType == .Video || liveObject.liveType == .VideoCall {
                        needReplay = true
                    }else if liveObject.liveType == .multiVideo {
                        needReplay = true
                    }else {
                        position = makePosition(roomType: liveObject.liveType,oldPos:position)
                        addRemoteViewObjectIfNeedWithStreamID(position: position, streamID: stream.streamID)
                    }
                }
            }
            var array:[String] = []
            for item in addedPlayerIdSet {
                array.append(item)
            }
            MemeTracker.trace(event: .zegoLog, status: "onRoomStreamUpdate", ext: nil, detail: ["addedPlayerIdSet":"\(array.joined(separator: ","))"])
            if needReplay == true {
                replayStreams()
            }
            
            for stream in streamList {
                let userId:Int = ((stream.user.userID) as NSString).integerValue
                self.delegate?.didJoinedOfUid(uid: UInt(userId))
            }
            startMixerTask()
        } else if updateType == .delete {
            for stream in streamList {
                msgManager.updateOtherUser(isAdd: false, streamId: stream.streamID)
                addedPlayerIdSet.remove(stream.streamID)
                removeViewObjectWithStreamID(streamID: stream.streamID)
            }
            var array:[String] = []
            for item in addedPlayerIdSet {
                array.append(item)
            }
            MemeTracker.trace(event: .zegoLog, status: "onRoomStreamUpdate", ext: nil, detail: ["addedPlayerIdSet":"\(array.joined(separator: ","))"])
            if liveObject.liveType == .Video || liveObject.liveType == .VideoCall {
                replayStreams()
            }else if liveObject.liveType == .multiVideo {
                replayStreams()
            }
            
            // 主播PK
            if liveObject.liveType == .PK || liveObject.liveType == .newPK {
                let position = 1
                if self.showViews.count >= 2 {
                    if let userView = self.getPreviewView(withPosition: position) {
                        userView.isHidden = true
                        delegate?.removePKUserWindow(view: userView)
                    }
                }
                leaveChannel()
            }
            for stream in streamList {
                let userId:Int = ((stream.user.userID ?? "") as NSString).integerValue
                self.delegate?.didOfflineOfUid(uid: UInt(userId), reason: .quit)
            }
            startMixerTask()
        }
    }
    
    func onCapturedSoundLevelUpdate(_ soundLevel: NSNumber) {
        let uid = liveObject.currentUid
        var soundLevelShow:Float = soundLevel.floatValue * 2.0
        soundLevelShow = soundLevelShow > 100.0 ? 100.0 : soundLevelShow
        guard soundLevel.floatValue > 5 else {
            return
        }
        let soundLevels = ["\(uid)": "\(soundLevelShow)"]
        soundLevelUpdateBlock?(soundLevels,roomID)
        
        let speakers = judgeWhoIsSpeaking(speakers: soundLevels)
        delegate?.audioSpeakers(speakersId: speakers)
        
        if myPosition > 0 {
            return
        }
        
        if _myPosition == 0, liveObject.liveType == .multiVideo {
            var dic = [String: Any]()
            dic["type"] = 1
            dic["soundLevels"] = soundLevels
            if let data = try? JSONSerialization.data(withJSONObject: dic, options: .fragmentsAllowed) {
                msgManager.sendData(data: data, forceMode: .useSEI)
            }
        }
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        var soundlevels = [String: String]()
        for soundLevel in soundLevels {
            var soundLevelShow:Float = soundLevel.1.floatValue * 2.0
            soundLevelShow = soundLevelShow > 100.0 ? 100.0 : soundLevelShow
            var soundLevelUid:String = soundLevel.0
            if soundLevelShow > 5 {
                let userIds = soundLevelUid.description.components(separatedBy: "_")
                if userIds.count > 1 {
                    soundLevelUid = userIds[1]
                }
            }
            soundlevels[soundLevelUid] = "\(soundLevelShow)"
        }
        if soundlevels.count > 0 {
            soundLevelUpdateBlock?(soundlevels,roomID)
        }
        let speakers = judgeWhoIsSpeaking(speakers: soundlevels)
        delegate?.audioSpeakers(speakersId: speakers)
        
        if myPosition > 0 {
            return
        }
        
        if _myPosition  == 0, liveObject.liveType == .multiVideo {
            var dic = [String: Any]()
            dic["type"] = 1
            dic["soundLevels"] = soundlevels
            if let data = try? JSONSerialization.data(withJSONObject: dic, options: .fragmentsAllowed) {
                msgManager.sendData(data: data, forceMode: .useSEI)
            }
        }
    }
    
    func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String) {
        MemeTracker.trace(event: .zegoLog, status: "onRoomTokenWillExpire", ext: nil, detail: ["roomID":roomID,"remainTimeInSecond":"\(remainTimeInSecond)"])
        guard let roomid = Int(roomID) else { return }
        self.delegate?.livePushTokenExpired()
    }
    
    func onPublisherQualityUpdate(_ quality: ZegoPublishStreamQuality, streamID: String) {
        self.delegate?.onPublisherQualityUpdate(quality, streamID: streamID)
        self.delegate?.onPublisherQualityUpdate(videoSendBytes: quality.videoSendBytes)
    }
    
    func onPublisherStateUpdate(_ state: ZegoPublisherState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        MemeTracker.trace(event: .zegoLog, status: "onPublisherStateUpdate", ext: nil, detail: ["streamID":streamID,"state":"\(state)","errorCode":"\(errorCode)"])
        if state == .publishing  {
            //log.verbose("zego onPublisherStateUpdate publishing")
            streamFinishedList[streamID] = true
        }else {
            //log.verbose("zego onPublisherStateUpdate not publishing")
            streamFinishedList.removeValue(forKey: streamID)
        }
        startMixerTask()
    }
    
    func onPlayerStateUpdate(_ state: ZegoPlayerState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        MemeTracker.trace(event: .zegoLog, status: "onPlayerStateUpdate", ext: nil, detail: ["streamID":streamID,"state":"\(state)","errorCode":"\(errorCode)"])
        if state == .playing  {
            streamFinishedList[streamID] = true
        }else {
            streamFinishedList.removeValue(forKey: streamID)
        }
        startMixerTask()
    }
    
    func onPlayerRenderVideoFirstFrame(_ streamID: String) {
        if let userId = getUserId(streamId: streamID) {
            delegate?.onPlayerRenderVideoFirstFrame(userId)
        }
    }
    
    func onAudioRouteChange(_ audioRoute: ZegoAudioRoute) {
        var memeRoute:MeMeAudioOutputRouting = .normal
        switch audioRoute {
        case .speaker:
            memeRoute = .speakerphone
        case .headphone:
            memeRoute = .normal
        default:
            memeRoute = .other
        }
        self.delegate?.didAudioRouteChanged(routing: memeRoute)
    }
    
    func audioEffectPlayer(_ audioEffectPlayer: ZegoAudioEffectPlayer, audioEffectID: UInt32, playStateUpdate state: ZegoAudioEffectPlayState, errorCode: Int32) {
        if self.audioMixedID == audioEffectID,let mixStateChangedBlock = self.mixStateChangedBlock {
            var code:LivePushAudioMixingStateCode?
            switch state {
            case .noPlay:
                break
            case .playing:
                code = .playing
                isPausedMix = false
            case .playEnded:
                code = .stopped
                isPausedMix = nil
                self.mixStateChangedBlock = nil
            case .pausing:
                code = .paused
            @unknown default:
                break
            }
            if let code = code {
                mixStateChangedBlock(code)
            }
        }
    }
    
    func onPlayerRecvSEI(_ data: Data, streamID: String) {
        msgManager.dealData(data: data, streamID: streamID)
    }
}

extension ZegoManager: ZegoCustomVideoCaptureHandler {
    func onStart(_ channel: ZegoPublishChannel) {
        isStarted = true
    }
    
    func onStop(_ channel: ZegoPublishChannel) {
        isStarted = false
    }
    
    func onEncodedDataTrafficControl(_ trafficControlInfo: ZegoTrafficControlInfo, channel: ZegoPublishChannel) {
        
    }
    
    func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        let isOpen = state == .open
        cameraStates[streamID] = isOpen
        startMixerTask(force:true)
        let userId:Int = getUserId(streamId: streamID) ?? 0
        self.delegate?.didVideoMuted(mute: !isOpen, uid: UInt(userId))
    }
}

// MARK: - Mixer Task
extension ZegoManager {
    private func splitedPushUrl(_ pushUrl: String) {
        let splitedArray = pushUrl.components(separatedBy: "&")
        
        guard splitedArray.count > 0  else {
            transcodingLayoutWidth = TranscodingWindowWidthDefault
            transcodingLayoutHeight = TranscodingWindowHeightDefault
            return
        }
        
        for item in splitedArray {
            if item.contains(TranscodingWindowWidthStr) {
                let width = Int(item.mySubString(from: TranscodingWindowWidthStr.count)) ?? Int(TranscodingWindowWidthDefault)
                transcodingLayoutWidth = CGFloat.init(width)
            }
            
            if item.contains(TranscodingWindowHeightStr)  {
                let height = Int(item.mySubString(from: TranscodingWindowHeightStr.count)) ?? Int(TranscodingWindowWidthDefault)
                transcodingLayoutHeight = CGFloat.init(height)
            }
        }
    }
    
    func startMixerTask(force:Bool = false) {
        guard let publishCdnurl = publishCdnurl else { return }
        guard liveObject.isAnchor == true else {return}
        guard force == true || streamFinishedList != streamMixedList else {return}
        splitedPushUrl(publishCdnurl)
//        if let mixerTask = mixerTask {
//            ZegoExpressEngine.shared().stop(mixerTask) { [weak self] errorCode in
//                if errorCode == 0 {
//                    self?.streamMixedList.removeAll()
//                    self?.mixerTask = nil
//                    self?.startMixerTask()
//                }
//            }
//            return
//        }
        
        if liveObject.liveType == .multiVideo {
            configMultiVideoMixerTask()
        }else if liveObject.liveType == .PK || liveObject.liveType == .newPK {
            configVideoPkMixerTask()
        }else if liveObject.liveType == .connectlive {
            configVideoConnectliveMixerTask()
        }else if liveObject.liveType == .Video {
            configVideoMixerTask()
        }else if liveObject.liveType == .Radio {
            configRadioMixerTask()
        }else if liveObject.liveType == .VoiceCall || liveObject.liveType == .VideoCall {
            //不推流
        }else if liveObject.liveType == .Voice {
            configVoiceMixerTask()
        }
        
        if let task = mixerTask {
            //log.verbose("zego mixerTask start")
            MemeTracker.trace(event: .zegoLog, status: "startmix", ext: nil, detail: nil)
            ZegoExpressEngine.shared().start(task) { errorCode, extendeData in
                
            }
        }
        streamMixedList = streamFinishedList
    }
    
    //多人视频混流
    func configMultiVideoMixerTask() {
        guard let publishCdnurl = publishCdnurl else { return }
        if mixerTask == nil {
            let taskID = roomID
            let task = ZegoMixerTask(taskID: taskID)
            let videoConfig = ZegoMixerVideoConfig(resolution: previewBGView.size, fps: 15, bitrate: 500)
            task.setVideoConfig(videoConfig)
            let audioConfig = ZegoMixerAudioConfig.default()
            audioConfig.bitrate = 44
            audioConfig.codecID = .normal2
            task.setAudioConfig(audioConfig)
            
            let output = ZegoMixerOutput(target: publishCdnurl)
            task.setOutputList([output])
            switch number {
            case 9:
                task.setBackgroundImageURL(self.isProductMode == false ? "preset-id://2898695260_live_9.png" : "preset-id://2898695260_live_9.png")
            case 6:
                task.setBackgroundImageURL(self.isProductMode == false ? "preset-id://2898695260_live_6.png" : "preset-id://2898695260_live_6.png")
            case 4:
                task.setBackgroundImageURL(self.isProductMode == false ? "preset-id://2898695260_live_4.png" : "preset-id://2898695260_live_4.png")
            default: break
            }
            
            mixerTask = task
        }
        var inputArray = [ZegoMixerInput]()
        for (i,playerId) in allPlayerIDList.enumerated() {
            if let playerId = playerId, streamFinishedList.keys.contains(playerId) == true,let playerView = getPreviewView(withPosition: i)  {
                let video = cameraStates[playerId] == true
                let rect: CGRect
                if video {
                    rect = playerView.frame
                } else {
                    rect = CGRect(x: 0, y: 0, width: 0, height: 0)
                }
                let input = ZegoMixerInput(streamID: playerId, contentType: .video, layout: rect)
                MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"MultiVideo","i":"\(i)"])
                inputArray.append(input)
            }
        }
        mixerTask?.setInputList(inputArray)
    }
    
    //pk
    func configVideoPkMixerTask() {
        guard let publishCdnurl = publishCdnurl else { return }
        if mixerTask == nil {
            let taskID = liveObject.streamId > 0 ? "\(liveObject.streamId)" : roomID
            let task = ZegoMixerTask(taskID: taskID)
            let size = CGSize(width: transcodingLayoutWidth,
                              height: transcodingLayoutHeight)
            let videoConfig = ZegoMixerVideoConfig(resolution: size, fps: 15, bitrate: 500)
            task.setVideoConfig(videoConfig)
            let audioConfig = ZegoMixerAudioConfig.default()
            audioConfig.bitrate = 44
            audioConfig.codecID = .normal2
            task.setAudioConfig(audioConfig)
            
            
            let output = ZegoMixerOutput(target: publishCdnurl)
            task.setOutputList([output])
            if self.isProductMode == true {
                task.setBackgroundImageURL(TranscodingBackgroundImageUrl)
            }else{
                task.setBackgroundImageURL(TranscodingBackgroundImageUrl_test)
            }
            
            mixerTask = task
        }
        
        // PK窗口布局参数
        let windowWidth: CGFloat = 180 * transcodingLayoutWidth / 360
        var windowSpaceTop: CGFloat = 130.0 * transcodingLayoutHeight / 640
        if liveObject.liveType == .newPK {
            windowSpaceTop = 100.0 * transcodingLayoutHeight / 640
        }
        let windowSpaceRight: CGFloat = windowWidth
        let windowHeight: CGFloat = windowWidth * 4 / 3
        
        var inputArray = [ZegoMixerInput]()
        for (i,playerId) in allPlayerIDList.enumerated() {
            if let playerId = playerId, streamFinishedList.keys.contains(playerId) == true {
                let rect: CGRect = CGRect(x: i == 0 ? 0.0 : windowSpaceRight, y: windowSpaceTop, width: windowWidth, height: windowHeight)
                let input = ZegoMixerInput(streamID: playerId, contentType: .video, layout: rect)
                MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"pk","i":"\(i)"])
                inputArray.append(input)
                //log.verbose("zego info mix,pos=\(i)")
            }
        }
        mixerTask?.setInputList(inputArray)
    }
    
    func configVideoConnectliveMixerTask() {
        guard liveObject.isAnchor == true else {return}
        guard let publishCdnurl = publishCdnurl else { return }
        let pushSize = CGSize.init(width: transcodingLayoutWidth, height: transcodingLayoutHeight)
        if mixerTask == nil {
            let taskID = liveObject.streamId > 0 ? "\(liveObject.streamId)" : roomID
            let task = ZegoMixerTask(taskID: taskID)
            let size = CGSize(width: pushSize.width,
                              height: pushSize.height)
            let videoConfig = ZegoMixerVideoConfig(resolution: size, fps: 15, bitrate: 500)
            //log.verbose("zego mix,publishCdnurl=\(publishCdnurl),taskID=\(taskID),size=\(size),fps=15,bitrate=1000")
            task.setVideoConfig(videoConfig)
            let audioConfig = ZegoMixerAudioConfig.default()
            audioConfig.bitrate = 44
            audioConfig.codecID = .normal2
            task.setAudioConfig(audioConfig)
            
            
            let output = ZegoMixerOutput(target: publishCdnurl)
            task.setOutputList([output])
            
            mixerTask = task
        }
        
        var inputArray = [ZegoMixerInput]()
        for (i,playerId) in allPlayerIDList.enumerated() {
            if let playerId = playerId, streamFinishedList.keys.contains(playerId) == true {
                if i == 0 {
                    let rect: CGRect = CGRect(x:0, y:0, width:pushSize.width, height:pushSize.height)
                    let input = ZegoMixerInput(streamID: playerId, contentType: .video, layout: rect)
                    MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"connectlive","i":"\(i)"])
                    inputArray.append(input)
                    //log.verbose("zego info mix,pos=\(i)")
                }else{
                    let scaleFactor: CGFloat = pushSize.height/640.0 > pushSize.width / 360.0 ? pushSize.width / 360.0 : pushSize.height / 640.0
                    
                    let height = 164.0 / UIScreen.main.bounds.height * 640.0
                    let width = height * 110.0 / 164.0
                    
                    let window_height:CGFloat = height * scaleFactor
                    let window_width:CGFloat = width * scaleFactor
                    let window_x:CGFloat = pushSize.width - 15 - window_width
                    let window_y:CGFloat = pushSize.height / 2.0 - window_height / 2.0 + 15
                    
                    let rect: CGRect = CGRect(x:window_x, y:window_y, width:window_width, height:window_height)
                    let input = ZegoMixerInput(streamID: playerId, contentType: .video, layout: rect)
                    MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"connectlive","i":"\(i)"])
                    inputArray.append(input)
                    //log.verbose("zego info mix,pos=\(i)")
                }
            }
        }
        mixerTask?.setInputList(inputArray)
    }
    
    //连麦
    func configVideoMixerTask() {
        guard liveObject.isAnchor == true else {return}
        guard let publishCdnurl = publishCdnurl else { return }
        let pushSize = CGSize.init(width: transcodingLayoutWidth, height: transcodingLayoutHeight)
        if mixerTask == nil {
            let taskID = liveObject.streamId > 0 ? "\(liveObject.streamId)" : roomID
            let task = ZegoMixerTask(taskID: taskID)
            let size = CGSize(width: pushSize.width,
                              height: pushSize.height)
            let videoConfig = ZegoMixerVideoConfig(resolution: size, fps: 15, bitrate: 500)
            task.setVideoConfig(videoConfig)
            let audioConfig = ZegoMixerAudioConfig.default()
            audioConfig.bitrate = 44
            audioConfig.codecID = .normal2
            task.setAudioConfig(audioConfig)
            
            
            let output = ZegoMixerOutput(target: publishCdnurl)
            task.setOutputList([output])
            
            mixerTask = task
        }
        
        var inputArray = [ZegoMixerInput]()
        for (i,playerId) in allPlayerIDList.enumerated() {
            if let playerId = playerId, streamFinishedList.keys.contains(playerId) == true {
                if i == 0 {
                    let rect: CGRect = CGRect(x:0, y:0, width:pushSize.width, height:pushSize.height)
                    let input = ZegoMixerInput(streamID: playerId, contentType: .video, layout: rect)
                    MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"video","i":"\(i)"])
                    inputArray.append(input)
                    //log.verbose("zego info mix,pos=\(i)")
                }else{
                    let scaleFactor: CGFloat = pushSize.height/640.0 > pushSize.width / 360.0 ? pushSize.width / 360.0 : pushSize.height / 640.0
                    
                    let height = 164.0 / UIScreen.main.bounds.height * 640.0
                    let width = height * 110.0 / 164.0
                    
                    let window_height:CGFloat = height * scaleFactor
                    let window_width:CGFloat = width * scaleFactor
                    let window_x:CGFloat = pushSize.width - 15 - window_width
                    var window_y:CGFloat = pushSize.height / 2.0 - window_height / 2.0 + 15
                    
                    if i == 2 {
                        window_y = window_y - window_height
                    }
                    
                    let rect: CGRect = CGRect(x:window_x, y:window_y, width:window_width, height:window_height)
                    
                    let input = ZegoMixerInput(streamID: playerId, contentType: .video, layout: rect)
                    MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"video","i":"\(i)"])
                    inputArray.append(input)
                    //log.verbose("zego info mix,pos=\(i)")
                }
            }
        }
        mixerTask?.setInputList(inputArray)
    }
    
    //电台
    func configRadioMixerTask() {
        guard liveObject.isAnchor == true else {return}
        guard let publishCdnurl = publishCdnurl else { return }
        if mixerTask == nil {
            let taskID = liveObject.streamId > 0 ? "\(liveObject.streamId)" : roomID
            let task = ZegoMixerTask(taskID: taskID)
            task.setAudioConfig(ZegoMixerAudioConfig.default())
            
            
            let output = ZegoMixerOutput(target: publishCdnurl)
            task.setOutputList([output])
            
            mixerTask = task
        }
        
        var inputArray = [ZegoMixerInput]()
        for (i,playerId) in allPlayerIDList.enumerated() {
            if let playerId = playerId {
                if i == 0 {
                    let rect: CGRect = CGRect()
                    let input = ZegoMixerInput(streamID: playerId, contentType: .audio, layout: rect)
                    MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"radio","i":"\(i)"])
                    inputArray.append(input)
                    //log.verbose("zego info mix,pos=\(i)")
                }else{
                    let rect: CGRect = CGRect()
                    let input = ZegoMixerInput(streamID: playerId, contentType: .audio, layout: rect)
                    MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"radio","i":"\(i)"])
                    inputArray.append(input)
                    //log.verbose("zego info mix,pos=\(i)")
                }
            }
        }
        mixerTask?.setInputList(inputArray)
    }
    
    //多人语言派对房
    func configVoiceMixerTask() {
        guard liveObject.isAnchor == true else {return}
        guard let publishCdnurl = publishCdnurl else { return }
        if mixerTask == nil {
            let taskID = liveObject.streamId > 0 ? "\(liveObject.streamId)" : roomID
            let task = ZegoMixerTask(taskID: taskID)
            task.setAudioConfig(ZegoMixerAudioConfig.default())
            
            
            let output = ZegoMixerOutput(target: publishCdnurl)
            task.setOutputList([output])
            
            mixerTask = task
        }
        
        var inputArray = [ZegoMixerInput]()
        for (i,playerId) in allPlayerIDList.enumerated() {
            if let playerId = playerId {
                if i == 0 {
                    let rect: CGRect = CGRect()
                    let input = ZegoMixerInput(streamID: playerId, contentType: .audio, layout: rect)
                    MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"voice","i":"\(i)"])
                    inputArray.append(input)
                    //log.verbose("zego info mix,pos=\(i)")
                }else{
                    let rect: CGRect = CGRect()
                    let input = ZegoMixerInput(streamID: playerId, contentType: .audio, layout: rect)
                    MemeTracker.trace(event: .zegoLog, status: "preparemix", ext: nil, detail: ["playerId":playerId,"room":"voice","i":"\(i)"])
                    inputArray.append(input)
                    //log.verbose("zego info mix,pos=\(i)")
                }
            }
        }
        mixerTask?.setInputList(inputArray)
    }
}

#endif
