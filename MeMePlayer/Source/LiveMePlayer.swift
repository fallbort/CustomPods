//
//  LiveMePlayer.swift
//  MeMe
//
//  Created by fabo on 2021/5/11.
//  Copyright © 2021 sip. All rights reserved.
//

import Foundation
import MeMeKit
import MeMediaPlayer
import Alamofire

fileprivate let kAutoReconnectMaxCount:Int = 120
#if (!arch(i386) && !arch(x86_64)) || (!os(iOS) && !os(watchOS) && !os(tvOS))
class LiveMePlayer :NSObject, MeMeLivePlayer {
   
    
    weak var delegate: LivePlayManagerDelegate?
    
    var loopPlay: Bool = false
    var isMute: Bool = false {
        didSet {
            if isMute == true {
                self.livePlayer?.setVolume(0.0)
                self.filePlayer?.setVolume(0.0)
            }else{
                self.livePlayer?.setVolume(1.0)
                self.filePlayer?.setVolume(1.0)
            }
        }
    }
    
    var contentMode: UIView.ContentMode = .scaleAspectFill {
        didSet {
            switch contentMode {
            case .scaleAspectFill:
                self.livePlayer?.setDisplayScaling(MeMediaPlayerDisplayScaleModeAspectFill)
                self.filePlayer?.setDisplayScaling(MeMediaPlayerDisplayScaleModeAspectFill)
            case .scaleAspectFit:
                self.livePlayer?.setDisplayScaling(MeMediaPlayerDisplayScaleModeAspectFit)
                self.filePlayer?.setDisplayScaling(MeMediaPlayerDisplayScaleModeAspectFit)
            case .scaleToFill:
                self.livePlayer?.setDisplayScaling(MeMediaPlayerDisplayScaleModeFill)
                self.filePlayer?.setDisplayScaling(MeMediaPlayerDisplayScaleModeFill)
            default:
                self.livePlayer?.setDisplayScaling(MeMediaPlayerDisplayScaleModeNone)
                self.filePlayer?.setDisplayScaling(MeMediaPlayerDisplayScaleModeNone)
            }
            
        }
    }
    
    var backgroundPlayEnable: Bool = true {
        didSet {
            self.livePlayer?.setPauseInBackground(!backgroundPlayEnable)
            self.filePlayer?.setPauseInBackground(!backgroundPlayEnable)
        }
    }
    
    var streamUrl: String?
    
    deinit {
        removePlayer()
        removeOldPlayer()
        NotificationCenter.default.removeObserver(self)
    }
    
    required init(baseView: UIView?, streamUrl: String?,isLive:Bool) {
        super.init()
        
        self.streamUrl = configUrl(streamUrl)
        self.reconnectCount = 0
        self.baseView = baseView
        self.isLive = isLive
        preparePlayer()
        resumePlayer()
    }
    
    func setPlayViewFrame(_ frame: CGRect) {
//        self.ijkPlayer?.view.frame = frame
    }
    
    func reloadStreamUrl(_ streamUrl: String) {
        let oldStream = self.streamUrl
        self.streamUrl = configUrl(streamUrl)
        self.reconnectCount = 0
        self.retryDelayDispatch?.cancel()
        self.retryDelayDispatch = nil
        removePlayer()
        preparePlayer()
        resumePlayer()
        removeOldPlayer()
    }
    
    func stopPlayer() {
        self.livePlayer?.stop()
        self.filePlayer?.stop()
    }
    
    func resumePlayer() {
        self.livePlayer?.play()
        self.filePlayer?.play()
    }
    
    func pausePlayer() {
        self.filePlayer?.pause()
    }
    
    func removePlayer() {
        stopPlayer()
        self.livePlayer?.shutdown()
        self.filePlayer?.shutdown()
        self.livePlayer = nil
        self.filePlayer = nil
    }
    
    func removeOldPlayer() {
        self.livePlayer_old?.stop()
        self.livePlayer_old?.shutdown()
        self.livePlayer_old = nil
        self.filePlayer_old?.stop()
        self.filePlayer_old?.shutdown()
        self.livePlayer_old = nil
    }
    
    func enableRender(status: Bool) {
        
    }
    
    func playerSeek(to: TimeInterval) {
        self.filePlayer?.seek(to)
    }
    
    func getCurPlayingTime() -> TimeInterval {
        return self.filePlayer?.getCurrentPostion() ?? 0.0
    }
    
    func getTotalDuration() -> TimeInterval {
        return filePlayer?.getDuration() ?? 0.0
    }
    
    
    
    //MARK:<>外部变量
    
    //MARK:<>外部block
    
    //MARK:<>生命周期开始
    
    //MARK:<>功能性方法
    
    func configUrl(_ urlString:String?) -> String? {
        if let urlString = urlString {
            var url = urlString
            url = url.replace("\\", withString: "")
            url = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return url
        }
        return nil
    }
    
    func preparePlayer() {
        if let text = streamUrl {
            let category =  AVAudioSession.sharedInstance().category
            let options = AVAudioSession.sharedInstance().categoryOptions
            if (category == .playback || category == .playAndRecord) && options.contains(.mixWithOthers) {} else {
                DispatchQueue.global().async {
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
                    }catch {
                        
                    }
                }
            }

            if isLive {
                self.livePlayer = MeMediaLivePlayer.init(url: text, ignoreCategory: true)
            }else{
                self.filePlayer = MeMediaVodPlayer.init(file: text, ignoreCategory: true)
            }
            if let view = baseView {
                self.livePlayer?.setDisplay(view)
                self.filePlayer?.setDisplay(view)
            }
            addIcon()
            self.livePlayer?.setMediaPlayerDelegate(self)
            self.livePlayer?.setMediaPlayerStateDelegate(self)
            self.livePlayer?.setMediaPlayerSeiDelegate(self)
            self.filePlayer?.setMediaPlayerDelegate(self)
            self.filePlayer?.setMediaPlayerStateDelegate(self)
 
            self.checkTime = Date().timeIntervalSince1970 * 1000
            let oldMode = contentMode
            self.contentMode = oldMode
            let backEnable = backgroundPlayEnable
            self.backgroundPlayEnable = backEnable
            let iMute = isMute
            self.isMute = iMute
            self.livePlayer?.play();
            
        }
    }
    
    fileprivate func addIcon() {
        #if DEBUG
        nameIcon?.removeFromSuperview()
        let oneIcon = UILabel()
        oneIcon.text = "mePlayer"
        oneIcon.font = UIFont.systemFont(ofSize: 22)
        oneIcon.textColor = UIColor.red
        oneIcon.sizeToFit()
        let iconSize = oneIcon.bounds.size
        baseView?.addSubview(oneIcon)
        var rect = baseView?.bounds ?? CGRect()
        rect = CGRect(x:rect.size.width - iconSize.width - 5,y:5,width:iconSize.width,height:iconSize.height)
        oneIcon.frame = rect
        nameIcon = oneIcon
        #endif
    }
    
    fileprivate class func getLiveStateFromState(_ state:MeMediaPlayerState) -> LivePlayingState {
        switch state {
        case MeMediaPlayerStateStarted:
            return .playing
        case MeMediaPlayerStatePaused:
            return .paused
        case MeMediaPlayerStateStopped:
            return .stopped
        default:
            return .other
        }
    }
    
    func replayStream() {
        if let urlStr = self.streamUrl {
            //log.verbose("ijkplayer replayStream")
            self.retryDelayDispatch?.cancel()
            self.retryDelayDispatch = nil
            removePlayer()
            preparePlayer()
            resumePlayer()
            
        }
    }
    
    static func startup(config:String?) {
        let deviceId = DeviceInfo.deviceId
        let deviceMode = "ios-" + DeviceInfo.modelName
        let bundleId = DeviceInfo.appBundleID
        MeMediaPlayer.initMediaPlayer(deviceId, deviceMode: deviceMode, systemVersion: DeviceInfo.systemVersion, appVersion: DeviceInfo.appVersion, userId: Int64(MeMeKitConfig.userIdBlock()), config: config ?? "")
        MeMediaPlayer.setAppChannel(0);
        let countryCode = "zh_CN"
        MeMediaPlayer.setCountryRegionCode(countryCode)
        
        startNetworkWatcher()
    }
    
    static func endup() {
        
    }
    
    class func startNetworkWatcher() {
        if case let .reachable(type) = reachablityManager?.status {
            switch type {
            case .ethernetOrWiFi:
                MeMediaPlayer.setNetworkType(MeMediaPlayerNetworkWIFI)
            case .cellular:
                MeMediaPlayer.setNetworkType(MeMediaPlayerNetworkWWAN)
            }
        }else{
            MeMediaPlayer.setNetworkType(MeMediaPlayerNetworkNone)
        }
        reachablityManager?.startListening(onUpdatePerforming: { (status) in
            if case let .reachable(type) = status {
                switch type {
                case .ethernetOrWiFi:
                    MeMediaPlayer.setNetworkType(MeMediaPlayerNetworkWIFI)
                case .cellular:
                    MeMediaPlayer.setNetworkType(MeMediaPlayerNetworkWWAN)
                }
            }else{
                MeMediaPlayer.setNetworkType(MeMediaPlayerNetworkNone)
            }
        })
    }
    
    func getDownloadSpeed() -> Int64 {
        return livePlayer?.getDownloadSpeed() ?? 0
    }
    
    //MARK:<>内部View
    //MARK:<>内部UI变量
    //MARK:<>内部数据变量
    fileprivate var livePlayer:MeMediaLivePlayer?
    fileprivate var livePlayer_old:MeMediaLivePlayer?
    fileprivate var filePlayer:MeMediaVodPlayer?
    fileprivate var filePlayer_old:MeMediaVodPlayer?
    fileprivate weak var baseView:UIView?
    // 初始化播放器时间
    fileprivate var checkTime:TimeInterval = 0.0
    fileprivate var isLive = true
    // 重连次数
    var reconnectCount:Int = 0
    fileprivate var nameIcon:UILabel?
    
    fileprivate var retryDelayDispatch: DispatchWorkItem?
    
    private static let reachablityManager = NetworkReachabilityManager()
    
    //MARK:<>内部block
}

extension LiveMePlayer : MeMediaPlayerDelegate,MeMediaPlayerStateDelegate,MeMediaPlayerSeiDelegate {
    func notifyMediaPlayerInfo(_ player: Any!, info: MeMediaPlayerInfoType) {
        self.delegate?.playerInfoStateChangeed?(state: info.rawValue)
    }
    
    func notifyMediaPlayerError(_ player: Any!, error: MeMediaPlayerErrorType) {
        let errorInfo = NSError.init(domain: "mePlayer error,\(error)", code: Int(error.rawValue), userInfo: nil)
        gLog("mePlayer code=\(error)")
        self.delegate?.liveStoppedError?(error: errorInfo)
        if self.reconnectCount < kAutoReconnectMaxCount {
            self.reconnectCount += 1
            if livePlayer == nil && filePlayer == nil {
                livePlayer_old = livePlayer
                livePlayer_old?.stop()
                livePlayer_old?.shutdown()
                livePlayer_old = nil
                
                filePlayer_old = filePlayer
                filePlayer_old?.stop()
                filePlayer_old?.shutdown()
                filePlayer_old = nil
            }
            if self.reconnectCount > 0 {
               self.retryDelayDispatch?.cancel()
                self.retryDelayDispatch = delay(2.5) { [weak self] in
                    self?.replayStream()
                    self?.delegate?.liveStartReloadSameStream?(errorMsg: "StoppedError")
                }
            }else{
                self.replayStream()
                self.delegate?.liveStartReloadSameStream?(errorMsg: "StoppedError")
            }
        }
    }
    
    func notifyMediaPlayerState(_ player: Any!, state: MeMediaPlayerState) {
        if state == MeMediaPlayerStateStarted || state == MeMediaPlayerStatePrepared {
            self.removeOldPlayer()
            self.reconnectCount = 0
            self.retryDelayDispatch?.cancel()
            self.retryDelayDispatch = nil
            let showTime = Date().timeIntervalSince1970 * 1000
            let renderTime:TimeInterval = showTime - self.checkTime
            self.delegate?.liveStartPlayed?(renderTime / 1000.0, livePlayer: self, play: baseView)
            //log.verbose("mePlayer playerDidStart")
        }else if state == MeMediaPlayerStateCompleted {
            if loopPlay == true {
                self.filePlayer?.play()
            }
        }
        
        self.delegate?.livePlayingStateChanged?(state: Self.getLiveStateFromState(state).rawValue)
    }
    
    func notifyMediaPlayerSei(_ player: Any!, type: Int32, sei: Data!) {
        if type == 243 { //zego的sei
            delegate?.mediaPlayerSei?(zegoData: sei)
        }
    }
}
#endif
