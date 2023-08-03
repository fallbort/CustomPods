//
//  LiveZegoPusher.swift
//  MeMe
//
//  Created by fabo on 2022/1/13.
//  Copyright © 2022 sip. All rights reserved.
//

#if ZegoImported

import Foundation

import Foundation
import Cartography
import MeMeKit
import UIKit
import ZegoExpressEngine

class LiveZegoPusher : NSObject, MeMeLivePusher {
    var logViewBlock:(()->UIView?)? {
        didSet {
            zegoManager?.logViewBlock = logViewBlock
        }
    }
    
    deinit {
        
    }
    required init(_ object: MeMeLivePushObject,devMode:Bool,isProductMode:Bool) {
        if object.liveType == .Voice {
            var newObject = object
            newObject.seatNum = 20  //席位数暂定20个，只要比实际需要用到的多就行
            self.initalObject = newObject
        }else{
            self.initalObject = object
        }
        super.init()
        zegoManager = ZegoManager(liveObject: object,devMode:devMode,isProductMode:isProductMode)
        zegoManager?.delegate = self
        zegoManager?.loginRoomFailure = { [weak self] in
            self?.liveDelegate?.livePushConnectedFailed()
        }
        zegoManager?.soundLevelUpdateBlock = { [weak self] (speakers,channelId) in
            var volumeInfos:[MeMeAudioVolumeInfo] = []
            var maxVolume:Int = 0
            for (uid,volume) in speakers {
                let volumeInfo = MeMeAudioVolumeInfo()
                let uidInt = (uid as NSString).integerValue
                let volumeInt = (volume as NSString).integerValue
                volumeInfo.uid = uidInt
                volumeInfo.volume = volumeInt
                volumeInfo.channelId = channelId
                volumeInfos.append(volumeInfo)
                maxVolume = max(maxVolume,volumeInt)
            }
            self?.liveDelegates.excuteObject({ delegate in
                delegate?.auidoSpeakersAndVolume(speakers: volumeInfos, totalVolume: maxVolume)
            })
        }
    }
    
    func setChannelRole(role: LivePushClientRole) {
        zegoManager?.setChannelRole(role: role)
        MMPermissionManager.setAllowHaptics(key: "push", role == .broadcaster ? true : true)
    }
    
    func switchCamera() -> Int {
        zegoManager?.exchangeCameraFrontOrBack()
        return 1
    }
    
    func muteLocalVideoStream(muted: Bool) -> Int {
        zegoManager?.videoMuteUser(muted)
        self.muteLocalVideo(muted: muted)
        return 0
    }
    
    func muteLocalVideo(muted: Bool) {
        localVideoMuted = muted
        zegoManager?.isEnableCamera = !muted
    }
    
    func getLocalVideoMuted() -> Bool {
        return localVideoMuted
    }
    
    func enableSpeakerphone(enableSpeaker: Bool) -> Int {
        return zegoManager?.enableSpeakerphone(enableSpeaker: enableSpeaker) ?? 0
    }
    
    func playEffectSound(filePath: String) -> Int {
        zegoManager?.playEffectSound(filePath: filePath)
        return 1
    }
    
    func playEffectSound(filePath: String, publish: Bool, effectID: Int) {
        zegoManager?.playEffectSound(filePath: filePath, isPublishOut: publish, effectID: UInt32(effectID))
    }
    
    func muteAudio(userId:Int?,muted:Bool) -> Int {
        if userId == -1 {
            zegoManager?.muteOwnAudio(muted: muted)
            return 1
        }else if userId == 0 {
            zegoManager?.muteOtherUsersAudio(muted: muted)
            return 1
        }else if let userId = userId, userId > 0 {
            if userId != initalObject.currentUid {
                zegoManager?.muteOneUserAudio(uid: (userId), muted: muted)
                return 1
            }else{
                zegoManager?.muteOwnAudio(muted: muted)
                return 1
            }
        }
        return 0
    }
    
    func adjustRecordingSignalVolume(volume: Int) {
        zegoManager?.setCaptureVolume(volume: volume)
    }
    
    func getRecordingSignalVolume() -> Int {
        return zegoManager?.getCaptureVolume() ?? 0
    }
    
    func setVoicePitch(_ pitch: Double) -> Int {
        return 0
    }
    //返回值0为成功
    func setMusicPitch(_ pitch: Int) -> Int {
        if let ret = zegoManager?.setMusicPitch(pitch) {
            return ret == 1 ? 0 : 1
        }
        return 1
    }
    
    func setAudioEffectPreset(present: MeMeAudioEffectPreset) {
        zegoManager?.setAudioEffectPreset(present: present)
    }
    
    func getAudioEffectPreset() -> MeMeAudioEffectPreset {
        return zegoManager?.getAudioEffectPreset() ?? .source
    }
    
    func enableInEarMonitoring(enable: Bool) -> Int {
        return zegoManager?.enableInEarMonitoring(enable: enable) ?? 1
    }
    
    func startAudioMixing(filePath: String, stageChanged: ((LivePushAudioMixingStateCode) -> ())?) -> Int {
        return zegoManager?.startAudioMixing(filePath: filePath, audioEffectID: audioEffectID, stageChanged: stageChanged) ?? 0
    }
    
    func setAudioMixPosition(pos: Int) {
        zegoManager?.setAudioMixPosition(pos: pos, audioEffectID: audioEffectID)
    }
    
    func getAudioMixPosition() -> Int? {
        return zegoManager?.getAudioMixPosition(audioEffectID: audioEffectID) ?? 0
    }
    
    func adjustAudioMixingVolume(volume: Int) {
        zegoManager?.adjustAudioMixingVolume(volume: volume, audioEffectID: audioEffectID)
    }
    
    func getAudioMixingVolum() -> Int {
        return zegoManager?.getAudioMixingVolum(audioEffectID: audioEffectID) ?? 50
    }
    
    func pauseAudioMixing(isPause: Bool) {
        zegoManager?.pauseAudioMixing(isPause: isPause, audioEffectID: audioEffectID)
    }
    
    func getPauseAudioMixing() -> Bool? {
        return zegoManager?.getPauseAudioMixing(audioEffectID: audioEffectID)
    }
    
    func stopAudioMixing() {
        zegoManager?.stopAudioMixing(audioEffectID: audioEffectID)
    }
    
    func stopPlayEffectSound(effectID: Int) {
        zegoManager?.stopPlayEffectSound(effectID: UInt32(effectID))
    }
    
    func setPKWindowHidden(hidden: Bool) {
        zegoManager?.setPKWindowHidden(hidden: hidden)
    }
    
    func resetCanvasFrame(rect: CGRect, uid: UInt) {
        zegoManager?.resetCanvasFrame(rect: rect, uid: uid)
    }
    
    func joinChannel(token: String?, channelId: String) {
        zegoManager?.loginRoom(roomID: channelId, token: token)
    }
    
    func leaveChannel() {
        zegoManager?.leaveChannel()
    }
    
    func resetCanvas(uids: [UInt]) {
        let newUids:[UInt?] = uids.map({return $0})
        self.resetCanvas(uids: newUids)
    }
    
    func resetCanvas(uids: [UInt?]) {
        zegoManager?.resetCanvas(uids: uids)
    }
    
    func pushStreamingToCDN(pushUrl: String) {
        zegoManager?.publishCdnurl = pushUrl
    }
    
    func syncCapture(sampleBuffer: CMSampleBuffer?) {
        zegoManager?.syncCapture(sampleBuffer: sampleBuffer)
    }
    
    func renewToken(token: String) {
        zegoManager?.renewToken(token: token)
    }
    
    func destroyEngine() {
        zegoManager?.destroyEngine()
    }
    
    func sendData(type:SendDataType,params:[String:Any]) {
        zegoManager?.sendData(type: type, params: params)
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
        return zegoManager?.myPosition ?? -1
    }
    
    fileprivate var zegoManager: ZegoManager?
    
    fileprivate var localVideoMuted = false
    
    fileprivate var audioEffectID:UInt32 = 99996666
    
    //MARK:<>内部block
    
}

extension LiveZegoPusher : ZegoDelegate {
    func iJoinedChannel(channel: String) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.iJoinedChannel(channel: channel)
        }
    }
    func iLeavedChannel() {
        self.liveDelegates.excuteObject { delegate in
            delegate?.iLeavedChannel()
        }
    }
    
    // uid 加入当前所在频道
    func didJoinedOfUid(uid: UInt) {
        self.liveDelegates.excuteObject {  delegate in
            delegate?.didJoinedOfUid(uid:uid)
        }
    }
    // uid 离开当前所在频道
    func didOfflineOfUid(uid: UInt,reason:LivePushUserOfflineReason?) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.didOfflineOfUid(uid: uid, reason: reason)
        }
    }
    
    // 当前频道整体质量（3s回调一次）
    func onPublisherQualityUpdate(_ quality: ZegoPublishStreamQuality, streamID: String) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.livePushReportPushStats(quality)
        }
    }
    
    func onPlayerQualityUpdate(videoKBPS: Double) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.onPlayerQualityUpdate(videoKBPS: videoKBPS)
        }
    }
    
    func onPublisherQualityUpdate(videoSendBytes: Double) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.onPublisherQualityUpdate(videoSendBytes: videoSendBytes)
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
    
    
    // uid 该用户关闭了自己的摄像头
    func didVideoMuted(mute: Bool, uid: UInt) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.didVideoMuted(mute: mute, uid: uid)
        }
    }
    
    func onPlayerRenderVideoFirstFrame(_ uid: Int) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.firstRemoteVideoFrameOfUid(uid: uid)
        }
    }
    
    func livePushTokenExpired() {
        self.liveDelegates.excuteObject { delegate in
            delegate?.livePushTokenExpired()
        }
    }
    
    func didAudioRouteChanged(routing: MeMeAudioOutputRouting) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.didAudioRouteChanged(routing: routing)
        }
    }
    
    func audioSpeakers(speakersId:[UInt]) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.audioSpeakers(speakersId: speakersId)
        }
    }
    
    func livePushDataDidFetched(type:SendDataType,uid:Int,data:[String:Any]?) {
        self.liveDelegates.excuteObject { delegate in
            delegate?.livePushDataDidFetched(type: type, uid: uid, data: data)
        }
    }
}

#endif
