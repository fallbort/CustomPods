//
//  LivePlayMannager.swift
//  MeMe
//
//  Created by fabo on 2020/9/17.
//  Copyright © 2020 sip. All rights reserved.
//

import Foundation
import MeMeKit

public enum LivePlayingState : Int {
    case other = -1
    case prepareing = 1
    case ready
    case playing
    case paused
    case stopped
    case error
    case completed
}

@objc public enum LivePlayerType : Int {
    case qiniu = 0
    case sourceIJK
    case meMedia
}

@objc public protocol LivePlayManagerDelegate  {
    @objc optional func liveStartPlayed(_ renderTime:Double,livePlayer:MeMeLivePlayer,play playView:UIView?)   //播放器已开始播放第一帧画面
    @objc optional func livePlayingStateChanged(state:Int)    //播放器状态改变
    @objc optional func liveStoppedError(error:NSError)     //播放器因失败而停止
    @objc optional func liveStartReloadSameStream(errorMsg:String?)    //播放器重新载入流地址
    @objc optional func liveSeekTo(isCompleted:Bool,curTime:Double)   //播放器定位到回调
    @objc optional func mediaPlayerSei(zegoData: Data)   //播放器接受Sei的回调
    @objc optional func playerInfoStateChangeed(state:UInt32)
}

@objc public protocol MeMeLivePlayer :NSObjectProtocol {
    weak var delegate:LivePlayManagerDelegate? { get set }
    var loopPlay:Bool { get set }   //是否循环播放
    var isMute:Bool { get set }  //是否静音
    var contentMode:UIView.ContentMode { get set } //播放器显示模式
    var backgroundPlayEnable:Bool { get set }  //进入后台是否可以继续播放
    var streamUrl:String?  { get }   //播放的流地址
    init(baseView:UIView?,streamUrl:String?,isLive:Bool)
    func setPlayViewFrame(_ frame:CGRect)  //设置播放器rect
    func reloadStreamUrl(_ streamUrl:String)  // 不销毁控制器，直接重新加载新的拉流地址。
    func stopPlayer()   // 停止播放
    func resumePlayer()  // 恢复暂停的播放器
    func pausePlayer()   // 暂停播放器
    func enableRender(status:Bool)  // 进入后台，停止渲染。回头前台，恢复渲染。
    func playerSeek(to:TimeInterval)   // 指定媒体，位置播放。
    func getCurPlayingTime() -> TimeInterval   // 获取媒体，当前播放时间。
    func getTotalDuration() -> TimeInterval    // 获取媒体，完整时间。
    func getDownloadSpeed() -> Int64
    static func startup(config:String?)  //初始化
    static func endup()    //完结
}



@objc public class LivePlayMannager : NSObject {
    
    //MARK:<>外部变量
    
    //MARK:<>外部block
    
    //MARK:<>生命周期开始
    @objc public class func getPlayer(baseView:UIView? = nil,streamUrl:String? = nil,isLive:Bool,playerType playerTypeInt:Int = -1) -> MeMeLivePlayer? {
        
        let playerType:LivePlayerType?
        if let oneType = LivePlayerType.init(rawValue: playerTypeInt) {
            playerType = oneType
        }else{
            playerType = defaultPlayType
        }
        var player:MeMeLivePlayer?
        #if (!arch(i386) && !arch(x86_64)) || (!os(iOS) && !os(watchOS) && !os(tvOS))
        switch playerType {
        case .sourceIJK:
            player = LiveMePlayer.init(baseView: baseView, streamUrl: streamUrl,isLive:isLive)
        break
        case .qiniu:
            player = LiveMePlayer.init(baseView: baseView, streamUrl: streamUrl,isLive:isLive)
        case .meMedia:
            player = LiveMePlayer.init(baseView: baseView, streamUrl: streamUrl,isLive:isLive)
        break
        case .none:
            break
        }
        if let player = player {
            players.addObject(player)
        }
        #endif
        return player
    }

    @objc public class func setDefaultPlayerType(_ playerTypeInt:Int) {
        if let playerType = LivePlayerType.init(rawValue: playerTypeInt) {
            self.defaultPlayType = playerType
            #if (!arch(i386) && !arch(x86_64)) || (!os(iOS) && !os(watchOS) && !os(tvOS))
            switch playerType {
            case .sourceIJK:
                self.defaultPlayMemoryType = LiveMePlayer.self
            case .qiniu:
                self.defaultPlayMemoryType = LiveMePlayer.self
            case .meMedia:
                self.defaultPlayMemoryType = LiveMePlayer.self
            }
            #endif
        }
    }
    
    @objc public class func geDefaultPlayerMemoryType() -> (MeMeLivePlayer.Type)? {
        return defaultPlayMemoryType
    }
    
    @objc public class func getDefaultPlayerType() -> Int {
        return defaultPlayType.rawValue
    }
    
    //MARK:<>功能性方法
    @objc public class func enableRender(status:Bool) {
        players.excuteObject { (player) in
            player?.enableRender(status: status)
        }
    }
    
    //MARK:<>内部View
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    fileprivate static let shared:LivePlayMannager = LivePlayMannager()
    fileprivate static var defaultPlayType:LivePlayerType = .meMedia
    fileprivate static var players:WeakReferenceArray = WeakReferenceArray<MeMeLivePlayer>()
    
    fileprivate static var defaultPlayMemoryType:(MeMeLivePlayer.Type)? {
        didSet {
            oldValue?.endup()
        }
    }
    
    @objc public class func startup(playerType:LivePlayerType) {
        LivePlayMannager.setDefaultPlayerType(playerType.rawValue)
//        if let config = ConfigService.memeConfig?.ijkConfig {
//            LivePlayMannager.geDefaultPlayerMemoryType()?.startup(config: config)
//        }
    }
    
    
    //MARK:<>内部block
}
