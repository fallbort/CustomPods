//
//  MeMeLivePushManager.swift
//  MeMe
//
//  Created by fabo on 2022/1/13.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation
import Foundation
import Cartography
import MeMeKit
import UIKit
import SwiftyUserDefaults

public enum LivePusherType : Int {
    case agora = 0  //声网sdk
    case zego  //zego sdk
}

public enum LivePushRoomType: Int {
    case Voice             = 0             // 多人语音模式
    case Video             = 1             // 视频连麦模式
    case PK                = 2             // 主播PK模式
    case VideoCall         = 3             // 视频，无需旁路推流
    case VoiceCall         = 4             // 语音，无需旁路推流
    case connectlive       = 5             // 心动连线
    case multiVideo        = 6             // 多人视频
    case Radio             = 7             // 电台模式
    case newPK             = 8              //主播新PK模式
}

public enum LivePushAudioMixingStateCode : Int {
    case playing = 1
    case paused = 2
    case stopped = 3
    case failed = 4
}

public enum LivePushClientRole : Int {
    case broadcaster = 1
    case audience = 2
}

public enum MeMeAudioOutputRouting : Int {
    case other = -2  //所有其他
    case normal = -1 //普通
    case speakerphone
    case loudspeaker
}

public enum LivePushUserOfflineReason : Int {
    case other = -1  //其他
    case quit = 1 //退出
    case dropped  //
    case exchange  //切换身份
}

public enum SendDataType:String {
    case ktv_lrc_check = "lrc_check"
}

public class MeMeAudioVolumeInfo : NSObject {
    public var uid:Int = 0
    public var volume:Int = 0
    public var channelId:String = ""
}

public enum MeMeAudioEffectPreset : Int {
    case source = 0 //原声
    case liuxing  //流行
    case rb   //r&b
    case ktv   //ktv
    case luyin  //录音棚
    case yanchang  //演唱会
    case liusheng //留声机
    case uncle  //大叔
    case girl   //小姐姐
    case liti   //立体声
}

public struct MeMeLivePushObject {
    public var liveType: LivePushRoomType = .Voice
    public var seatNum:Int = 1  //坐席数，目前用于multiVideo
    public var myPos:Int = 0 //所在位置，目前用于multiVideo
    public var anchorUid: Int = 0
    public var currentUid: Int = 0
    public var streamId:Int = 0 //流id
    public var isAnchor: Bool = false  //是否是房间主播
    public var preview: UIView?   //可预览的本地视图
    public var views: [UIView]?   //所有用户直播流的父窗口
    public var uids: [UInt] = []  //所有的用户id
    
    public init() {}
}

public protocol LivePushSingleDelegate  {
    //连接失败
    func livePushConnectedFailed() -> Bool
}

extension LivePushSingleDelegate {
    public func livePushConnectedFailed() -> Bool {return false}
}

public protocol LivePushMultiDelegate  {
    //获取数据
    func livePushDataDidFetched(type:SendDataType,uid:Int,data:[String:Any]?)
    // 我加入channel频道成功。
    func iJoinedChannel(channel: String)
    // 我退出channel频道成功。
    func iLeavedChannel()
    // uid 加入当前所在频道
    func didJoinedOfUid(uid: UInt)
    // uid 离开当前所在频道
    func didOfflineOfUid(uid: UInt,reason:LivePushUserOfflineReason?)
    // 当前频道整体质量(定时回调)
    func livePushReportPushStats(_ stats: Any)
    //zego时时下行码率回调
    func onPlayerQualityUpdate(videoKBPS: Double)
    //zego时时上行码率回调
    func onPublisherQualityUpdate(videoSendBytes: Double)
    // Token过期了
    func livePushTokenExpired()
    
    
    // uid 该用户关闭了自己的摄像头
    func didVideoMuted(mute: Bool, uid: UInt)
    // 音频的路由发生了改变
    func didAudioRouteChanged(routing: MeMeAudioOutputRouting)
    // uids 当前发言用的
    func audioSpeakers(speakersId:[UInt])
    // 当前发言人及他的说话声响以及最大的响度
    func auidoSpeakersAndVolume(speakers: [MeMeAudioVolumeInfo], totalVolume: Int)
    //视频第一帧
    func firstRemoteVideoFrameOfUid(uid:Int)
    
    
    // 主播PK，PK匹配成功，添加PK者的视图
    func addPKUserWindow(view: UIView)
    // 主播PK，PK一次结束，移除PK者的视图
    func removePKUserWindow(view: UIView)
    
}

extension LivePushMultiDelegate {
    public func livePushDataDidFetched(type:SendDataType,uid:Int,data:[String:Any]?) {}
    public func iJoinedChannel(channel: String)  {}
    public func iLeavedChannel() {}
    public func didJoinedOfUid(uid: UInt) {}
    public func didOfflineOfUid(uid: UInt,reason:LivePushUserOfflineReason?) {}
    public func didVideoMuted(mute: Bool, uid: UInt) {}
    public func didAudioRouteChanged(routing: MeMeAudioOutputRouting) {}
    public func audioSpeakers(speakersId:[UInt]) {}
    public func auidoSpeakersAndVolume(speakers: [MeMeAudioVolumeInfo], totalVolume: Int) {}
    public func livePushReportPushStats(_ stats: Any) {}
    public func onPlayerQualityUpdate(videoKBPS: Double) {}
    public func onPublisherQualityUpdate(videoSendBytes: Double) {}
    public func firstRemoteVideoFrameOfUid(uid:Int) {}
    public func livePushTokenExpired() {}
    public func addPKUserWindow(view: UIView) {}
    public func removePKUserWindow(view: UIView) {}
}

public protocol MeMeLivePusher :NSObjectProtocol {
    var liveDelegate:LivePushSingleDelegate? { get set } //已定义
    var liveDelegates:WeakReferenceArray<LivePushMultiDelegate> {get} //已定义
    var livePusherType:LivePusherType {get set}  //已定义,当前使用的类型
//    var restartedBlock:((_ manger:MeMeLivePusher)->())? {get set}//已定义，重启回调,目前没在用
//    var localPreviewBlock:((_ isShow:Bool,_ view:UIView?)->())? {get set}  //已定义，使用外部预览
    var liveRoomType:LivePushRoomType {get}
    var myPosition:Int {get}
    
    var logViewBlock:(()->UIView?)? {get set}  //打上log的view
    
    init(_ object:MeMeLivePushObject,devMode:Bool,appId:String)
    
    func setChannelRole(role: LivePushClientRole) //设置是主播还是用户
    
    func switchCamera()-> Int //切换摄像头
    func muteLocalVideoStream(muted: Bool) -> Int //停止推送本地视频流，只推声音流。
    func muteLocalVideo(muted: Bool)  //是否关闭本地视频
    func getLocalVideoMuted() -> Bool //获取本地视频状态
    
    func enableSpeakerphone(enableSpeaker: Bool) -> Int //是否开启外功放
    func getPeakerphoneEnabled() -> Bool //是否开启外功放
    func playEffectSound(filePath: String) -> Int  //播放声效
    func playEffectSound(filePath: String, publish: Bool, effectID: Int) //播放声效
    func muteAudio(userId:Int?,muted:Bool) -> Int //静音统一接口，userId = -1 是自己，userId = 0 是所有其他人，其他为某个用户
    func getMuteAudio(userId:Int?) -> Bool //获取静音统一接口，userId = -1 是自己，userId = 0 是所有其他人，其他为某个用户
    
    func adjustRecordingSignalVolume(volume: Int)  //调整话筒音量
    func getRecordingSignalVolume() -> Int //获取话筒音量
    
    func setVoicePitch(_ pitch:Double)->Int //设置人声音调
    func setMusicPitch(_ pitch:Int)->Int //设置音乐文件音调
    
    func setAudioEffectPreset(present:MeMeAudioEffectPreset) //设置人声音效
    func getAudioEffectPreset() -> MeMeAudioEffectPreset //获取人声音效
    
    func enableInEarMonitoring(enable:Bool)->Int //开启耳返
    
    func startAudioMixing(filePath: String,stageChanged:((_ state:LivePushAudioMixingStateCode)->())?) -> Int  //开始混音
    func setAudioMixPosition(pos:Int)   //设置混音位置ms
    func getAudioMixPosition() -> Int? //获取混音位置ms
    func adjustAudioMixingVolume(volume: Int) //设置混音音量
    func getAudioMixingVolum() -> Int //获取混音音量
    func pauseAudioMixing(isPause: Bool) //暂停或恢复混音
    func getPauseAudioMixing() -> Bool? //获取暂停状态
    func stopAudioMixing() //停止混音
    func stopPlayEffectSound(effectID: Int) //停止音效

    func setPKWindowHidden(hidden: Bool)   //右侧PK窗口显隐
    func resetCanvasFrame(rect: CGRect, uid: UInt) //调整窗口位置
    func joinChannel(token: String?, channelId: String)  //加入频道
    func leaveChannel()   //离开频道
    func resetCanvas(uids: [UInt])  //重设画布,不需要关注空白位置
    func resetCanvas(uids: [UInt?]) //重设画布
    func pushStreamingToCDN(pushUrl: String)  //设置推流
    func syncCapture(sampleBuffer: CMSampleBuffer?)  //同步视频画面
    func renewToken(token: String)  //刷新token
    func destroyEngine()  //销毁
    
    func sendData(type:SendDataType,params:[String:Any])  //发数据
}

private var MeMeLivePusherWeakDeleagte = "MeMeLivePusherWeakDeleagte"
private var MeMeLivePusherMultiDeleagte = "MeMeLivePusherMultiDeleagte"
private var MeMeLivePusherRestartBlockKey = "MeMeLivePusherRestartBlockKey"
private var MeMeLivePusherOutPreviewBlockKey = "MeMeLivePusherOutPreviewBlockKey"
private var MeMeLivePusherTypeKey = "MeMeLivePusherTypeKey"

extension MeMeLivePusher {
    public var liveDelegate: LivePushSingleDelegate? {
        get {
            let weakArray = objc_getAssociatedObject(self, &MeMeLivePusherWeakDeleagte) as? WeakReferenceArray<LivePushSingleDelegate>
            if let object = weakArray?.allObjects().first as? LivePushSingleDelegate {
                return object
            } else {
                return nil
            }
        }
        
        set {
            let weakArray = WeakReferenceArray<LivePushSingleDelegate>()
            if let object = newValue {
                weakArray.addObject(object)
            }
            objc_setAssociatedObject(self, &MeMeLivePusherWeakDeleagte, weakArray, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var liveDelegates:WeakReferenceArray<LivePushMultiDelegate> {
        get {
            let object = objc_getAssociatedObject(self, &MeMeLivePusherMultiDeleagte) as? WeakReferenceArray<LivePushMultiDelegate>
            if let object = object {
                return object
            }else{
                let newobject = WeakReferenceArray<LivePushMultiDelegate>()
                objc_setAssociatedObject(self, &MeMeLivePusherMultiDeleagte, newobject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return newobject
            }
        }
    }
    
//    var restartedBlock:((_ manger:MeMeLivePusher)->())? {
//        get {
//            let timer = objc_getAssociatedObject(self, &MeMeLivePusherRestartBlockKey) as? ((_ manger:MeMeLivePusher)->())
//            return timer
//        }
//
//        set {
//            objc_setAssociatedObject(self, &MeMeLivePusherRestartBlockKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
//        }
//    }
    
//    var localPreviewBlock:((_ isShow:Bool,_ view:UIView?)->())? {
//        get {
//            let timer = objc_getAssociatedObject(self, &MeMeLivePusherOutPreviewBlockKey) as? ((_ isShow:Bool,_ view:UIView?)->())
//            return timer
//        }
//        
//        set {
//            objc_setAssociatedObject(self, &MeMeLivePusherOutPreviewBlockKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
//        }
//    }
    
    public var livePusherType:LivePusherType {
        get {
            if let typeInt = objc_getAssociatedObject(self, &MeMeLivePusherTypeKey) as? Int {
                return LivePusherType.init(rawValue: typeInt) ?? .agora
            }
            return .agora
        }
        
        set {
            let typeInt = newValue.rawValue
            objc_setAssociatedObject(self, &MeMeLivePusherTypeKey, typeInt, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}




public class MeMeLivePushManager : NSObject {
    
    //MARK:<>外部变量
    //MARK:<>外部block
    
    
    //MARK:<>生命周期开始

    //MARK:<>功能性方法
    public class func startup(isDev:Bool,appId:String) {
        self.isDev = isDev
        self.appId = appId
    }
    public class func getPusherType(pusherType outPusherType:LivePusherType? = nil,object:MeMeLivePushObject) -> LivePusherType? {
        var pusherType:LivePusherType?
        if let oneType = outPusherType {
            pusherType = oneType
        }else{
            pusherType = getDefaultPushType()
        }
        if object.liveType == .connectlive || object.liveType == .Video || object.liveType == .PK || object.liveType == .newPK || object.liveType == .Radio || object.liveType == .VideoCall || object.liveType == .VoiceCall || object.liveType == .Voice || object.liveType == .multiVideo {
            
        }else{
            pusherType = .agora
        }
        return pusherType
    }
    
    public class func getPusher(pusherType outPusherType:LivePusherType? = nil,object:MeMeLivePushObject) -> MeMeLivePusher? {
        let pusherType:LivePusherType? = self.getPusherType(pusherType: outPusherType, object: object)
        var pusher:MeMeLivePusher?
        let devMode = self.isDev
        let appId = self.appId
        #if (!arch(i386) && !arch(x86_64)) || (!os(iOS) && !os(watchOS) && !os(tvOS))
        switch pusherType {
        case .agora:
            pusher = LiveAgoraPusher.init(object,devMode:devMode,appId:appId)
        break
        case .zego:
            #if ZegoImported
            pusher = LiveZegoPusher.init(object,devMode:devMode,isProductMode:isProductMode)
            #endif
        break
        case .none:
            break
        }
        if let pusher = pusher,let pusherType = pusherType {
            pusher.livePusherType = pusherType
            pushers.addObject(pusher)
        }
        #endif
        return pusher
    }
    
    public class func setDefaultPushType(_ pusherType:LivePusherType) {
        defaultPushType = pusherType
    }
    
    public class func getDefaultPushType() -> LivePusherType {
        return  defaultPushType
    }
    //MARK:<>内部View
    
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    fileprivate static var pushers:WeakReferenceArray = WeakReferenceArray<MeMeLivePusher>()
    
    fileprivate static var defaultPushMemoryType:(MeMeLivePusher.Type)? {
        didSet {
            
        }
    }
    
    fileprivate static var defaultPushType:LivePusherType = .agora
    
    fileprivate static var isDev = false
    fileprivate static var appId = ""
    //MARK:<>内部block
    
}

extension LivePushMultiDelegate {
    public func mapOptionalUids(uids:[UInt?]?) -> [Int?]? {
        if let uids = uids {
            return self.mapUids(uids: uids)
        }
        return nil
    }
    
    public func mapOptionalUids(uids:[Int?]?) -> [UInt?]? {
        if let uids = uids {
            return self.mapUids(uids: uids)
        }
        return nil
    }
    
    public func mapUids(uids:[UInt?]) -> [Int?] {
        let newUids:[Int?] = uids.map({ uid in
            if let uid = uid {
                return Int(uid)
            }
            return nil
        })
        return newUids
    }
    
    public func mapUids(uids:[Int?]) -> [UInt?] {
        let newUids:[UInt?] = uids.map({ uid in
            if let uid = uid {
                return UInt(uid)
            }
            return nil
        })
        return newUids
    }
    
    public func mapOptionalUids(uids:[UInt]?) -> [Int]? {
        if let uids = uids {
            return self.mapUids(uids: uids)
        }
        return nil
    }
    
    public func mapOptionalUids(uids:[Int]?) -> [UInt]? {
        if let uids = uids {
            return self.mapUids(uids: uids)
        }
        return nil
    }
    
    public func mapUids(uids:[UInt]) -> [Int] {
        let newUids:[Int] = uids.map({ uid in
            return Int(uid)
        })
        return newUids
    }
    
    public func mapUids(uids:[Int]) -> [UInt] {
        let newUids:[UInt] = uids.map({ uid in
            return UInt(uid)
        })
        return newUids
    }
}
