//
//  LiveAgoraPusher.swift
//  MeMe
//
//  Created by fabo on 2022/1/13.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation

import Foundation
import Cartography
import MeMeKit
import AgoraRtcKit

class LiveAgoraPusher : NSObject, MeMeLivePusher {
    var logViewBlock:(()->UIView?)? {
        didSet {
            agoraManager?.logViewBlock = logViewBlock
        }
    }
    
    deinit {
        self.agoraManager?.agoraVoiceDelegate = nil
        self.agoraManager?.delegates.removeObject(self)
    }
    required init(_ object: MeMeLivePushObject,devMode:Bool,appId:String) {
        self.initalObject = object
        super.init()
        let liveObject = AgoraLiveObject()
        liveObject.liveType = object.liveType
        liveObject.anchorUid = object.anchorUid
        liveObject.currentUid = object.currentUid
        liveObject.isAnchor = object.isAnchor
        liveObject.preview = object.preview
        liveObject.views = object.views
        liveObject.uids = object.uids
        liveObject.myPosition = object.myPos
        
        
        let agoraManager = AgoraLiveManager.init(liveObject: liveObject,devMode:devMode,appId: appId)
        agoraManager.delegates.addObject(self)
        agoraManager.agoraVoiceDelegate = self
        agoraManager.restartedBlock = { [weak self] newManager in
            self?.agoraManager = newManager
        }
        agoraManager.didConnectedFailedBlock = { [weak self] in
            return self?.liveDelegate?.livePushConnectedFailed() ?? false
        }
        self.agoraManager = agoraManager
    }
    
    func setChannelRole(role: LivePushClientRole) {
        MMAudioPermissionManager.setAllowHaptics(key: "push", role == .broadcaster ? true : true)
        switch role {
        case .broadcaster:
            agoraManager?.setChannelRole(role: .broadcaster)
        case .audience:
            agoraManager?.setChannelRole(role: .audience)
        }
    }
    
    func switchCamera() -> Int {
        return agoraManager?.switchCamera() ?? 0
    }
    
    func muteLocalVideoStream(muted: Bool) -> Int {
        return agoraManager?.muteLocalVideoStream(muted: muted) ?? 0
    }
    
    func muteLocalVideo(muted: Bool) {
        localVideoMuted = muted
        agoraManager?.muteLocalVideoStream(muted: muted)
    }
    
    func getLocalVideoMuted() -> Bool {
        return localVideoMuted
    }
    
    func enableSpeakerphone(enableSpeaker: Bool) -> Int {
        return agoraManager?.enableSpeakerphone(enableSpeaker: enableSpeaker) ?? 0
    }
    
    func playEffectSound(filePath: String) -> Int {
        return agoraManager?.playEffectSound(filePath: filePath) ?? 0
    }
    
    func playEffectSound(filePath: String, publish: Bool, effectID: Int) {
        agoraManager?.playEffectSound(filePath: filePath, publish: publish, effectID: Int32(effectID))
    }
    
    func muteOwnAudio(muted: Bool) -> Int {
        return agoraManager?.muteOwnAudio(muted: muted) ?? 0
    }
    
    func muteOtherUsersAudio(muted: Bool) -> Int {
        return agoraManager?.muteOtherUsersAudio(muted: muted) ?? 0
    }
    
    func muteOneUserAudio(uid: UInt, muted: Bool) -> Int {
        return agoraManager?.muteOneUserAudio(uid: uid, muted: muted) ?? 0
    }
    
    func muteAudio(userId:Int?,muted:Bool) -> Int {
        if userId == -1 {
            return muteOwnAudio(muted: muted)
        }else if userId == 0 {
            return muteOtherUsersAudio(muted: muted)
        }else if let userId = userId, userId > 0 {
            if userId != initalObject.currentUid {
                return muteOneUserAudio(uid: (UInt)(userId), muted: muted)
            }else{
                return muteOwnAudio(muted: muted)
            }
        }
        return 0
    }
    
    func adjustRecordingSignalVolume(volume: Int) {
        agoraManager?.adjustRecordingSignalVolume(volume: volume)
    }
    
    func getRecordingSignalVolume() -> Int {
        return agoraManager?.getRecordingSignalVolume() ?? 0
    }
    
    func setVoicePitch(_ pitch: Double) -> Int {
        return agoraManager?.setVoicePitch(pitch) ?? 0
    }
    
    func setMusicPitch(_ pitch: Int) -> Int {
        return agoraManager?.setMusicPitch(pitch) ?? 0
    }
    
    func setAudioEffectPreset(present: MeMeAudioEffectPreset) {
        agoraManager?.setAudioEffectPreset(present: present)
    }
    
    func getAudioEffectPreset() -> MeMeAudioEffectPreset {
        return agoraManager?.getAudioEffectPreset() ?? .source
    }
    
    func enableInEarMonitoring(enable: Bool) -> Int {
        return agoraManager?.enableInEarMonitoring(enable: enable) ?? 0
    }
    
    func startAudioMixing(filePath: String, stageChanged: ((LivePushAudioMixingStateCode) -> ())?) -> Int {
        return agoraManager?.startAudioMixing(filePath: filePath, stageChanged: { code in
            switch code {
            case .failed:
                stageChanged?(.failed)
            case .paused:
                stageChanged?(.paused)
            case .playing:
                stageChanged?(.playing)
            case .stopped:
                stageChanged?(.stopped)
            }
        }) ?? 0
    }
    
    func setAudioMixPosition(pos: Int) {
        agoraManager?.setAudioMixPosition(pos: pos)
    }
    
    func getAudioMixPosition() -> Int? {
        return agoraManager?.getAudioMixPosition()
    }
    
    func adjustAudioMixingVolume(volume: Int) {
        agoraManager?.adjustAudioMixingVolume(volume: volume)
    }
    
    func getAudioMixingVolum() -> Int {
        return agoraManager?.getAudioMixingVolum() ?? 0
    }
    
    func pauseAudioMixing(isPause: Bool) {
        agoraManager?.pauseAudioMixing(isPause: isPause)
    }
    
    func getPauseAudioMixing() -> Bool? {
        return agoraManager?.getPauseAudioMixing()
    }
    
    func stopAudioMixing() {
        agoraManager?.stopAudioMixing()
    }
    
    func stopPlayEffectSound(effectID: Int) {
        agoraManager?.stopPlayEffectSound(effectID: Int32(effectID))
    }
    
    func setPKWindowHidden(hidden: Bool) {
        agoraManager?.setPKWindowHidden(hidden: hidden)
    }
    
    func resetCanvasFrame(rect: CGRect, uid: UInt) {
        agoraManager?.resetCanvasFrame(rect: rect, uid: uid)
    }
    
    func joinChannel(token: String?, channelId: String) {
        agoraManager?.joinChannel(token: token, channelId: channelId)
    }
    
    func leaveChannel() {
        agoraManager?.leaveChannel()
    }
    
    func resetCanvas(uids: [UInt?]) {
        if liveRoomType == .multiVideo {
            agoraManager?.resetMultiVideoCanvas(uids: uids)
        }else{
            let newUids:[UInt] = uids.flatMap({return $0})
            self.resetCanvas(uids: newUids)
        }
    }
    
    func resetCanvas(uids: [UInt]) {
        switch liveRoomType {
        case .Radio:
            break
        case .Voice:
            break
        case .Video:
            agoraManager?.resetVideoCanvas(uids: uids)
        case .PK,.newPK:
            agoraManager?.resetPKCanvas(uids: uids)
        case .VideoCall:
            agoraManager?.resetVideoCallCanvas(oppositeId: uids.first ?? 0)
        case .VoiceCall:
            break
        case .connectlive:
            agoraManager?.resetConnectLiveCanvas(uids: uids)
        case .multiVideo:
            agoraManager?.resetMultiVideoCanvas(uids: uids)
        }
    }
    
    func pushStreamingToCDN(pushUrl: String) {
        agoraManager?.pushStreamingToCDNByAnchor(pushUrl: pushUrl)
    }
    
    func syncCapture(sampleBuffer: CMSampleBuffer?) {
        agoraManager?.syncCapture(sampleBuffer: sampleBuffer)
    }
    
    func renewToken(token: String) {
        agoraManager?.renewAgoraToken(token: token)
    }
    
    func destroyEngine() {
        agoraManager?.destroyAgoraEngine()
    }
    
    func sendData(type:SendDataType,params:[String:Any]) {
        agoraManager?.sendData(type: type, params: params)
    }
    //MARK:<>外部变量
    //MARK:<>外部block
    
    
    //MARK:<>生命周期开始

    //MARK:<>功能性方法
    
    //MARK:<>内部View
    
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    fileprivate var initalObject:MeMeLivePushObject
    var liveRoomType:LivePushRoomType {
        return initalObject.liveType
    }
    var myPosition:Int {
        return agoraManager?.myPosition ?? -1
    }
    fileprivate var agoraManager:AgoraLiveManager?
    
    fileprivate var localVideoMuted = false
    
    //MARK:<>内部block
    
}

extension LiveAgoraPusher : AgoraMultiObserverDelegate, AgoraLiveManagerDelegate {
    func agoraDataDidFetched(type:SendDataType,uid:Int,data:[String:Any]?) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.livePushDataDidFetched(type: type, uid: uid, data: data)
        }
    }
    
    // 我加入channel频道成功。
    func iJoinedChannel(channel: String) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.iJoinedChannel(channel: channel)
        }
    }
    // 我退出channel频道成功。
    func iLeavedChannel() {
        self.liveDelegates.excuteObject { delegate in
            delegate?.iLeavedChannel()
        }
    }
    
    // uid 加入当前所在频道
    func didJoinedOfUid(uid: UInt) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.didJoinedOfUid(uid: uid)
        }
    }
    // uid 离开当前所在频道
    func didOfflineOfUid(uid: UInt, reason: AgoraUserOfflineReason) {
        switch reason {
        case .dropped:
            self.liveDelegates.excuteObject { delegate in
                delegate?.didOfflineOfUid(uid: uid,reason:.dropped)
            }
        case .quit:
            self.liveDelegates.excuteObject { delegate in
                delegate?.didOfflineOfUid(uid: uid,reason:.quit)
            }
        case .becomeAudience:
            self.liveDelegates.excuteObject { delegate in
                delegate?.didOfflineOfUid(uid: uid,reason:.exchange)
            }
        default:
            self.liveDelegates.excuteObject { delegate in
                delegate?.didOfflineOfUid(uid: uid,reason:.other)
            }
        }
        
    }
    // uid 该用户关闭了自己的摄像头
    func didVideoMuted(mute: Bool, uid: UInt) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.didVideoMuted(mute: mute, uid: uid)
        }
    }
    // 音频的路由发生了改变
    func didAudioRouteChanged(routing: AgoraAudioOutputRouting) {
        switch routing {
        case .default:
            self.liveDelegates.excuteObject { delegate in
                delegate?.didAudioRouteChanged(routing: .normal)
            }
        case .speakerphone:
            self.liveDelegates.excuteObject { delegate in
                delegate?.didAudioRouteChanged(routing: .speakerphone)
            }
        case .loudspeaker:
            self.liveDelegates.excuteObject { delegate in
                delegate?.didAudioRouteChanged(routing: .loudspeaker)
            }
        default:
            self.liveDelegates.excuteObject { delegate in
                delegate?.didAudioRouteChanged(routing: .other)
            }
        }
        
    }
    // uids 当前发言用的
    func audioSpeakers(speakersId:[UInt]) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.audioSpeakers(speakersId: speakersId)
        }
    }
    
    // Token过期了
    func agoraTokenExpired() {
        self.liveDelegates.excuteObject { delegate in
            delegate?.livePushTokenExpired()
        }
    }
    // 当前发言人及他的说话声响以及最大的响度
    func auidoSpeakersAndVolume(speakers: [MeMeAudioVolumeInfo], totalVolume: Int) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.auidoSpeakersAndVolume(speakers: speakers, totalVolume: totalVolume)
        }
    }
    // 当前频道整体质量（2秒回调一次）
    func reportAgoraStats(stats: AgoraChannelStats, formatStr: String?) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.livePushReportPushStats(stats)
        }
    }
    
    // 主播PK，PK匹配成功，添加PK者的视图
    func addPKUserWindow(view: UIView) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.addPKUserWindow(view: view)
        }
    }
    // 主播PK，PK一次结束，移除PK者的视图
    func removePKUserWindow(view: UIView) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.removePKUserWindow(view: view)
        }
    }
    
    func firstRemoteVideoFrameOfUid(uid:Int) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.firstRemoteVideoFrameOfUid(uid: uid)
        }
    }

}
