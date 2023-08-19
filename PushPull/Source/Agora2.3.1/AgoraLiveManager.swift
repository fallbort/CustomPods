//
//  AgoraLiveManager.swift
//  MeMe
//
//  Created by Mingde on 2018/5/9.
//  Copyright © 2018 sip. All rights reserved.
//

import MeMeKit
import AgoraRtcKit
import SwiftyJSON
import CoreGraphics

// 旁路推流，整个画面的宽、高的默认数值。
fileprivate var TranscodingWindowWidthDefault: CGFloat = 360
fileprivate var TranscodingWindowHeightDefault: CGFloat = 640
fileprivate let TranscodingWindowWidthStr = "ikWidth="
fileprivate let TranscodingWindowHeightStr = "ikHeight="
fileprivate let TranscodingBackgroundImageUrl = "https://d9iyrkd8y2zpr.cloudfront.net/webapi-assets-prod/resources/banners/202207/upload.6p8pfwrg037ar7d6.png"

fileprivate let TranscodingBackgroundImageUrl_4 = "https://d9iyrkd8y2zpr.cloudfront.net/webapi-assets-prod/202212/4cf15be1-3b12-4b70-a38e-b3c469928935.png"
fileprivate let TranscodingBackgroundImageUrl_9 = "https://d9iyrkd8y2zpr.cloudfront.net/webapi-assets-prod/202212/8d24dea7-026e-4202-920b-3898738c0889.png"
fileprivate let TranscodingBackgroundImageUrl_6 = "https://d9iyrkd8y2zpr.cloudfront.net/webapi-assets-prod/202212/77388d6a-f204-4366-bfc2-014f3ad28197.png"


// PK窗口布局参数
fileprivate let PKWindowSpaceTop = 130.0 * UIScreen.main.bounds.size.height / 640
fileprivate let PKWindowSpaceTopNew = 100.0 * UIScreen.main.bounds.size.height / 640
fileprivate let PKWindowWidth = UIScreen.main.bounds.size.width / 2
fileprivate let PKWindowSpaceRight = PKWindowWidth
fileprivate let PKWindowHeight = 250 * UIScreen.main.bounds.size.height / 667

extension MeMeAudioEffectPreset {
    var agoraEffectPreset:AgoraAudioEffectPreset {
        get {
            switch self {
            case .source:
                return .audioEffectOff
            case .liuxing:
                return .styleTransformationPopular
            case .rb:
                return .styleTransformationRnB
            case .ktv:
                return .roomAcousticsKTV
            case .luyin:
                return .roomAcousticsStudio
            case .yanchang:
                return .roomAcousticsVocalConcert
            case .liusheng:
                return .roomAcousticsPhonograph
            case .uncle:
                return .voiceChangerEffectUncle
            case .girl:
                return .voiceChangerEffectSister
            case .liti:
                return .roomAcousticsVirtualStereo
            }
        }
    }
    
    static func getMeMeEffect(from agoraValue:AgoraAudioEffectPreset) -> MeMeAudioEffectPreset {
        switch agoraValue {
        case .audioEffectOff:
            return .source
        case .styleTransformationPopular:
            return .liuxing
        case .styleTransformationRnB:
            return .rb
        case .roomAcousticsKTV:
            return .ktv
        case .roomAcousticsStudio:
            return .luyin
        case .roomAcousticsVocalConcert:
            return .yanchang
        case .roomAcousticsPhonograph:
            return .liusheng
        case .voiceChangerEffectUncle:
            return .uncle
        case .voiceChangerEffectSister:
            return .girl
        case .roomAcousticsVirtualStereo:
            return .liti
        default:
            return .source
        }
    }
}

protocol AgoraMultiObserverDelegate {
    func agoraDataDidFetched(type:SendDataType,uid:Int,data:[String:Any]?)
}

extension AgoraMultiObserverDelegate {
    func agoraDataDidFetched(type:SendDataType,uid:Int,data:[String:Any]?) {}
}

@objc protocol AgoraLiveManagerDelegate {
    // 我加入channel频道成功。
    @objc optional func iJoinedChannel(channel: String)
    // 我退出channel频道成功。
    @objc optional func iLeavedChannel()
    
    // uid 加入当前所在频道
    @objc optional func didJoinedOfUid(uid: UInt)
    // uid 离开当前所在频道
    @objc optional func didOfflineOfUid(uid: UInt, reason: AgoraUserOfflineReason)
    // uid 该用户关闭了自己的摄像头
    @objc optional func didVideoMuted(mute: Bool, uid: UInt)
    // 音频的路由发生了改变
    @objc optional func didAudioRouteChanged(routing: AgoraAudioOutputRouting)
    // uids 当前发言用的
    @objc optional func audioSpeakers(speakersId:[UInt])
    
    // Token过期了
    @objc optional func agoraTokenExpired();
    // 当前发言人及他的说话声响以及最大的响度
    @objc optional func auidoSpeakersAndVolume(speakers: [MeMeAudioVolumeInfo], totalVolume: Int)
    // 当前频道整体质量（2秒回调一次）
    @objc optional func reportAgoraStats(stats: AgoraChannelStats, formatStr: String?)
    
    // 主播PK，PK匹配成功，添加PK者的视图
    @objc optional func addPKUserWindow(view: UIView)
    // 主播PK，PK一次结束，移除PK者的视图
    @objc optional func removePKUserWindow(view: UIView)
    
    @objc optional func firstRemoteVideoFrameOfUid(uid:Int)
}

enum AgoraRestartFuncEnum : Int {
    case initM
    case setPKWindowHidden
    case joinChannel
    case playEffectSound
    case startAudioMixing
    case resetVideoCanvas
    case resetMultiVideoCanvas
    case resetConnectLiveCanvas
    case muteOwnAudio
    case agoraVoiceDelegate
    case setChannelRole
    case setRecordingVolume
    case muteLocalVideoStream
    case switchCamera
    case muteOtherUsersAudio
    case renewAgoraToken
    case resetVideoCallCanvas
    case resetCanvasFrame
    case setAudioEffectPreset
    case adjustAudioMixingVolume
    case adjustRecordingSignalVolume
    case pauseAudioMixing
    case stopAudioMixing
    case setAudioMixPosition
    case enableInEarMonitoring
    case setVoicePitch
    case setMusicPitch
}

struct AgoraRestartFuncData {
    var curEnum:AgoraRestartFuncEnum?
    var data:[Any?] = []
}

class AgoraLiveManager: NSObject {
    var logViewBlock:(()->UIView?)?
    
    weak var agoraVoiceDelegate: AgoraLiveManagerDelegate? {
        didSet{
            addRestartFunc(funcEnum: .agoraVoiceDelegate, data: [])
        }
    }
    
    fileprivate var devMode:Bool = false
    fileprivate static var devMode:Bool = false
    fileprivate static var appId:String = ""
    
    fileprivate var restartData:[AgoraRestartFuncData] = []
  
    fileprivate var isRoomOwner = false                         // 是否是房主（主播针对调用调用方而言），从接入层赋值过来。
    fileprivate var isJoinedChannel: Bool = false               // 是否在房间

    var agoraLiveType: LivePushRoomType = .Voice       // 默认是多人语音模式，从接入层赋值过来。
    fileprivate var agoraKit: AgoraRtcEngineKit?                // 声网SDK核心引擎。
    fileprivate var agoraConsumer: AgoraVideoFrameConsumer?     // 裸数据协议对象，声网赋值过来，我们只持有。
    
    // 旁路推流相关，只有房主（主播）配置，只要涉及到CDN转推就需要配置。
    fileprivate var transcoding: AgoraLiveTranscoding?          // 旁路推流所需的配置项。
    fileprivate var transcodingAddedFlag = false                // 确保方法在当前类周期内，只会执行一次。
    fileprivate var transcodingUids: [UInt?]?                    // 用于维护旁路推流的所有User数组（包含主播自己），从接入层赋值过来。
    fileprivate var transcodingPushUrl: String?                 // 旁路推流地址
    fileprivate var transcodingLayoutWidth: CGFloat = TranscodingWindowWidthDefault    // 旁路推流的初始化宽
    fileprivate var transcodingLayoutHeight: CGFloat = TranscodingWindowHeightDefault  // 旁路推流的初始化高
    
    fileprivate var orderUids:[UInt?]? //排序的需要展示的uids
    
    // Video，部分属性可以为空nil，因为在.Voice情况不需要。
    fileprivate var localPreview: UIView?                                   // 本地预览窗口，从接入层赋值过来。
    fileprivate var streamSuperViews: [UIView]?                             // 连麦者窗口，从接入层赋值过来。
    fileprivate var roomOwnerUid: UInt = 0                                  // 房主（主播）Uid，从接入层赋值过来。
    fileprivate var localUid: UInt = 0                                      // 当前登录用户Uid，从接入层赋值过来。
    fileprivate var myUid: Int = 0
    fileprivate var useOutCapture:Bool = false  //使用外部视频源
    
    fileprivate var streamerViewMapping: [UInt: UIView?] = [:]              // 视频连麦，缓存连麦者容器View数组。
    fileprivate var videoCanvasMapping: [UInt: AgoraRtcVideoCanvas] = [:]   // 视频连麦，远端连麦者嘉宾的画布数组。
    
    fileprivate var needRemoveViews:[UIView] = [] //完成后需要删除的view
    fileprivate var updateTokenTimer: CancelableTimeoutBlock?  //刷新token定时器
    fileprivate var isLoginRoomStage = false  //是否在加入房间阶段
    fileprivate var isLoginRoomCalled = false  //是否已调用加入房间
    fileprivate var joinedUids:[Int] = []  //已加入的他人uids
    
    fileprivate var token:String?
    fileprivate var roomId:String = ""
    
    fileprivate var joinCheckDelay: DispatchWorkItem?
    
    fileprivate var personVolume:Int32 = 100
    fileprivate var mixVolume:Int32 = 100
    fileprivate var mixPreset:MeMeAudioEffectPreset = .source
    fileprivate var isPausedMix:Bool?

    var mixStateChangedBlock:((_ state:AgoraAudioMixingStateCode)->())?
    var dataTypeStream:[SendDataType:Int] = [:]
    
    var delegates:WeakReferenceArray = WeakReferenceArray<AgoraMultiObserverDelegate>()
    
    fileprivate var mixVolumeDelayDispatch: DispatchWorkItem?

    fileprivate var curChannelRole:AgoraClientRole?
    fileprivate var mixPositionTimer: GCDTimer? = nil
    fileprivate var mixPositionTimePassed: TimeInterval = 0
    fileprivate var cacheMixPosition: Int?  //ms

    fileprivate var publishRetryTimer:CancelableTimeoutBlock? //推流
    
    fileprivate var isMeMuted = false
    fileprivate var isOthersMuted = false
    fileprivate var isOtherIdsMuted:[UInt] = []
    
    var didConnectedFailedBlock:(()->Bool)?
    
    var _myPosition:Int = 0
    var myPosition:Int {
        if _myPosition == 0 {
            return _myPosition
        }else if let orderedUsers = orderUids {
            if agoraLiveType == .multiVideo {
                return orderedUsers.firstIndex(of: UInt(localUid)) ?? -1
            }else{
                return _myPosition
            }
        }else{
            return _myPosition
        }
    }
    
    init(liveObject: AgoraLiveObject,devMode:Bool,appId:String)
    {
        super.init()
        self.devMode = devMode
        Self.appId = appId
        Self.instanceCount = Self.instanceCount + 1
        addRestartFunc(funcEnum: .initM, data: [liveObject])
        agoraLiveType = liveObject.liveType
        roomOwnerUid = UInt(liveObject.anchorUid)
        localUid = UInt(liveObject.currentUid)
        isRoomOwner = liveObject.isAnchor
        localPreview = liveObject.preview
        streamSuperViews = liveObject.views
        transcodingUids = liveObject.uids
        _myPosition = liveObject.myPosition
        myUid = liveObject.currentUid
        useOutCapture = liveObject.useOutCapture
       
        UIApplication.shared.setMultiValueMixTrue(uniqueKey: "\(self.className)+\(self.getAddress())", keyPath: \UIApplication.isIdleTimerDisabled, value: true)

        initEngine()
    }
    
    deinit {
        // delegate
        UIApplication.shared.setMultiValueMixTrue(uniqueKey: "\(self.className)+\(self.getAddress())", keyPath: \UIApplication.isIdleTimerDisabled, value: false)
        Self.instanceCount = Self.instanceCount - 1
        agoraVoiceDelegate = nil
        joinCheckDelay?.cancel()
        joinCheckDelay = nil
        // 如调用destroy()，SDK将无法触发"didLeaveChannelWithStats"回调。
        if Self.instanceCount <= 0 {
            AgoraRtcEngineKit.destroy()
        }
        clearCacheMixPosition()
        
        if self.devMode == true {
            let oldLabel = self.tipLabel
            main_async {
                oldLabel.removeFromSuperview()
            }
        }
    }
    
    fileprivate func addRestartFunc(funcEnum:AgoraRestartFuncEnum,data:[Any?]) {
        if funcEnum == .renewAgoraToken {
            if let token = data.first as? String {
                if let index = restartData.firstIndex(where: { (data) -> Bool in
                    return data.curEnum == .joinChannel
                }) {
                    var oneData = restartData[index]
                    oneData.data[0] = token
                    restartData[index] = oneData
                }
            }
            
        }else{
            var hasOld = false
            if let index = restartData.firstIndex(where: { (data) -> Bool in
                return data.curEnum == funcEnum
            }) {
                restartData.remove(at: index)
                hasOld = true
            }
            if hasOld == true {
                if funcEnum == .switchCamera {
                    return
                }
            }
            var funcData:AgoraRestartFuncData = AgoraRestartFuncData()
            funcData.curEnum = funcEnum
            funcData.data = data
            restartData.append(funcData)
        }
        
    }
    
    func restartManger() {
        let delegate = agoraVoiceDelegate
        let datas = restartData
        agoraKit?.delegate = nil
         self.destroyAgoraEngine(true)
        var manager:AgoraLiveManager?
        var newDatas:[AgoraRestartFuncData] = []
        var inited = false
        for oneData in datas {
            if inited == false {
                if let newManger = Self.restartDo(oneData, manager: manager, delegate: delegate) {
                    manager = newManger
                }
                if oneData.curEnum == .initM {
                    inited = true
                }
            }else{
                newDatas.append(oneData)
            }
        }
        if let manager = manager {
            restartedBlock?(manager)
            for oneData in datas {
                if oneData.curEnum != .initM {
                    _ = Self.restartDo(oneData, manager: manager, delegate: delegate)
                }
            }
        }
    }
    
    class func restartDo(_ funcData:AgoraRestartFuncData,manager:AgoraLiveManager?,delegate:AgoraLiveManagerDelegate?) -> AgoraLiveManager? {
        if let dataEnum = funcData.curEnum {
            let data = funcData.data
            switch dataEnum {
            case .initM:
                if let data = data.first as? AgoraLiveObject {
                    let manager = AgoraLiveManager.init(liveObject: data,devMode:self.devMode, appId: self.appId)
                    return manager
                }
            case .setPKWindowHidden:
                if let hidden = data.first as? Bool {
                    manager?.setPKWindowHidden(hidden: hidden)
                }
            case .joinChannel:
                let token = data.first as? String
                if let channelId = data.last as? String {
                    manager?.joinChannel(token: token, channelId: channelId)
                }
            case .startAudioMixing:
                if let filePath = data.first as? String {
                    _ = manager?.startAudioMixing(filePath: filePath)
                }
            case .playEffectSound:
                break
            case .setAudioEffectPreset:
                if let present = data.first as? MeMeAudioEffectPreset {
                    _ = manager?.setAudioEffectPreset(present: present)
                }
            case .adjustAudioMixingVolume:
                if let volume = data.first as? Int {
                    _ = manager?.adjustAudioMixingVolume(volume: volume)
                }
            case .adjustRecordingSignalVolume:
                if let volume = data.first as? Int {
                    _ = manager?.adjustRecordingSignalVolume(volume: volume)
                }
            case .pauseAudioMixing:
                if let isPause = data.first as? Bool {
                    _ = manager?.pauseAudioMixing(isPause: isPause)
                }
            case .stopAudioMixing:
                manager?.stopAudioMixing()
            case .setAudioMixPosition:
                if let pos = data.first as? Int {
                    _ = manager?.setAudioMixPosition(pos: pos)
                }
            case .muteOwnAudio:
                if let muted = data.first as? Bool {
                    _ = manager?.muteOwnAudio(muted: muted)
                }
            case .agoraVoiceDelegate:
                manager?.agoraVoiceDelegate = delegate
            case .setChannelRole:
                if let role = data.first as? AgoraClientRole {
                    manager?.setChannelRole(role: role)
                }
            case .setRecordingVolume:
                if let volume = data.first as? Int {
                    manager?.setRecordingVolume(volume: volume)
                }
            case .muteLocalVideoStream:
                if let muted = data.first as? Bool {
                    _ = manager?.muteLocalVideoStream(muted: muted)
                }
            case .switchCamera:
                _ = manager?.switchCamera()
            case .muteOtherUsersAudio:
                if let muted = data.first as? Bool {
                    _ = manager?.muteOtherUsersAudio(muted: muted)
                }
            case .renewAgoraToken:
                break
            case .resetVideoCanvas:
                if let uids = data.first as? [UInt] {
                    manager?.resetVideoCanvas(uids: uids)
                }
            case .resetMultiVideoCanvas:
                if let uids = data.first as? [UInt] {
                    manager?.resetMultiVideoCanvas(uids: uids)
                }
            case .resetConnectLiveCanvas:
                if let uids = data.first as? [UInt] {
                    manager?.resetConnectLiveCanvas(uids: uids)
                }
            case .resetVideoCallCanvas:
                if let oppositeId = data.first as? UInt {
                    manager?.resetVideoCallCanvas(oppositeId: oppositeId)
                }
            case .resetCanvasFrame:
                if let rect = data.first as? CGRect, let uid = data.last as? UInt {
                    manager?.resetCanvasFrame(rect: rect, uid: uid)
                }
            case .enableInEarMonitoring:
                if let enable = data.first as? Bool {
                    manager?.enableInEarMonitoring(enable: enable)
                }
            case .setVoicePitch:
                if let pitch = data.first as? Double {
                    manager?.setVoicePitch(pitch)
                }
            case .setMusicPitch:
                if let pitch = data.first as? Int {
                    manager?.setMusicPitch(pitch)
                }
            }
        }
        return nil
    }
    
    var restartedBlock:((_ manger:AgoraLiveManager)->())?
    
    static var instanceCount = 0
    
    var tipLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.regular)
        view.textColor =  UIColor.hexString(toColor: "#ff0000")!
        view.text = "agora"
        view.sizeToFit()
        return view
    }()
}

//MARK: - 【Public】必须 Init & Destroy
extension AgoraLiveManager {
    
    // 1）初始化引擎
    fileprivate func initEngine() {
        let appId = Self.appId
        let agoraSDK = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
        
        /* 1.直播模式有主播和观众两种用户角色，可以通过调用 setClientRole 设置。主播可收发语音和视频，但观众只能收，不能发。
         * 2.同一频道内只能同时设置一种模式。
         * 3.该方法必须在加入频道前调用和进行设置，进入频道后无法再设置。*/
        agoraSDK.setChannelProfile(.liveBroadcasting)                               // 默认是音频开启了外放。
        if agoraLiveType == .Voice {
            agoraSDK.setAudioProfile(.musicStandardStereo, scenario: .gameStreaming)
        }else if agoraLiveType == .Video {
            agoraSDK.setAudioProfile(.musicStandardStereo, scenario: .gameStreaming)
        }else{
            agoraSDK.setAudioProfile(.musicStandardStereo, scenario: .gameStreaming)
        }
        
        // 连麦 + 语音模式
        if agoraLiveType == .Voice || agoraLiveType == .Radio || agoraLiveType == .VoiceCall {
            agoraSDK.enable(inEarMonitoring: false)                                 // 是否启用耳机监听
            agoraSDK.enableAudioVolumeIndication(500, smooth: 3, report_vad: true)                    // 允许定期向我们反馈"当前谁在说话以及说话者的音量
        }
        
        // .Video视频连麦。房主(主播）
        if (agoraLiveType == .Video || agoraLiveType == .connectlive) && isRoomOwner == true {
            let config = AgoraVideoEncoderConfiguration.init(size:CGSize(width:720, height:1280),
                                                             frameRate: AgoraVideoFrameRate(rawValue: 20) ?? .fps15,
                                                             bitrate: 1000,
                                                             orientationMode: .fixedPortrait)
            agoraSDK.setVideoEncoderConfiguration(config)
            
            agoraSDK.enableVideo()
            agoraSDK.setExternalVideoSource(true, useTexture: true, pushMode: true) //关键代码：启用自采集方案，触发AgoraVideoSourceProtocol的协议回调
            agoraSDK.setParameters("{\"che.video.keep_prerotation\":false}")        // 美颜专用私有方法
            agoraSDK.setParameters("{\"che.video.local.camera_index\":1025}")       // 美颜专用私有方法
            agoraSDK.setParameters("{\"che.video.keyFrameInterval\":1}")            // 视频发送码流中关键帧间隔从2s修改成1s
            agoraSDK.setParameters("{\"lowLatency\":true}")                         // 降低服务端转码推流服务器jitterBuffer

        }
        
        
        //多人视频,房主
        if (agoraLiveType == .multiVideo) {
            if let views = streamSuperViews {
                if views.count == 4 {
                    let config = AgoraVideoEncoderConfiguration.init(size:CGSize(width:270, height:270),
                                                                     frameRate: AgoraVideoFrameRate(rawValue: 20) ?? .fps15,
                                                                     bitrate: 200,
                                                                     orientationMode: .fixedPortrait)
                    agoraSDK.setVideoEncoderConfiguration(config)
                }else if views.count == 6 && isRoomOwner == true {
                    let config = AgoraVideoEncoderConfiguration.init(size:CGSize(width:360, height:360),
                                                                     frameRate: AgoraVideoFrameRate(rawValue: 20) ?? .fps15,
                                                                     bitrate: 400,
                                                                     orientationMode: .fixedPortrait)
                    agoraSDK.setVideoEncoderConfiguration(config)
                }else{
                    let config = AgoraVideoEncoderConfiguration.init(size:CGSize(width:180, height:180),
                                                                     frameRate: AgoraVideoFrameRate(rawValue: 20) ?? .fps15,
                                                                     bitrate: 130,
                                                                     orientationMode: .fixedPortrait)
                    agoraSDK.setVideoEncoderConfiguration(config)
                }
            }
            
            
            agoraSDK.enableVideo()
            agoraSDK.setExternalVideoSource(true, useTexture: true, pushMode: true) //关键代码：启用自采集方案，触发AgoraVideoSourceProtocol的协议回调
            agoraSDK.setParameters("{\"che.video.keep_prerotation\":false}")        // 美颜专用私有方法
            agoraSDK.setParameters("{\"che.video.local.camera_index\":1025}")       // 美颜专用私有方法
            agoraSDK.setParameters("{\"che.video.keyFrameInterval\":1}")            // 视频发送码流中关键帧间隔从2s修改成1s
            agoraSDK.setParameters("{\"lowLatency\":true}")                         // 降低服务端转码推流服务器jitterBuffer

        }
        
        // .Video视频连麦。其他连麦者(嘉宾）
        if (agoraLiveType == .Video || agoraLiveType == .connectlive) && isRoomOwner == false {
            let config = AgoraVideoEncoderConfiguration.init(size:CGSize(width:720, height:1280),
                                                             frameRate: AgoraVideoFrameRate(rawValue: 20) ?? .fps15,
                                                             bitrate: 1000,
                                                             orientationMode: .fixedPortrait)
            agoraSDK.setVideoEncoderConfiguration(config)
            agoraSDK.enableVideo()
            
            if let transcodingUids = transcodingUids, let index: Int = transcodingUids.indexOf({$0 == localUid}) {
                // 构建本地预览画面。
                let localCanvas = AgoraRtcVideoCanvas()
                if let superviews = streamSuperViews, index > 0, index - 1 < superviews.count {
                    let superView = superviews[index - 1]
                    let currentView = UIView()
                    superView.addSubview(currentView)
                    streamerViewMapping[localUid] = currentView
                    currentView.frame = superView.bounds
                    
                    localCanvas.view = currentView
                    videoCanvasMapping[localUid] = localCanvas
                }
                localCanvas.uid = localUid
                localCanvas.renderMode = .hidden
                agoraSDK.setupLocalVideo(localCanvas)
                agoraSDK.startPreview()
            }
        }
        
        //（被邀请者是虚拟房主）
        if agoraLiveType == .VideoCall {
            let config = AgoraVideoEncoderConfiguration.init(size:CGSize(width:720, height:1280),
                                                             frameRate: AgoraVideoFrameRate(rawValue: 20) ?? .fps15,
                                                             bitrate: 1000,
                                                             orientationMode: .fixedPortrait)
            agoraSDK.setVideoEncoderConfiguration(config)
            
            agoraSDK.enableVideo()
            if self.useOutCapture == true {
                agoraSDK.setExternalVideoSource(true, useTexture: true, pushMode: true) //关键代码：启用自采集方案，触发AgoraVideoSourceProtocol的协议回调
                agoraSDK.setParameters("{\"che.video.keep_prerotation\":false}")        // 美颜专用私有方法
                agoraSDK.setParameters("{\"che.video.local.camera_index\":1025}")       // 美颜专用私有方法
                agoraSDK.setParameters("{\"che.video.keyFrameInterval\":1}")            // 视频发送码流中关键帧间隔从2s修改成1s
                agoraSDK.setParameters("{\"lowLatency\":true}")                         // 降低服务端转码推流服务器jitterBuffer
            }else{
                // 构建本地预览画面。
                let localCanvas = AgoraRtcVideoCanvas()
                if let localPreview = localPreview {
                    localCanvas.view = localPreview
                }
                localCanvas.uid = localUid
                localCanvas.renderMode = .hidden
                agoraSDK.setupLocalVideo(localCanvas)
                agoraSDK.startPreview()
            }
            
        }
        
        // .PK主播PK模式。
        if (agoraLiveType == .PK || agoraLiveType == .newPK) {
            if isRoomOwner == true {
                streamerViewMapping[localUid] = localPreview                                    // 添加到streamViews容器
                
                let config = AgoraVideoEncoderConfiguration.init(size:CGSize(width:720, height:1280),
                                                                 frameRate: AgoraVideoFrameRate(rawValue: 20) ?? .fps15,
                                                                 bitrate: 1000,
                                                                 orientationMode: .fixedPortrait)
                agoraSDK.setVideoEncoderConfiguration(config)
                agoraSDK.enableVideo()
                
                agoraSDK.setExternalVideoSource(true, useTexture: true, pushMode: true) // 关键代码：启用自采集方案，触发AgoraVideoSourceProtocol的协议回调
                agoraSDK.setParameters("{\"che.video.keep_prerotation\":false}")        // 美颜专用私有方法
                agoraSDK.setParameters("{\"che.video.local.camera_index\":1025}")       // 美颜专用私有方法
                agoraSDK.setParameters("{\"che.video.keyFrameInterval\":1}")            // 视频发送码流中关键帧间隔从2s修改成1s
                agoraSDK.setParameters("{\"lowLatency\":true}")                         // 降低服务端转码推流服务器jitterBuffer
            }else{
                let config = AgoraVideoEncoderConfiguration.init(size:CGSize(width:720, height:1280),
                                                                 frameRate: AgoraVideoFrameRate(rawValue: 20) ?? .fps15,
                                                                 bitrate: 1000,
                                                                 orientationMode: .fixedPortrait)
                agoraSDK.setVideoEncoderConfiguration(config)
                agoraSDK.enableVideo()
                agoraSDK.muteLocalAudioStream(true)
                agoraSDK.muteLocalVideoStream(true)
            }
        }

        //log.verbose("agoratest agoraKitInit in")
        agoraKit = agoraSDK
        setlogFile(enable: true, logFilter: 0x080f)
        //log.verbose("agoratest agoraKitInit out")
    }
  
    // 2）设置角色。（Broadcaster = 1, audience = 2）
    func setChannelRole(role: AgoraClientRole) {
        addRestartFunc(funcEnum: .setChannelRole, data: [role])
        guard let agoraKit = agoraKit else { return }
        self.curChannelRole = role
        if role == .audience, self.isRoomOwner == false, self.agoraLiveType == .PK || self.agoraLiveType == .newPK || self.agoraLiveType == .multiVideo {
            let options = AgoraClientRoleOptions()
            options.audienceLatencyLevel = .lowLatency
            agoraKit.setClientRole(role, options: options)
        }else{
            agoraKit.setClientRole(role)
        }
        
        /* 3.0.2版本发现一个bug，我们基于目前声网的SDK，没有办法制作一个纯静音的默认环境。
         所以声网建议：通过"调节音量实现全局静音"，实现默认房间内除主播外全局静音
         所以，针对AgoraClientRole = broadcaster的情况，请再外部业务确认可发言后，强制将音量调回100。
         */
        setRecordingVolume(volume: 0)
    }
    
    
    // 3）设置采集音量。(除主播外，默认都设置为0。连麦可发言者设100，100为建议数值，不够了解的前期下，不建议乱设置)
    func setRecordingVolume(volume: Int) {
        addRestartFunc(funcEnum: .setRecordingVolume, data: [volume])
        guard let agoraKit = agoraKit else { return }
        personVolume = Int32(volume)
        agoraKit.adjustRecordingSignalVolume(volume)
    }
    
    // 4）加入频道。（Token如果后台不给，可以不传）
    func joinChannel(token: String?, channelId: String) {
        gLog("agora joinChannel channelId=\(channelId)")
        addRestartFunc(funcEnum: .joinChannel, data: [token,channelId])
        self.internal_joinChannel(token: token, channelId: channelId)
    }
    
    fileprivate func internal_joinChannel(token: String?, channelId: String) {
        if isLoginRoomCalled == true {
            leaveChannel()
        }
        isLoginRoomStage = true
        updateTokenTimer?.cancel()
        updateTokenTimer = nil
        self.roomId = channelId
        //log.debug("AgoraRtc：joinChannel=\(channelId)")
        guard let agoraKit = agoraKit else { return }
        // 每次加入前，先执行一次清除。
        
        if agoraLiveType == .PK || agoraLiveType == .newPK {
            resetPKCanvas(uids: [0,0])
        }
        
        if let token = token,token.count > 0 {
            self.token = token
            joinCheckDelay?.cancel()
            joinCheckDelay = delay(12.0) {
                MeMeKitConfig.showHUDBlock(MeMeKitConfig.localizeStringBlock("check_network", .normal))
            }
            
    //        #if DEBUG
    //        if let token = token, token.count > 0 {
    //                        HUD.flash("存在channelId \(channelId)")
    //        } else {
    //            HUD.flash("Token 不存在，问下C++同学")
    //        }
    //        #endif

    //        agoraKit.setParameters("{\"che.audio.keep.audiosession\": true}")
    //        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
    //        agoraKit.setParameters( "{\"che.audio.mixable.option\":true}" )

            //log.verbose("agoratest joinChannel,channelId=\(channelId)")
            isLoginRoomCalled = true
            let code = agoraKit.joinChannel(byToken: token,           // 频道名称。
                channelId: channelId,                                 // 频道名称。必填
                info: nil,                                            // 该信息不会传递给频道内的其他用户。
                uid: localUid,                                        // 32位,无符号整数。
                joinSuccess: nil)                                     // 依赖didJoinChannel的代码回调。
            
            gLog("agora didjoinChannel channelId=\(channelId),code=\(code)")
            //log.debug("AgoraRtc：joinChannel.joinChannel(byToken:channelId:...")
            if code != 0 {
                DispatchQueue.main.async(execute: {
                    #if DEBUG
                    //                HUD.flash("AgoraRtc：join channel failed: \(code)")
                    #endif
                })
            }
        }else{
            self.agoraVoiceDelegate?.agoraTokenExpired?()
        }
    }
    
    // 5）离开频道。（每次离开必须调用，不管当前是否在通话中，都可以调用leaveChannel()，没有副作用）
    func leaveChannel() {
        isLoginRoomStage = false
        isLoginRoomCalled = false
        updateTokenTimer?.cancel()
        updateTokenTimer = nil
        guard let agoraKit = agoraKit else { return }
        /* 1.是异步操作。
         * 2.在真正退出频道后，SDK 会触发 didLeaveChannelWithStats 回调。*/
        publishRetryTimer?.cancel()
        publishRetryTimer = nil
       
        // 是房主（主播）情况下
        if isRoomOwner {
            if let myPushUrl = self.transcodingPushUrl {
                //log.debug("AgoraRtc：leaveChannel.RoomOwner.RemovePublish")
                agoraKit.removePublishStreamUrl(myPushUrl)
            }
            
            agoraKit.setupLocalVideo(nil)
        }
        //log.debug("AgoraRtc：leaveChannel.all")
        if self.devMode == true {
            tipLabel.removeFromSuperview()
        }
        agoraKit.leaveChannel(nil)
        // 如果当前用户离开房间，那么销毁所有的自绘窗口
        destoryAllCacheStreamView()
    }
    
    // 6）销毁引擎。
    func destroyAgoraEngine(_ isRestart:Bool = false) {
        isJoinedChannel = false
        //log.verbose("agoratest destroyAgoraEngine in")
        AgoraRtcEngineKit.destroy()
        //log.verbose("agoratest destroyAgoraEngine out")
        joinCheckDelay?.cancel()
        joinCheckDelay = nil
        publishRetryTimer?.cancel()
        publishRetryTimer = nil
        
        isLoginRoomStage = false
        isLoginRoomCalled = false
        updateTokenTimer?.cancel()
        updateTokenTimer = nil
        joinedUids.removeAll()
        orderUids = nil
        
        for oneView in needRemoveViews {
            oneView.removeFromSuperview()
        }
        needRemoveViews.removeAll()
        
        if self.devMode == true {
            tipLabel.removeFromSuperview()
        }
        UIApplication.shared.setMultiValueMixTrue(uniqueKey: "\(self.className)+\(self.getAddress())", keyPath: \UIApplication.isIdleTimerDisabled, value: false)
    }
    
    private func destoryAllCacheStreamView() {
        for (uid, view) in streamerViewMapping {
            if uid != roomOwnerUid {
                if uid == localUid {
                    
                }
                if view?.superview != nil {
                    view?.removeFromSuperview()
                }
            }
        }
        videoCanvasMapping.removeAll()
        if agoraLiveType == .multiVideo {
            for (uid, view) in streamerViewMapping {
                if uid != localUid {
                    if view?.superview != nil {
                        view?.removeFromSuperview()
                    }
                }
            }
        }
        streamerViewMapping.removeAll()
    }
}

//MARK: - 【Public】可选 通用接口
extension AgoraLiveManager {
    // .PK，右侧PK者窗口显隐，不删除
    func setPKWindowHidden(hidden: Bool) {
        addRestartFunc(funcEnum: .setPKWindowHidden, data: [hidden])
        guard let uids = transcodingUids, uids.count > 1 else {
            return
        }
        for (index,uid) in uids.enumerated() {
            if uid == nil {continue}
            let uid = uid ?? 0
            if uid == 0 {continue}
            let oppsidUid = uids[index] ?? 0
            
            if let canvas = videoCanvasMapping[oppsidUid] {
                if let userView = canvas.view {
                    userView.isHidden = hidden
                }
            }
        }
    }
    
    // .PK，窗口布局（两位PK的主播）
    func resetPKCanvas(uids: [UInt]) {
        guard uids.count > 1 else {
            return
        }
        if isRoomOwner == true {
            transcodingUids = uids
        }else{
            var newUids:[UInt] = []
            if uids[0] == 0,let index = joinedUids.firstIndex(where: {$0 == Int(roomOwnerUid)}) {
                newUids.append(UInt(joinedUids[index]))
            }else{
                newUids.append(0)
            }
            if uids[0] == 0,let index = joinedUids.firstIndex(where: {$0 != Int(roomOwnerUid)}) {
                newUids.append(UInt(joinedUids[index]))
            }else{
                newUids.append(0)
            }
            transcodingUids = newUids
        }
        
        resetRemoteLiveTranscoding()
        
        var contentTop:CGFloat = 0
        var contentBottom:CGFloat = 0
        var top:CGFloat = PKWindowSpaceTop
        if agoraLiveType == .newPK {
            top = PKWindowSpaceTopNew
        }
        var height:CGFloat = PKWindowHeight
        let screenBounds = UIScreen.main.bounds
        if screenBounds.height / screenBounds.width < 640.0 / 360.0 {
            let extraHeight = (640.0 * screenBounds.width / 360.0 - screenBounds.height) / 2.0
            if agoraLiveType == .newPK {
                top = 100.0 * screenBounds.size.width / 360.0 - extraHeight;
            }else{
                top = 130.0 * screenBounds.size.width / 360.0 - extraHeight;
            }
            
            height = PKWindowWidth * 4.0 / 3.0
        }
        contentTop = top
        contentBottom = top + height
        
        for (index,uid) in uids.enumerated() {
            if uid == 0 {continue}
            if self.isRoomOwner == true,index == 0 {continue}
            var position = index
            
            let hostingView = UIView(frame: CGRect(x: PKWindowSpaceRight*CGFloat(position), y: top, width: PKWindowWidth, height: height))
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            needRemoveViews.append(hostingView)
            
            let oppsidUid = uids[position]
            
            let remoteCanvas = AgoraRtcVideoCanvas()
            remoteCanvas.uid = oppsidUid
            remoteCanvas.view = hostingView
            remoteCanvas.renderMode = .hidden
            //log.debug("AgoraRtc：didJoinedOfUid.setupRemoteVideo")
            if let resultCode = agoraKit?.setupRemoteVideo(remoteCanvas), resultCode != 0 {
                print("AgoraRtc：setupRemoteVideo return code:\(resultCode)")
            }else{
            }
            videoCanvasMapping[oppsidUid] = remoteCanvas
            agoraVoiceDelegate?.addPKUserWindow?(view: hostingView)
        }
        
//        if self.needRemoveViews.contains(where: {$0.tag == 9998123}) == false {
//            let topView      = UIImageView(image: UIImage(named: "pk_top_bg"))
//            topView.tag = 9998123
//            let bottomView   = UIImageView(image: UIImage(named: "pk_bottom_bg"))
//            topView.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: contentTop)
//            self.needRemoveViews.append(topView)
//            agoraVoiceDelegate?.addPKUserWindow?(view: topView)
//            bottomView.frame = CGRect.init(x: 0, y: contentBottom, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - contentBottom)
//            self.needRemoveViews.append(bottomView)
//            agoraVoiceDelegate?.addPKUserWindow?(view: bottomView)
//        }
    }
    
    func resetMultiVideoCanvas(uids: [UInt?]) {
        addRestartFunc(funcEnum: .resetMultiVideoCanvas, data: [uids])
        orderUids = uids
        realResetMultiVideoCanvas()
    }
    
    func resetOrderedRemoteLiveTranscoding() {
        let joinedUids = self.joinedUids
        var uids:[UInt?] = []
        if let orderUids = orderUids {
            for (index,uid) in orderUids.enumerated() {
                if uid == nil || uid == localUid || joinedUids.contains(where: {$0 == uid!}) {
                    uids.append(uid)
                }else{
                    uids.append(nil)
                }
            }
        }
        transcodingUids = uids
        resetRemoteLiveTranscoding()
    }
    
    func realResetMultiVideoCanvas() {
        resetOrderedRemoteLiveTranscoding()
        
        guard let streamSuperViews = streamSuperViews, streamSuperViews.count > 0, let transcodingUids = transcodingUids, agoraLiveType == .multiVideo else {
            return
        }
        
        // 布局窗口。
        for (i, uid) in transcodingUids.enumerated() {
            if uid == nil {continue}
            let uid = uid ?? 0
            if uid == localUid {continue}
            
            var curView: UIView
            var curCanvas: AgoraRtcVideoCanvas
            
            // 从缓存中找，找到对应uid的流View，找不到就新建一个
            if let tmpView = streamerViewMapping[uid], let streamView = tmpView {
                curView = streamView
            } else {
                curView = UIView()
                streamerViewMapping[uid] = curView
            }
            
            // 从缓存中找，找到对应uid的流canvas，找不到就新建一个
            if let tmpCanvas = videoCanvasMapping[uid] {
                curCanvas = tmpCanvas
            } else {
                curCanvas = AgoraRtcVideoCanvas()
                videoCanvasMapping[uid] = curCanvas
            }
            
            // 从上层传递下来的对方容器视图。将流View添加到当前的streamSuperView上进行显示
            if streamSuperViews.count > i {
                let containerView = streamSuperViews[i]
                curView.frame = containerView.bounds
                curView.isUserInteractionEnabled = false
                containerView.addSubview(curView)
            }
            
            curCanvas.uid = uid
            curCanvas.renderMode = .hidden
            curCanvas.view = curView
            
            if let resultCode = agoraKit?.setupRemoteVideo(curCanvas), resultCode == 0 {
                print("AgoraRtc：setupRemoteVideo return code:\(resultCode)")
            }else{
            }
            
        }
    }
    
    func realAddedMultiVideoCanvas() {
        let oldUids = transcodingUids
        resetOrderedRemoteLiveTranscoding()
        
        guard let streamSuperViews = streamSuperViews, streamSuperViews.count > 0, let transcodingUids = transcodingUids, agoraLiveType == .multiVideo else {
            return
        }
        
        guard oldUids != transcodingUids else {return}
        
        var diffUids:[UInt?] = []
        for (index,uid) in transcodingUids.enumerated() {
            if let oldUids = oldUids,oldUids.count > index {
                if oldUids[index] != uid {
                    diffUids.append(uid)
                }else{
                    diffUids.append(nil)
                }
            }else{
                diffUids.append(uid)
            }
        }
        
        // 布局窗口。
        for (i, uid) in diffUids.enumerated() {
            if uid == nil {continue}
            let uid = uid ?? 0
            // uid若是当前用户自己，并且她还是房主，不需要在此操作任何页面。
            if uid == localUid {
                continue
            }
            
            var curView: UIView
            var curCanvas: AgoraRtcVideoCanvas
            
            // 从缓存中找，找到对应uid的流View，找不到就新建一个
            if let tmpView = streamerViewMapping[uid], let streamView = tmpView {
                curView = streamView
            } else {
                curView = UIView()
                streamerViewMapping[uid] = curView
            }
            
            // 从缓存中找，找到对应uid的流canvas，找不到就新建一个
            if let tmpCanvas = videoCanvasMapping[uid] {
                curCanvas = tmpCanvas
            } else {
                curCanvas = AgoraRtcVideoCanvas()
                videoCanvasMapping[uid] = curCanvas
            }
            
            // 从上层传递下来的对方容器视图。将流View添加到当前的streamSuperView上进行显示
            if streamSuperViews.count > i {
                let containerView = streamSuperViews[i]
                curView.frame = containerView.bounds
                curView.isUserInteractionEnabled = false
                containerView.addSubview(curView)
            }
            
            curCanvas.uid = uid
            curCanvas.renderMode = .hidden
            curCanvas.view = curView
            
            // 同步到远端
            if let resultCode = agoraKit?.setupRemoteVideo(curCanvas), resultCode == 0 {
                print("AgoraRtc：setupRemoteVideo return code:\(resultCode)")
            }else{
            }
        }
    }
    
    // Video，窗口布局（主播、连麦者）
    func resetVideoCanvas(uids: [UInt]) {
        addRestartFunc(funcEnum: .resetVideoCanvas, data: [uids])
        transcodingUids = uids
        resetRemoteLiveTranscoding()
        
        guard let streamSuperViews = streamSuperViews, streamSuperViews.count > 0, let transcodingUids = transcodingUids, agoraLiveType == .Video else {
            return
        }
        
        // 去掉所有的view
        for tmpSuperView in streamSuperViews {
            for subview in tmpSuperView.subviews {
                subview.removeFromSuperview()
            }
        }
        
        // 布局连麦窗口。
        for (i, uid) in transcodingUids.enumerated() {
            if uid == nil {continue}
            let uid = uid ?? 0
            // uid若是当前用户自己，并且她还是房主，不需要在此操作任何页面。
            if uid == localUid && isRoomOwner == true {
                continue
            }
            
            var canvas: AgoraRtcVideoCanvas
            if let tmpCanvas = videoCanvasMapping[uid] {
                canvas = tmpCanvas
            } else {
                canvas = AgoraRtcVideoCanvas()
                videoCanvasMapping[uid] = canvas
            }
            
            canvas.uid = uid
            canvas.renderMode = .hidden
        
            // uids里index = 0，一定是房主，并且自己不是房主，要使用localPreview做画面的显示。
            if i == 0 && isRoomOwner == false {
                canvas.view = localPreview
                agoraKit?.setupRemoteVideo(canvas)
                continue
            }
            
            let remoteIndex = i - 1
            if remoteIndex > streamerViewMapping.count { break }

            //防止数组越界
            if remoteIndex >= streamSuperViews.count || remoteIndex < 0 {
                continue
            }

            let selectedView = streamSuperViews[remoteIndex]
            
            var currentView: UIView
            if let tmpView = streamerViewMapping[uid], let streamView = tmpView {
                // 从缓存的streamerViewMapping中，找到对应uid的流View
                currentView = streamView
            } else {
                // 如果从缓存中找不到流View，那么新建一个
                currentView = UIView()
                streamerViewMapping[uid] = currentView
            }
            
            currentView.frame = selectedView.bounds
            
            // 将流View添加到当前的streamSuperView上进行显示
            selectedView.addSubview(currentView)
            
            // uid若是当前用户自己，他需要调整他的本地预览窗口位置。重新构建本地预览画面。
            if uid == localUid {
                canvas.view = currentView
                canvas.uid = localUid
                canvas.renderMode = .hidden
                agoraKit?.setupLocalVideo(canvas)
                agoraKit?.startPreview()
            } else {
                canvas.view = currentView
                if let resultCode = agoraKit?.setupRemoteVideo(canvas), resultCode == 0 {
                    print("AgoraRtc：setupRemoteVideo return code:\(resultCode)")
                }else{
                }
            }
            // print("remoteUidsuid = \(uid), index = \(i), selectedView.x = \(selectedView.frame.origin.x), y = \(selectedView.frame.origin.y), width = \(selectedView.frame.size.width), height = \(selectedView.frame.size.height)")
        }
    }
    
    // 心动连线，窗口布局（主播、连麦者）
    func resetConnectLiveCanvas(uids: [UInt]) {
        addRestartFunc(funcEnum: .resetConnectLiveCanvas, data: [uids])
        transcodingUids = uids
        resetRemoteLiveTranscoding()
        
        guard let streamSuperViews = streamSuperViews, streamSuperViews.count > 0, let transcodingUids = transcodingUids, agoraLiveType == .connectlive else {
            return
        }
        
        // 去掉所有的view
        for tmpSuperView in streamSuperViews {
            for subview in tmpSuperView.subviews {
                subview.removeFromSuperview()
            }
        }
        
        // 布局连麦窗口。
        for (i, uid) in transcodingUids.enumerated() {
            if uid == nil {continue}
            let uid = uid ?? 0
            // uid若是当前用户自己，并且她还是房主，不需要在此操作任何页面。
            if uid == localUid && isRoomOwner == true {
                continue
            }
            
            var canvas: AgoraRtcVideoCanvas
            if let tmpCanvas = videoCanvasMapping[uid] {
                canvas = tmpCanvas
            } else {
                canvas = AgoraRtcVideoCanvas()
                videoCanvasMapping[uid] = canvas
            }
            
            canvas.uid = uid
            canvas.renderMode = .hidden
        
            // uids里index = 0，一定是房主，并且自己不是房主，要使用localPreview做画面的显示。
            if i == 0 && isRoomOwner == false {
                canvas.view = localPreview
                agoraKit?.setupRemoteVideo(canvas)
                continue
            }
            
            let remoteIndex = i - 1
            if remoteIndex > streamerViewMapping.count { break }
            
            let selectedView = streamSuperViews[remoteIndex]
            
            var currentView: UIView
            if let tmpView = streamerViewMapping[uid], let streamView = tmpView {
                // 从缓存的streamerViewMapping中，找到对应uid的流View
                currentView = streamView
            } else {
                // 如果从缓存中找不到流View，那么新建一个
                currentView = UIView()
                streamerViewMapping[uid] = currentView
            }
            
            currentView.frame = selectedView.bounds
            
            // 将流View添加到当前的streamSuperView上进行显示
            selectedView.addSubview(currentView)
            
            // uid若是当前用户自己，他需要调整他的本地预览窗口位置。重新构建本地预览画面。
            if uid == localUid {
                canvas.view = currentView
                canvas.uid = localUid
                canvas.renderMode = .hidden
                agoraKit?.setupLocalVideo(canvas)
                agoraKit?.startPreview()
            } else {
                canvas.view = currentView
                if let resultCode = agoraKit?.setupRemoteVideo(canvas), resultCode == 0 {
                    print("AgoraRtc：setupRemoteVideo return code:\(resultCode)")
                }else{
                }
            }
            // print("remoteUidsuid = \(uid), index = \(i), selectedView.x = \(selectedView.frame.origin.x), y = \(selectedView.frame.origin.y), width = \(selectedView.frame.size.width), height = \(selectedView.frame.size.height)")
        }
    }
    
    // .VideoCall
    func resetVideoCallCanvas(oppositeId: UInt) {
        addRestartFunc(funcEnum: .resetVideoCallCanvas, data: [oppositeId])
        guard let streamSuperViews = streamSuperViews, streamSuperViews.count > 0, agoraLiveType == .VideoCall else {
            return
        }
        
        // 去掉所有的view
        for tmpSuperView in streamSuperViews {
            for subview in tmpSuperView.subviews {
                subview.removeFromSuperview()
            }
        }
        
        var curView: UIView
        var curCanvas: AgoraRtcVideoCanvas
        
        // 从缓存中找，找到对应uid的流View，找不到就新建一个
        if let tmpView = streamerViewMapping[oppositeId], let streamView = tmpView {
            curView = streamView
        } else {
            curView = UIView()
            streamerViewMapping[oppositeId] = curView
        }
        
        // 从缓存中找，找到对应uid的流canvas，找不到就新建一个
        if let tmpCanvas = videoCanvasMapping[oppositeId] {
            curCanvas = tmpCanvas
        } else {
            curCanvas = AgoraRtcVideoCanvas()
            videoCanvasMapping[oppositeId] = curCanvas
        }
        
        // 从上层传递下来的对方容器视图。将流View添加到当前的streamSuperView上进行显示
        let containerView = streamSuperViews[0]
        curView.frame = containerView.bounds
        curView.isUserInteractionEnabled = false
        containerView.addSubview(curView)
        
        curCanvas.uid = oppositeId
        curCanvas.renderMode = .hidden
        curCanvas.view = curView
        
        // 同步到远端
        if let resultCode = agoraKit?.setupRemoteVideo(curCanvas), resultCode == 0 {
            print("AgoraRtc：setupRemoteVideo return code:\(resultCode)")
        }else{
        }
    }
    
    func resetCanvasFrame(rect: CGRect, uid: UInt){
        addRestartFunc(funcEnum: .resetCanvasFrame, data: [rect,uid])
        if let canvas = videoCanvasMapping[uid] {
            canvas.view?.frame = rect
        }
    }
    
    // 自采集视频数据。在此同步给声网的推流引擎。目前的数据是720P：width = 720,height = 1280
    func syncCapture(sampleBuffer: CMSampleBuffer?) {
        self.syncCapture(sampleBuffer: sampleBuffer,pixelBuffer: nil)
    }
    func syncCapture(sampleBuffer: CMSampleBuffer?,pixelBuffer:CVPixelBuffer?) {
        guard let sampleBuffer = sampleBuffer else { return  }
        
        guard let pixelBuffer: CVPixelBuffer = pixelBuffer ?? CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        //        print("AgoraRtc：width = \(width), height: \(height)")
        
        if isJoinedChannel {
            let frame = AgoraVideoFrame()
            frame.format = 12
            frame.time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            frame.textureBuf = pixelBuffer
            frame.strideInPixels = Int32(width)
            frame.height = Int32(height)
            
            agoraKit?.pushExternalVideoFrame(frame)
        }
    }
  
    // 重置Token。
    func renewAgoraToken(token: String) {
        addRestartFunc(funcEnum: .renewAgoraToken, data: [token])
        updateTokenTimer?.cancel()
        updateTokenTimer = nil
        
        guard let agoraKit = agoraKit else { return }
       
        if token.count > 0 {
            if self.isLoginRoomStage == true {
                if self.token == nil {
                    self.joinChannel(token: token, channelId: self.roomId)
                }else{
                    self.token = token
                    agoraKit.renewToken(token)
                }
            }
        }else{
            updateTokenTimer?.cancel()
            updateTokenTimer = timeout(2.0) { [weak self] in
                self?.agoraVoiceDelegate?.agoraTokenExpired?()
            }
        }
    }
    
    // 静音，当前用户，0 == 成功。
    func muteOwnAudio(muted: Bool) -> Int {
        addRestartFunc(funcEnum: .muteOwnAudio, data: [muted])
        guard let agoraKit = agoraKit else { return 0 }
      
        // （该方法用于允许/禁止往网络发送本地音频流）
        let operateCode = agoraKit.muteLocalAudioStream(muted)
        isMeMuted = muted
        return Int(operateCode)
    }
    
    // 静音，所有远端用户，0 == 成功。
    func muteOtherUsersAudio(muted: Bool) -> Int {
        addRestartFunc(funcEnum: .muteOtherUsersAudio, data: [muted])
        guard let agoraKit = agoraKit else { return 0 }
        
        // muteAllRemoteAudioStreams 是全局控制，muteRemoteAudioStream 是精细控制
        let operateCode = agoraKit.muteAllRemoteAudioStreams(muted)
        isOthersMuted = muted
        if muted {
            isOtherIdsMuted = joinedUids.mapUids()
        }else{
            isOtherIdsMuted = []
        }
        return Int(operateCode)
    }
    
    func refreshMuteStatus() {
        var hasNotContained = false
        for uid in joinedUids {
            if isOtherIdsMuted.contains(where: {$0 == uid}) {
                hasNotContained = true
                break
            }
        }
        if hasNotContained == true  {
            isOthersMuted = false
        }else{
            isOthersMuted = true
        }
    }
    
    // 静音，将某一远端用户，0 == 成功。
    func muteOneUserAudio(uid: UInt, muted: Bool) -> Int {
        guard let agoraKit = agoraKit else { return 0 }
       
        // 如果之前有对"所有远端音频进行静音"，在调用本API之前，请确保你已调用muteOtherUsersAudio(false)
        let operateCode = agoraKit.muteRemoteAudioStream(uid, mute: muted)
        if muted == true {
            isOtherIdsMuted.append(uid)
            refreshMuteStatus()
        }else{
            if let index = isOtherIdsMuted.firstIndex(where: {uid == $0}) {
                isOtherIdsMuted.remove(at: index)
            }
            refreshMuteStatus()
        }
        return Int(operateCode)
    }
    
    // 停止推送本地视频流，只推声音流。
    func muteLocalVideoStream(muted: Bool) -> Int {
        addRestartFunc(funcEnum: .muteLocalVideoStream, data: [muted])
        guard let agoraKit = agoraKit else { return 0 }
        
        let operateCode = agoraKit.muteLocalVideoStream(muted)
        return Int(operateCode)
    }
    
    func getMeMuteAudio() -> Bool {
        return isMeMuted
    }
    
    func getOtherUserAudio(uid: UInt) -> Bool {
        return isOtherIdsMuted.contains(where: {$0 == uid})
    }
    
    func getAllOtherUsersAudio() -> Bool {
        return isOthersMuted
    }
    
    // 是否开启外功放
    func enableSpeakerphone(enableSpeaker: Bool) -> Int {
        guard let agoraKit = agoraKit else { return 0 }
        
        let operateCode = agoraKit.setEnableSpeakerphone(enableSpeaker)
        return Int(operateCode)
    }
    
    func getPeakerphoneEnabled() -> Bool {
        guard let agoraKit = agoraKit else { return false }
        
        return agoraKit.isSpeakerphoneEnabled()
    }
    
    // 旋转摄像头，默认前置摄像头，每点击一次，交互替换一次。
    func switchCamera()-> Int {
        addRestartFunc(funcEnum: .switchCamera, data: [])
        guard let agoraKit = agoraKit else { return 0 }
        
        let operateCode = agoraKit.switchCamera()
        return Int(operateCode)
    }
    
    func playEffectSound(filePath: String, publish: Bool = true, effectID: Int32 = 1) -> Int {
        addRestartFunc(funcEnum: .playEffectSound, data: [filePath])
        guard let agoraKit = agoraKit else { return 0 }
        //https://docs.agora.io/cn/Interactive%20Broadcast/API%20Reference/oc/Classes/AgoraRtcEngineKit.html#//api/name/playEffect:filePath:loopCount:pitch:pan:gain:publish:
        let operateCode = agoraKit.playEffect(effectID, filePath: filePath, loopCount: 0, pitch: 1.0, pan: 0.0, gain: 100, publish: publish)
        
        return Int(operateCode)
    }
    
    func stopPlayEffectSound(effectID: Int32 = 1) {
        agoraKit?.stopEffect(effectID)
    }
    
    // 设置混音
    func startAudioMixing(filePath: String,stageChanged:((_ state:AgoraAudioMixingStateCode)->())? = nil) -> Int {
        addRestartFunc(funcEnum: .startAudioMixing, data: [filePath])
        guard let agoraKit = agoraKit else { return 0 }
        mixStateChangedBlock = stageChanged
        clearCacheMixPosition()
        // 文档https://docs.agora.io/cn/Voice/API%20Reference/oc/Classes/AgoraRtcEngineKit.html#//api/name/startAudioMixing:loopback:replace:cycle:
        let operateCode = agoraKit.startAudioMixing(filePath, loopback: false, replace: false, cycle: 1)
        return Int(operateCode)
    }
    
    func getAudioEffectPreset() -> MeMeAudioEffectPreset {
        return mixPreset
    }
    
    func setAudioEffectPreset(present:MeMeAudioEffectPreset) {
        addRestartFunc(funcEnum: .setAudioEffectPreset, data: [present])
        guard let agoraKit = agoraKit else { return }
        mixPreset = present
        agoraKit.setAudioEffectPreset(present.agoraEffectPreset)
    }
    
    func getAudioMixingVolum() -> Int {
        return Int(mixVolume)
    }
    func adjustAudioMixingVolume(volume: Int) {
        addRestartFunc(funcEnum: .adjustAudioMixingVolume, data: [volume])
        guard let agoraKit = agoraKit else { return }
        mixVolume = Int32(volume)
        agoraKit.adjustAudioMixingVolume(volume)
        
        self.mixVolumeDelayDispatch?.cancel()
        self.mixVolumeDelayDispatch = delay(0.5) { [weak self] in
            
        }
    }
    
    func getRecordingSignalVolume() -> Int {
        return Int(personVolume)
    }
    func adjustRecordingSignalVolume(volume: Int) {
        setRecordingVolume(volume: volume)
    }
    
    func getPauseAudioMixing() -> Bool? {
        return isPausedMix
    }
    func pauseAudioMixing(isPause: Bool) {
        addRestartFunc(funcEnum: .pauseAudioMixing, data: [isPause])
        guard let agoraKit = agoraKit else { return }
        isPausedMix = isPause
        if isPause == true {
            clearCacheMixPosition()
            agoraKit.pauseAudioMixing()
        }else{
            clearCacheMixPosition()
            agoraKit.resumeAudioMixing()
        }
    }
    
    func stopAudioMixing() {
        addRestartFunc(funcEnum: .stopAudioMixing, data: [])
        guard let agoraKit = agoraKit else { return }
        isPausedMix = nil
        mixStateChangedBlock = nil
        clearCacheMixPosition()
        agoraKit.stopAudioMixing()
    }
    //ms
    func getAudioMixPosition() -> Int? {
        if mixPositionTimePassed < 2.0,let cacheMixPosition = cacheMixPosition {
            return Int(cacheMixPosition) + Int(mixPositionTimePassed * 1000)
        }else{
            var mixPos:Int?
            if isPausedMix != nil {
                if let pos = agoraKit?.getAudioMixingCurrentPosition() {
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
    //ms
    func setAudioMixPosition(pos:Int) {
        addRestartFunc(funcEnum: .setAudioMixPosition, data: [pos])
        guard let agoraKit = agoraKit else { return }
        clearCacheMixPosition()
        agoraKit.setAudioMixingPosition(pos)
    }
    
    func clearCacheMixPosition() {
        cacheMixPosition = nil
        mixPositionTimePassed = 0
        mixPositionTimer?.cancel()
        mixPositionTimer = nil
    }
    
    func enableInEarMonitoring(enable:Bool)->Int {
        addRestartFunc(funcEnum: .enableInEarMonitoring, data: [enable])
        guard let agoraKit = agoraKit else { return -9999}
        let result:Int = Int(agoraKit.enable(inEarMonitoring: enable))
        if(result < 0){
            return result
        }
        
        if(enable){
            agoraKit.setInEarMonitoringVolume(100)
        }
        return result
    }
    
    func setVoicePitch(_ pitch:Double)->Int {
        addRestartFunc(funcEnum: .setVoicePitch, data: [pitch])
        guard let agoraKit = agoraKit else { return -9999}
        return Int(agoraKit.setLocalVoicePitch(pitch))
    }
    
    func setMusicPitch(_ pitch:Int)->Int {
        addRestartFunc(funcEnum: .setMusicPitch, data: [pitch])
        guard let agoraKit = agoraKit else { return -9999}
        return Int(agoraKit.setAudioMixingPitch(pitch))
    }
    
    func sendData(type:SendDataType,params:[String:Any]) {
        guard let agoraKit = agoraKit else { return }
        var streamId = dataTypeStream[type]
        if streamId == nil {
            let str = UnsafeMutablePointer<Int>.allocate(capacity: 0)
            agoraKit.createDataStream(str, reliable: true, ordered: true)
            streamId = str.pointee
            str.deallocate()
            dataTypeStream[type] = streamId
        }
        if let streamId = streamId, streamId > 0 {
            var newParams = params
            newParams["type"] = type.rawValue
            DispatchQueue.global().async { [weak self] in
                if let agoraKit = self?.agoraKit {
                    if let data = newParams.toJsonString()?.data(using: .utf8) {
                        let ret = agoraKit.sendStreamMessage(streamId, data: data)
                        if ret != 0 {
                            
                        }
                    }
                }
            }
            
        }
        
        
    }
}

//MARK: - 【Public】辅助 通用接口
extension AgoraLiveManager {
    // 获取SDK信息。
    func getAgoraSdkVersion() -> String {
        let version =  "SDKVer:" + AgoraRtcEngineKit.getSdkVersion() + "MediaVer:" + AgoraRtcEngineKit.getSdkVersion()
        
        return version
    }

    // 是否启用日志和日志等级。（日志路径->CachesDirectory/AgoraVoiceLog.txt）
    func setlogFile(enable: Bool, logFilter: Int) {
        guard let agoraKit = agoraKit else { return}
        
        // 不启用日志
        if enable == false { return }
        
        let filePath: URL = FileUtils.cachesDirectory.appendingPathComponent("AgoraVoiceLog.txt")

        agoraKit.setLogFile(filePath.absoluteString);
        
        /* off = 0; debug = 0x080f; info = 0x000f; warning = 0x000e; error = 0x000c; critical = 0x0008; */
        agoraKit.setLogFilter(UInt(logFilter))
    }
}

// MARK: - 【Public】Voice，Video，旁路推流（主播）
extension AgoraLiveManager {
    /* 1.只有主播(房主)，才需进行下述配置，调用一定要在"JoinChannel"回调之后实现。
     * 2.维护了一个"AgoraLiveTranscoding"对象，该对象传递最终会通过"setLiveTranscoding"同步给声网Server。
     * 3.声网Server通过读取对象内的配置，在Server端合流，随后转推给"pushUrl"传递来的CDN地址，从而让普通观众通过传统CDN获取到合成的视频。
     * 4.在.Voice的模式下，不需要配置相应"视频属性"，只需存在音频即可。
     * 5."LiveTranscoding"中的"transcodingUsers"，涵盖该频道内的所有用户，每个用户都是一个AgoraLiveTranscodingUser对象。
     * 6.每个"AgoraLiveTranscodingUser"，包含了Server端合流布局时的"相对位置"和"视图层级"。
     * 7.当有人进出该频道时，要重置transcodingUsers，并通过setLiveTranscoding同步给声网Server。
     */

    func pushStreamingToCDNByAnchor(pushUrl: String) {
        //log.debug("AgoraRtc：pushStreamingToCDNByAnchor")
        // 通话，是不需要旁路推流。
        if agoraLiveType == .VideoCall ||  agoraLiveType == .VoiceCall { return }
        
        // 只有当前是主播(房主)进入
        if isRoomOwner == false { return }
        // 下面代码逻辑只能执行一次
        if transcodingAddedFlag == true { return }
        
        transcodingPushUrl = pushUrl
        splitedPushUrl(pushUrl)
        
        let liveTranscoding = AgoraLiveTranscoding()
        // 音频配置
        liveTranscoding.audioBitrate = 92
        liveTranscoding.audioSampleRate = .type44100
        liveTranscoding.audioChannels = 2
        
        // 视频配置
        if agoraLiveType == .Video || agoraLiveType == .PK || agoraLiveType == .newPK || agoraLiveType == .connectlive || agoraLiveType == .multiVideo {
            let backgroundImage = AgoraImage()
            if agoraLiveType == .PK || agoraLiveType == .newPK {
                if let url = URL(string: TranscodingBackgroundImageUrl)  {
                    backgroundImage.url = url
                }
                backgroundImage.rect = CGRect(x: 0, y: 0, width: transcodingLayoutWidth, height: transcodingLayoutHeight)
            }else if agoraLiveType == .multiVideo {
                var url = TranscodingBackgroundImageUrl_9
                if let view = streamSuperViews {
                    if view.count == 4 {
                        url = TranscodingBackgroundImageUrl_4
                    }else if view.count == 6 {
                        url = TranscodingBackgroundImageUrl_6
                    }
                }
                if let url = URL(string: url)  {
                    backgroundImage.url = url
                }
                backgroundImage.rect = CGRect.init(origin: CGPoint(), size: localPreview?.size ?? CGSize(width: transcodingLayoutWidth,height: transcodingLayoutHeight))
            }
            
            
            liveTranscoding.size = CGSize(width: transcodingLayoutWidth,
                                          height: transcodingLayoutHeight)          // 旁路视频的总尺寸（宽与高）
            liveTranscoding.videoBitrate = 1000                                     // 旁路视频的码率。 400 Kbps 为默认值
            if agoraLiveType == .multiVideo {
                liveTranscoding.size = localPreview?.size ?? CGSize(width: transcodingLayoutWidth,
                                                                    height: transcodingLayoutHeight)
            }
            liveTranscoding.videoFramerate = 15                                     // 15 fps 为默认值
            liveTranscoding.lowLatency = true                                       // 低延时，不保证画质。（默认值）高延时，保证画质。
            liveTranscoding.videoGop = 30                                           // 用于旁路直播的输出视频的 GOP。单位为帧。
            liveTranscoding.videoCodecProfile = .high                               // 默认值，最高视频编码率
            liveTranscoding.backgroundImage = backgroundImage
        }
        
        transcoding = liveTranscoding
        
        // 构建transcodingUsers，index = 0的用户应该是主播(房主)自己。
        let uids: [UInt] = [localUid]
        transcodingUids = uids
        resetRemoteLiveTranscoding()
        
        // 旁路推流地址
         //log.debug("AgoraRtc：addPublishStreamUrl.call")
        let code = agoraKit?.addPublishStreamUrl(pushUrl, transcodingEnabled: true)
        if code == 0 {
            //log.debug("AgoraRtc：addPublishStreamUrl == 0")
            transcodingAddedFlag = true
            publishRetryTimer?.cancel()
            publishRetryTimer = timeout(60.0) { [weak self] in
                if let urlString = self?.transcodingPushUrl {
                    self?.agoraKit?.startRtmpStreamWithoutTranscoding(urlString)
                }
            }
        }
    }
    
    // 有人进出Channel时，要调整setLiveTranscoding的transcodingUsers。
    fileprivate func resetRemoteLiveTranscoding() {
        // 通话，不需要transcodingUsers
        if agoraLiveType == .VideoCall ||  agoraLiveType == .VoiceCall { return }
        
        if isRoomOwner == false { return }
        
        if isJoinedChannel == false {return}
        
        // 重置 setLiveTranscoding.transcodingUsers
        if let transcoding = transcoding {
            let userArray = getTranscodingUserArray()
            transcoding.transcodingUsers = userArray
            for item in userArray {
            }
            agoraKit?.setLiveTranscoding(transcoding)
        }
    }
    
    
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
    
    // 构造一组，[AgoraLiveTranscodingUser]
    private func getTranscodingUserArray() -> [AgoraLiveTranscodingUser] {
        var users = [AgoraLiveTranscodingUser]()
        guard let transcodingUids = transcodingUids else {
            return users
        }
        
        for (i, uerId) in transcodingUids.enumerated() {
            if uerId == nil {continue}
            let uerId = uerId ?? 0
            if uerId == 0 {continue}
            users.append(getOneTranscodingUser(uerId, UInt(i)))
        }
        
        // print("AgoraRtc：Transcoding Users: ", users)
        return users
    }
    
    // 构造一个，AgoraLiveTranscodingUser
    private func getOneTranscodingUser(_ uid: UInt, _ index: UInt) -> AgoraLiveTranscodingUser {
        let user = AgoraLiveTranscodingUser()
        user.uid = uid
        user.rect = CGRect(x:0, y:0, width:0, height:0)
        
        if agoraLiveType == .Voice || agoraLiveType == .Radio {
            return user
        }
        
        if agoraLiveType == .PK || agoraLiveType == .newPK {
            user.alpha = 1
            user.zOrder = Int(index)
            
            // PK窗口布局参数
            let windowWidth: CGFloat = 180 * transcodingLayoutWidth / 360
            var windowSpaceTop: CGFloat = 130.0 * transcodingLayoutHeight / 640
            if agoraLiveType == .newPK {
                windowSpaceTop = 100.0 * transcodingLayoutHeight / 640
            }
            
            let windowSpaceRight: CGFloat = windowWidth
            let windowHeight: CGFloat = windowWidth * 4 / 3
            
            // 左侧主播窗口
            if index == 0 {
                user.rect = CGRect(x: 0, y: windowSpaceTop, width: windowWidth, height: windowHeight)
                return user
            }
            
            // 右侧主播窗口
            if index == 1 {
                user.rect = CGRect(x: windowSpaceRight, y: windowSpaceTop, width: windowWidth, height: windowHeight)
                return user
            }
        }
        
        if agoraLiveType == .multiVideo {
            user.alpha = 1
            user.zOrder = Int(index)
            
            if let views = streamSuperViews, views.count > index {
                user.rect = views[Int(index)].frame
                return user
            }
        }
        
        if agoraLiveType == .Video {
            user.alpha = 1
            user.zOrder = Int(index)
            
            // 房主窗口
            if index == 0 {
                user.rect = CGRect(x:0, y:0, width:transcodingLayoutWidth, height:transcodingLayoutHeight)
                return user
            }
            
            // 连麦者窗口
            let pushSize = CGSize.init(width: transcodingLayoutWidth, height: transcodingLayoutHeight)
            let scaleFactor: CGFloat = pushSize.height/640.0 > pushSize.width / 360.0 ? pushSize.width / 360.0 : pushSize.height / 640.0
            
            let height = 164.0 / UIScreen.main.bounds.height * 640.0
            let width = height * 110.0 / 164.0
            
            let window_height:CGFloat = height * scaleFactor
            let window_width:CGFloat = width * scaleFactor
            let window_x:CGFloat = pushSize.width - 15 - window_width
            var window_y:CGFloat = pushSize.height / 2.0 - window_height / 2.0 + 15
            
            if index == 2 {
                window_y = window_y - window_height
            }
            
            user.rect = CGRect(x:window_x, y:window_y, width:window_width, height:window_height)
            
//            print("AgoraRtc：user.index =\(index)  ,x = \(user.rect.x), y = \(user.rect.y), width = \(user.rect.width), height = \(user.rect.height)")
            return user
        }else if agoraLiveType == .connectlive {
            user.alpha = 1
            user.zOrder = Int(index)
            
            // 房主窗口
            if index == 0 {
                user.rect = CGRect(x:0, y:0, width:transcodingLayoutWidth, height:transcodingLayoutHeight)
                return user
            }
            
            // 连麦者窗口
            let pushSize = CGSize.init(width: transcodingLayoutWidth, height: transcodingLayoutHeight)
            let scaleFactor: CGFloat = pushSize.height/640.0 > pushSize.width / 360.0 ? pushSize.width / 360.0 : pushSize.height / 640.0
            
            let height = 164.0 / UIScreen.main.bounds.height * 640.0
            let width = height * 110.0 / 164.0
            
            let window_height:CGFloat = height * scaleFactor
            let window_width:CGFloat = width * scaleFactor
            let window_x:CGFloat = pushSize.width - 15 - window_width
            let window_y:CGFloat = pushSize.height / 2.0 - window_height / 2.0 + 15
            
            user.rect = CGRect(x:window_x, y:window_y, width:window_width, height:window_height)
            
//            print("AgoraRtc：user.index =\(index)  ,x = \(user.rect.x), y = \(user.rect.y), width = \(user.rect.width), height = \(user.rect.height)")
            return user
        }
        
        return user
    }
}

//MARK: - 【Private】Audio，判断是否在说话（主播，嘉宾）
fileprivate extension AgoraLiveManager {
    
    // 通过音量大小，判断是否在说话。
    fileprivate func isSpeakingJudgeVolume(volume: UInt) -> Bool {
        if curChannelRole == .broadcaster {
            if volume > 50 {
                return true
            }
        }else{
            if volume > 50 {
                return true
            }
        }
        
        return false
    }
    
    // 结合Agora的回调，过滤出正在说话的用户Id。
    fileprivate func judgeWhoIsSpeaking(speakers: [AgoraRtcAudioVolumeInfo]) -> [UInt] {
        var speakersNow = [UInt]();
        
        // 不是多人语音房间，不需要执行下面逻辑。
        guard agoraLiveType == .Voice || agoraLiveType == .Radio || agoraLiveType == .VoiceCall else {
            return speakersNow
        }

        for speaker in speakers {
            if isSpeakingJudgeVolume(volume: speaker.volume) {
                var uid = speaker.uid
                
                if uid == 0 { // 如果SDK 返回的UID = 0，表示是自己。
                    uid = UInt(myUid ?? 0)
                }
                speakersNow.append(uid)
            }
        }
        
        return speakersNow
    }
}
/* 1.AgoraRtcEngineDelegate。
 * 2.从 1.1 版本开始，SDK 使用 Delegate 代替原有的部分 Block 回调。 原有的 Block 回调被标为废弃，建议用相应的 Delegate 方法代替。
 * 3.如果同一个回调 Block 和 Delegate 方法都有定义，则 SDK 只回调 Block 方法。
 */

//MARK: - 【Protocol】所有模式下，AgoraVideoSourceProtocol协议（主播/嘉宾）
extension AgoraLiveManager: AgoraRtcEngineDelegate {
    
//MARK: 【Protocol】涉及 当前用户 "自己" 的回调。
    // 自己，连接，中断。（失去连接后，除非APP主动调用leaveChannel，SDK 会一直自动重连）
    func rtcEngineConnectionDidInterrupted(_ engine: AgoraRtcEngineKit) {
        // print("AgoraRtc：Connection interrupted")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, streamPublishedWithUrl url: String, errorCode: AgoraErrorCode) {
        //log.debug("AgoraRtc：stream.Published")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, streamUnpublishedWithUrl url: String, errorCode: AgoraErrorCode) {
         //log.debug("AgoraRtc：stream.Unpublished")
    }
    
    // 自己，连接，重连失败。（一定时间内，默认10秒）
    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKit) {
        // print("AgzoraRtc：Connection lost")
    }
    
    // 自己，自动重连成功。
    func rtcEngine(_ engine: AgoraRtcEngineKit, didRejoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        // print("AgoraRtc：I rejoin channel: \(channel), uid: \(uid), elapsed: \(elapsed)")
    }
    
    // 自己，连接，已被禁止。（被服务端禁掉连接的权限）
    func rtcEngineConnectionDidBanned(_ engine: AgoraRtcEngineKit) {
        // print("AgoraRtc：Connection did banned")
    }
    
    // 自己，Token，过期。（获取新Token，并调用renewToken方法）
    func rtcEngineRequestToken(_ engine: AgoraRtcEngineKit) {
        agoraVoiceDelegate?.agoraTokenExpired?()
    }
    
    // 自己，错误统一回调。
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
         print("AgoraRtc：Occur error: \(errorCode.rawValue)")
        gLog("agora didOccurError error=\(errorCode)")
    }
    
    // 自己，加入了指定的频道。
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        gLog("agora didJoinChanneled channelId=\(channel)")
        // 语音，默认使用听筒模式
        if agoraLiveType == .VoiceCall {
            agoraKit?.setEnableSpeakerphone(false)
        }
        isJoinedChannel = true
        //log.debug("AgoraRtc：iJoinedChannel")
        //log.verbose("agoratest iJoinedChannel")
//        print("AgoraRtc：I joined channel: \(channel), uid: \(uid), elapsed: \(elapsed)")
        if self.devMode == true {
            if let localPreview = self.logViewBlock?() ?? localPreview {
                tipLabel.removeFromSuperview()
                localPreview.addSubview(tipLabel)
                if agoraLiveType == .multiVideo {
                    tipLabel.frame = CGRect.init(x: 5, y: 5, width: tipLabel.bounds.width, height: tipLabel.bounds.height)
                }else{
                    tipLabel.frame = CGRect.init(x: localPreview.bounds.width - tipLabel.bounds.width - 5, y: 5, width: tipLabel.bounds.width, height: tipLabel.bounds.height)
                }
            }
        }
        agoraVoiceDelegate?.iJoinedChannel?(channel: channel)
    }
    
    // 自己，已离开当前的频道。
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        //print("AgoraRtc：I leaved channel: \(AgoraLiveHelper.channelStatsFormat(stats))")
        //log.debug("AgoraRtc：iLeavedChannel")
        gLog("agora didLeaveChannelWith stats=\(stats)")
        isJoinedChannel = false
        joinedUids.removeAll()
        if self.devMode == true {
            tipLabel.removeFromSuperview()
        }
        agoraVoiceDelegate?.iLeavedChannel?()
    }
    
    // 自己，语音路由变更。
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioRouteChanged routing: AgoraAudioOutputRouting) {
        // let routingStr = AgoraLiveHelper.outputRoutingTypeFormat(routing)
        // print("AgoraRtc：Audio route changed: " + routingStr)
        agoraVoiceDelegate?.didAudioRouteChanged?(routing: routing)
    }
    
    // 自己，SDK基本统计数据。（每两秒触发一次）
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportRtcStats stats: AgoraChannelStats) {
        let qualityStr = AgoraLiveHelper.channelStatsFormat(stats)
        // print("AgoraRtc：Report etc stats: \(qualityStr)")
        agoraVoiceDelegate?.reportAgoraStats?(stats: stats, formatStr: qualityStr)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason) {
        if state == .connected {
            joinCheckDelay?.cancel()
            joinCheckDelay = nil
        }else if state == .failed {
            if didConnectedFailedBlock?() != true {
                restartManger()
            }
        }else if state == .disconnected {
            if isLoginRoomStage == true {
                if didConnectedFailedBlock?() != true {
                    restartManger()
                }
            }else{
                didConnectedFailedBlock?()
            }
        }
    }
    
//MARK: - 【Protocol】涉及 其他用户 "他人" 的回调。
    // 他人，加入了当前的频道。
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        //print("AgoraRtc：Who joined, uid: \(uid), elapsed: \(elapsed)")
        joinedUids.append(Int(uid))
        refreshMuteStatus()
        //log.debug("AgoraRtc：didJoinedOfUid")
        if agoraLiveType == .PK || agoraLiveType == .newPK {
            if isRoomOwner == true {
                let ids = [UInt(localUid), UInt(uid)]
                resetPKCanvas(uids: ids)
            }else{
                if uid == self.roomOwnerUid {
                    resetPKCanvas(uids: [uid,0])
                }else{
                    resetPKCanvas(uids: [0,uid])
                }
            }
            
            
        }else if agoraLiveType == .multiVideo {
            self.realAddedMultiVideoCanvas()
        }
        
        agoraVoiceDelegate?.didJoinedOfUid?(uid: uid)
    }
    
    // 他人，离开频道回调。
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        let reasonStr = AgoraLiveHelper.userOfflineReasonTypeFormat(reason)
        //print("AgoraRtc：Who offline, uid: \(uid), reason: " + reasonStr)
        joinedUids.removeAll(where: {$0 == uid})
        refreshMuteStatus()
        //log.debug("AgoraRtc：didOfflineOfUid")
        // 视频连麦
        if let canvas = videoCanvasMapping[uid], agoraLiveType == .Video || agoraLiveType == .connectlive  {
            canvas.uid = uid
            canvas.renderMode = .hidden
            canvas.view = nil
            agoraKit?.setupRemoteVideo(canvas)
            streamerViewMapping.removeValue(forKey: uid)
        }
        
        // 主播PK
        if let canvas = videoCanvasMapping[uid], agoraLiveType == .PK || agoraLiveType == .newPK {
            if let userView = canvas.view {
                userView.isHidden = true
                agoraVoiceDelegate?.removePKUserWindow?(view: userView)
            }
            canvas.uid = uid
            canvas.renderMode = .hidden
            canvas.view = nil
            agoraKit?.setupRemoteVideo(canvas)
            streamerViewMapping.removeValue(forKey: uid)
        }else if agoraLiveType == .multiVideo {
            self.resetOrderedRemoteLiveTranscoding()
            if let canvas = videoCanvasMapping[uid]  {
                canvas.uid = uid
                canvas.renderMode = .hidden
                canvas.view = nil
                agoraKit?.setupRemoteVideo(canvas)
                let view = streamerViewMapping.removeValue(forKey: uid) as? UIView
                view?.removeFromSuperview()
            }
        }
        
        agoraVoiceDelegate?.didOfflineOfUid?(uid: uid, reason: reason)
    }
    
    // 他人，用户音频静音回调。(提示有用户将通话静音/取消静音。)
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        // print("AgoraRtc：Audio muted, muted: \(muted), uid: \(uid)")
    }
    
    // 他人，音量提示回调。
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        // print("AgoraRtc：report audio volume indication, speakers: \(speakers), totalVolume: \(totalVolume)")
        
        let newSpeakers:[MeMeAudioVolumeInfo] = speakers.map { info -> MeMeAudioVolumeInfo in
            let newInfo = MeMeAudioVolumeInfo()
            newInfo.uid = Int(info.uid)
            newInfo.volume = Int(info.volume)
            newInfo.channelId = info.channelId
            return newInfo
        }
        agoraVoiceDelegate?.auidoSpeakersAndVolume?(speakers: newSpeakers, totalVolume: totalVolume)
        let speakers = judgeWhoIsSpeaking(speakers: speakers)
        agoraVoiceDelegate?.audioSpeakers?(speakersId: speakers)
    }

    // 他人，禁止uid传输视频流画面。
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
        agoraVoiceDelegate?.didVideoMuted?(mute: muted, uid: uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, localAudioMixingStateDidChanged state: AgoraAudioMixingStateCode, reason:AgoraAudioMixingReasonCode) {
        if state == .failed {
            isPausedMix = nil
        }else if state == .playing {
            isPausedMix = false
        }
        mixStateChangedBlock?(state)
        if state == .failed {
            mixStateChangedBlock = nil
        }
    }
    
    func rtcEngineLocalAudioMixingDidFinish(_ engine: AgoraRtcEngineKit) {
        isPausedMix = nil
        mixStateChangedBlock = nil
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        let dict:[String:Any]?
        do {
            let json = try? JSON(data: data)
            dict = json?.dictionaryObject
        } catch {
           
        }
        if let typeStr = dict?["type"] as? String,let type = SendDataType.init(rawValue: typeStr) {
            self.delegates.excuteObject { (delegate) in
                delegate?.agoraDataDidFetched(type: type, uid: Int(uid), data: dict)
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
        agoraVoiceDelegate?.firstRemoteVideoFrameOfUid?(uid: Int(uid))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int) {
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, rtmpStreamingChangedToState url: String, state: AgoraRtmpStreamingState, errorCode: AgoraRtmpStreamingErrorCode) {
        var needRetry = false
        if errorCode == .streamingErrorCodeConnectionTimeout {
            needRetry = true
        }else if errorCode == .streamingErrorCodeInternalServerError {
            needRetry = true
        }else if errorCode == .streamingErrorCodeRtmpServerError {
            needRetry = true
        }else if errorCode == .streamPublishErrorNetDown {
            needRetry = true
        }
        if needRetry == true {
            if let transcodingPushUrl = transcodingPushUrl {
                agoraKit?.stopRtmpStream(transcodingPushUrl)
                agoraKit?.startRtmpStream(withTranscoding: transcodingPushUrl, transcoding: transcoding)
            }
            
        }
    }
}

//MARK: - 【Protocol】Video，AgoraVideoSourceProtocol协议（主播）
extension AgoraLiveManager: AgoraVideoSourceProtocol {
    func captureType() -> AgoraVideoCaptureType {
        return .camera
    }
    
    func contentHint() -> AgoraVideoContentHint {
        return .none
    }
    
    //  需要通过实现下述接口，来创建自定义的视频源(视频自采集)，并设置传递给Agora底层的Media Engine 进行推流。
    var consumer: AgoraVideoFrameConsumer? {
        get {
            return agoraConsumer
        }
        
        set(consumer) {
            agoraConsumer = consumer
        }
    }
    
    // 我们指定了视频数据类型为"pixelBuffer"
    func bufferType() -> AgoraVideoBufferType {
        return .pixelBuffer
    }
    
    func shouldInitialize() -> Bool {
        return true
    }
    
    func shouldStart() {

    }
    
    func shouldStop() {

    }
    
    func shouldDispose() {
        
    }
}
